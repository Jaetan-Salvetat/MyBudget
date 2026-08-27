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

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

source tool/models/registry.env
[ -f tool/models/lock.env ] && source tool/models/lock.env

DRY_RUN=0
ARGS=()
for arg in "$@"; do
  if [ "$arg" = "--dry-run" ]; then DRY_RUN=1; else ARGS+=("$arg"); fi
done
set -- "${ARGS[@]+"${ARGS[@]}"}"

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

# Republier sous un tag existant laisserait les installations deja a jour sur
# les anciens modeles : l'app choisit ses assets par leur nom de fichier.
if [ "$DRY_RUN" -eq 0 ] && gh release view "$RELEASE" > /dev/null 2>&1; then
  echo "La release $RELEASE existe deja : choisir une version superieure." >&2
  exit 1
fi

TOKENIZER_SOURCE="${TOKENIZER_SOURCE:-$TOKENIZER_SOURCE_DEFAULT}"
echo "$([ "$DRY_RUN" -eq 1 ] && echo 'Essai a blanc' || echo 'Publication') de $RELEASE :"
RELEASE_FILES=()
NOTES_ROWS=()
LOCK_ROWS=()

for entry in "${MODELS[@]}"; do
  id="$(id_of "$entry")"
  pattern="$(pattern_of "$entry")"
  # shellcheck disable=SC2059
  asset="$(printf "$pattern" "v$VERSION")"
  destination="$ASSETS_DIR/$asset"
  glob="${pattern//%s/v*}"
  source="$(source_override "$id")"
  [ -n "$source" ] || source="$(source_of "$entry")"

  if [ "$DRY_RUN" -eq 1 ]; then
    if [ -n "$source" ] && [ -f "$source" ]; then
      echo "  $id -> $asset (depuis $source)"
    else
      existing="$(find "$ASSETS_DIR" -name "$glob" | head -n 1)"
      [ -n "$existing" ] || { echo "  $id : ni source ni asset" >&2; exit 66; }
      echo "  $id -> $asset (report de $(basename "$existing"))"
    fi
    continue
  fi

  if [ "$id" = "tokenizer" ] && [ -f "$TOKENIZER_SOURCE" ]; then
    echo "Regeneration du tokenizer depuis $TOKENIZER_SOURCE..."
    dart run tool/models/build_tokenizer_asset.dart "$TOKENIZER_SOURCE" "$destination.tmp"
    source="$destination.tmp"
  fi

  if [ -n "$source" ] && [ -f "$source" ]; then
    # Un seul exemplaire dans le manifeste : l'app refuse de choisir.
    find "$ASSETS_DIR" -name "$glob" -delete
    # Copie, jamais deplacement : la sortie d'entrainement reste ou elle est.
    # Seul le tokenizer intermediaire, genere ici, est deplace.
    if [ "$source" = "$destination.tmp" ]; then
      mv "$source" "$destination"
    else
      cp "$source" "$destination"
    fi
    echo "  $id : depuis $source"
  else
    existing="$(find "$ASSETS_DIR" -name "$glob" | head -n 1)"
    if [ -z "$existing" ]; then
      echo "Ni sortie d'entrainement ni asset pour $id : rien a publier." >&2
      exit 66
    fi
    # Reporte sous la nouvelle version : meme contenu, version commune.
    [ "$existing" != "$destination" ] && mv "$existing" "$destination"
    echo "  $id : report de $(basename "$existing") (inchange)"
  fi

  sha="$(checksum "$destination")"
  size="$(du -h "$destination" | cut -f1)"
  upper="$(echo "$id" | tr '[:lower:]' '[:upper:]')"
  RELEASE_FILES+=("$destination")
  NOTES_ROWS+=("| \`$id\` | \`$asset\` | $size | \`$sha\` |")
  LOCK_ROWS+=("${upper}_ASSET=$asset" "${upper}_SHA256=$sha")
done

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
