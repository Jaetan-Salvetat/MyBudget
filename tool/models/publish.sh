#!/usr/bin/env bash
# Publie TOUS les modeles de l'app sous une seule version.
#
#   ./tool/models/publish.sh            # version suivante d'apres lock.env
#   ./tool/models/publish.sh v9         # version imposee
#   ./tool/models/publish.sh --dry-run  # ce qui serait publie, sans rien publier
#
# Un seul script, une seule release, une seule version : le quick-add
# (modele ONNX + tokenizer) et les quatre modeles du scan (classifieur de
# lignes, tagger de roles, modele de lien, tagger de spans) avancent ensemble. Ils sont
# utilises ensemble, et une installation qui melangerait les versions
# deciderait autrement que la reference mesuree.
#
# Un modele dont la sortie d'entrainement est absente n'est pas republie a
# l'identique : il est REPORTE sous la nouvelle version. Reentrainer un seul
# modele suffit donc, les autres suivent sans etre regeneres.
#
# Sources par defaut : tool/models/registry.env. Surchargeables une a une par
# <ID>_SOURCE en majuscules, par exemple :
#   QUICK_ADD_SOURCE=/tmp/model.onnx ./tool/models/publish.sh
#
# Rien n'est a editer a la main ensuite : l'app lit le nom de chaque modele
# dans le manifeste des assets, et tool/models/lock.env est reecrit ici.
set -euo pipefail

# Surchargeable pour que les tests exercent le script sur un depot factice.
ROOT="${MODELS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

source tool/models/registry.env
[ -f tool/models/lock.env ] && source tool/models/lock.env

DRY_RUN=0
CARRY_OVER=()
ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --carry-over) CARRY_OVER+=("$2"); shift ;;
    *) ARGS+=("$1") ;;
  esac
  shift
done
set -- "${ARGS[@]+"${ARGS[@]}"}"

# Reporter un modele est legitime quand on ne l'a pas reentraine — mais ca doit
# se demander. v10 est parti avec le quick-add perime parce que sa source
# n'existait pas encore et que le report s'est fait tout seul.
is_carried_over() {
  local id="$1" name
  for name in ${CARRY_OVER[@]+"${CARRY_OVER[@]}"}; do
    [ "$name" = "$id" ] && return 0
  done
  return 1
}

if [ $# -gt 1 ]; then
  echo "usage: ./tool/models/publish.sh [version] [--dry-run]" >&2
  exit 64
fi

if [ "$DRY_RUN" -eq 0 ]; then
  command -v gh > /dev/null || { echo "gh est requis" >&2; exit 69; }
fi

checksum() {
  if command -v sha256sum > /dev/null; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

file_date() {
  stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$1" 2> /dev/null || stat -c '%y' "$1" | cut -c1-16
}

# Le seul endroit ou se voit un export oublie : le sha de ce qu'on s'apprete a
# publier, confronte a celui de la version precedente. Le quick-add est reste
# cinq versions sur les memes octets parce que rien ne le disait.
verdict() {
  local sha="$1" previous="$2"
  if [ -z "$previous" ]; then echo "premiere version"
  elif [ "$sha" = "$previous" ]; then echo "INCHANGE"
  else echo "nouveau"
  fi
}

id_of() { echo "${1%%|*}"; }
pattern_of() { local rest="${1#*|}"; echo "${rest%%|*}"; }
source_of() { echo "${1##*|}"; }

# Le nom de la variable d'environnement qui surcharge la source d'un modele.
source_override() {
  local id="$1"
  local name
  name="$(echo "$id" | tr '[:lower:]' '[:upper:]')_SOURCE"
  echo "${!name:-}"
}

# La version courante, lue dans le nom d'un asset epingle.
version_of() {
  local asset="$1" pattern="$2"
  local prefix="${pattern%%\%s*}" suffix="${pattern##*\%s}"
  local stripped="${asset#"$prefix"}"
  echo "${stripped%"$suffix"}"
}

CURRENT=0
for entry in "${MODELS[@]}"; do
  id="$(id_of "$entry")"
  pinned_name="$(echo "$id" | tr '[:lower:]' '[:upper:]')_ASSET"
  pinned="${!pinned_name:-}"
  [ -n "$pinned" ] || continue
  number="$(version_of "$pinned" "$(pattern_of "$entry")")"
  number="${number#v}"
  [ "$number" -gt "$CURRENT" ] && CURRENT="$number"
done

if [ $# -eq 1 ]; then
  VERSION="${1#v}"
else
  VERSION="$((CURRENT + 1))"
fi
RELEASE="models-v$VERSION"
RELEASE_PREVIOUS="models-v$CURRENT"

# Republier sous un tag existant laisserait les installations deja a jour sur
# les anciens modeles : l'app choisit ses assets par leur nom de fichier.
if [ "$DRY_RUN" -eq 0 ] && gh release view "$RELEASE" > /dev/null 2>&1; then
  echo "La release $RELEASE existe deja : choisir une version superieure." >&2
  exit 1
fi

TOKENIZER_SOURCE="${TOKENIZER_SOURCE:-$TOKENIZER_SOURCE_DEFAULT}"
echo "$([ "$DRY_RUN" -eq 1 ] && echo 'Essai a blanc' || echo 'Publication') de $RELEASE :"
echo
RELEASE_FILES=()
NOTES_ROWS=()
LOCK_ROWS=()
UNCHANGED=()

for entry in "${MODELS[@]}"; do
  id="$(id_of "$entry")"
  pattern="$(pattern_of "$entry")"
  # shellcheck disable=SC2059
  asset="$(printf "$pattern" "v$VERSION")"
  destination="$ASSETS_DIR/$asset"
  glob="${pattern//%s/v*}"
  source="$(source_override "$id")"
  [ -n "$source" ] || source="$(source_of "$entry")"
  upper="$(echo "$id" | tr '[:lower:]' '[:upper:]')"
  previous_name="${upper}_SHA256"
  previous="${!previous_name:-}"

  # Le tokenizer n'a pas de source d'entrainement : il se regenere depuis
  # celui des poids livres, et n'existe donc qu'une fois le dart passe.
  if [ "$id" = "tokenizer" ] && [ -f "$TOKENIZER_SOURCE" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      printf '  %-16s %-24s %-16s regenere depuis %s\n' "$id" "$asset" "" "$TOKENIZER_SOURCE"
      continue
    fi
    echo "  Regeneration du tokenizer depuis $TOKENIZER_SOURCE..."
    dart run tool/models/build_tokenizer_asset.dart "$TOKENIZER_SOURCE" "$destination.tmp"
    source="$destination.tmp"
  fi

  # Une source declaree dont le fichier manque n'est pas un modele « pas
  # reentraine » : c'est un export qu'on a oublie de refaire, et le report
  # silencieux publierait l'ancien sous un nom neuf.
  if [ -n "$source" ] && [ ! -f "$source" ] && ! is_carried_over "$id"; then
    echo "Source declaree absente pour $id : $source" >&2
    echo "Refaire l'export, ou assumer le report avec --carry-over $id." >&2
    exit 65
  fi

  if [ -n "$source" ] && [ -f "$source" ]; then
    origin="$source ($(file_date "$source"))"
    sha="$(checksum "$source")"
    if [ "$DRY_RUN" -eq 0 ]; then
      # Un seul exemplaire dans le manifeste : l'app refuse de choisir.
      find "$ASSETS_DIR" -name "$glob" -delete
      # Copie, jamais deplacement : la sortie d'entrainement reste ou elle est.
      # Seul le tokenizer intermediaire, genere ici, est deplace.
      if [ "$source" = "$destination.tmp" ]; then
        mv "$source" "$destination"
      else
        cp "$source" "$destination"
      fi
    fi
  else
    existing="$(find "$ASSETS_DIR" -name "$glob" | head -n 1)"
    if [ -z "$existing" ]; then
      echo "Ni sortie d'entrainement ni asset pour $id : rien a publier." >&2
      exit 66
    fi
    origin="report de $(basename "$existing")"
    sha="$(checksum "$existing")"
    # Reporte sous la nouvelle version : meme contenu, version commune.
    if [ "$DRY_RUN" -eq 0 ] && [ "$existing" != "$destination" ]; then
      mv "$existing" "$destination"
    fi
  fi

  state="$(verdict "$sha" "$previous")"
  [ "$state" = "INCHANGE" ] && UNCHANGED+=("$id")
  printf '  %-16s %-24s %-16s %s\n' "$id" "$asset" "$state" "$origin"

  [ "$DRY_RUN" -eq 1 ] && continue

  size="$(du -h "$destination" | cut -f1)"
  RELEASE_FILES+=("$destination")
  NOTES_ROWS+=("| \`$id\` | \`$asset\` | $size | \`$sha\` |")
  LOCK_ROWS+=("${upper}_ASSET=$asset" "${upper}_SHA256=$sha")
done

# Un modele reentraine dont les octets ne bougent pas est un export qui n'a
# pas ete refait, ou une source qui pointe ailleurs que le run qu'on croit
# publier. Rien ne l'interdit — les modeles non reentraines sont reportes tels
# quels — mais ca ne doit pas passer sans etre lu.
if [ "${#UNCHANGED[@]}" -gt 0 ]; then
  echo
  echo "INCHANGES depuis $RELEASE_PREVIOUS : ${UNCHANGED[*]}"
  echo "Attendu pour un modele non reentraine. Sinon, la source de registry.env"
  echo "pointe un export perime : verifier la date affichee ci-dessus."
fi

# La source HuggingFace est archivee avec les modeles : elle ne vit plus dans
# le depot, et c'est elle qui permet de regenerer le tokenizer binaire.
[ -f "$TOKENIZER_SOURCE" ] && RELEASE_FILES+=("$TOKENIZER_SOURCE")

if [ "$DRY_RUN" -eq 1 ]; then
  echo
  echo "Essai a blanc : rien n'a ete publie ni renomme."
  exit 0
fi

echo "Publication de $RELEASE..."
gh release create "$RELEASE" "${RELEASE_FILES[@]}" \
  --title "Modeles $VERSION" \
  --notes "Tous les modeles embarques de l'app, sous une version commune.

- **quick_add** : le classifieur ONNX de l'ajout rapide ;
- **tokenizer** : son tokenizer, au format binaire lu par l'app ;
- **line_roles** : neuf roles sur toutes les lignes du ticket ; il designe
  l'enseigne et la ligne de date, et c'est lui que le decodeur sous
  contrainte lit pour prouver la somme ;
- **label_link** : a quelle distance au-dessus se trouve le libelle d'un
  article, quand son prix est imprime seul ;
- **label_span** : quels mots de cette ligne composent le libelle ;
- **store_gazetteer** : le repertoire des enseignes apprises du corpus.

| modele | asset | taille | sha256 |
|---|---|---|---|
$(printf '%s\n' "${NOTES_ROWS[@]}")

Recuperes au build par \`./tool/models/fetch.sh\`, epingles dans
\`tool/models/lock.env\`."

cat > tool/models/lock.env <<EOF
# Les modeles publies hors du depot : LFS facture le stockage et la bande
# passante a chaque run de CI, les release assets non. Versionne dans git, ce
# fichier rend chaque commit reproductible — un vieux commit recupere les
# modeles qu'il attend.
#
# Tous portent la MEME version et vivent dans la meme release : ils sont
# utilises ensemble.
#
# Genere par tool/models/publish.sh, a ne pas editer a la main.
REPOSITORY=$REPOSITORY
RELEASE=$RELEASE
$(printf '%s\n' "${LOCK_ROWS[@]}")
EOF

# Les assets sont deja en place — publish les y a deposes — mais c'est fetch
# qui fait foi : il confronte chaque fichier d'assets/models/ a l'empreinte
# tout juste ecrite dans le lock. Un asset oublie, une copie tronquee ou un
# lock desaccorde se voient ici, pas chez l'utilisateur.
echo
echo "Verification des modeles de l'app..."
./tool/models/fetch.sh

echo
echo "Publie. Reste a committer : tool/models/lock.env -> $RELEASE"
echo "Puis : flutter test"
