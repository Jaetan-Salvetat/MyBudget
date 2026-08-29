#!/usr/bin/env bash
# Publie les corpus d'entrainement dans le depot Hugging Face prive.
#
#   ./tool/ml_data/publish.sh                  # tous les corpus
#   ./tool/ml_data/publish.sh annotations      # un seul
#   ./tool/ml_data/publish.sh --dry-run        # ce qui partirait
#
# Prive parce que les licences des sources s'arretent a la recherche : FindIt
# ne se redistribue pas, et un depot public forcerait a l'exclure — c'est
# exactement ce que faisait l'ancienne publication en release GitHub, qui
# laissait chacun repasser par la CLI Kaggle.
#
# Ce script SYNCHRONISE : `--delete` efface cote distant ce qui a disparu en
# local, sans quoi un fichier retire du corpus y survivrait indefiniment. D'ou
# le refus, plus bas, de publier un corpus absent de la machine : apres un
# clone frais, ce serait vider le depot.
#
# Pas d'archive et pas d'empreinte a tenir a la main, contrairement aux
# release assets : le depot versionne fichier par fichier, donc republier
# trois annotations n'envoie que ces trois annotations. `hf upload` compare au
# distant et reprend tout seul un envoi interrompu.
set -euo pipefail

# Surchargeable pour que les tests exercent le script sur un depot factice.
ROOT="${ML_DATA_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

source tool/ml_data/registry.env

DRY_RUN=0
ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    -*) echo "usage: ./tool/ml_data/publish.sh [corpus...] [--dry-run]" >&2; exit 64 ;;
    *) ARGS+=("$1") ;;
  esac
  shift
done

name_of() { echo "${1%%|*}"; }
paths_of() { local rest="${1#*|}"; echo "${rest%%|*}"; }
description_of() { echo "${1##*|}"; }

selected() {
  local entry name
  for entry in "${SUBSETS[@]}"; do
    name="$(name_of "$entry")"
    if [ ${#ARGS[@]} -eq 0 ]; then
      echo "$entry"
    else
      local wanted
      for wanted in "${ARGS[@]}"; do
        [ "$wanted" = "$name" ] && echo "$entry"
      done
    fi
  done
}

known_names() {
  local entry
  for entry in "${SUBSETS[@]}"; do name_of "$entry"; done
}

for wanted in ${ARGS[@]+"${ARGS[@]}"}; do
  if ! known_names | grep -qx "$wanted"; then
    echo "Corpus inconnu : $wanted" >&2
    echo "Connus : $(known_names | paste -sd', ' -)" >&2
    exit 64
  fi
done

ENTRIES=()
while IFS= read -r entry; do ENTRIES+=("$entry"); done < <(selected)

# Publier un corpus qu'on n'a pas est la seule facon d'en perdre un : la
# synchronisation prendrait l'absence pour une suppression.
for entry in "${ENTRIES[@]}"; do
  for path in $(paths_of "$entry"); do
    [ -e "ml/$path" ] || {
      echo "Corpus absent de cette machine : ml/$path" >&2
      echo "Publier le supprimerait du depot. Le recuperer d'abord :" >&2
      echo "  ./tool/ml_data/fetch.sh $(name_of "$entry")" >&2
      exit 66
    }
  done
done

# Le refus distant arrive apres des minutes d'envoi. Le meme refus ici coute
# une seconde et dit quel dossier deborde.
for entry in "${ENTRIES[@]}"; do
  for path in $(paths_of "$entry"); do
    [ -d "ml/$path" ] || continue
    while IFS= read -r directory; do
      count="$(find "$directory" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')"
      if [ "$count" -ge "$FOLDER_LIMIT" ]; then
        echo "Trop d'entrees pour un dossier Hugging Face : $directory" >&2
        echo "  $count entrees, limite dure $FOLDER_LIMIT" >&2
        echo "Repartir ce dossier en sous-dossiers avant de publier." >&2
        exit 65
      fi
    done < <(find "ml/$path" -type d)
  done
done

if [ "$DRY_RUN" -eq 1 ]; then
  printf '%-12s %-10s %s\n' CORPUS TAILLE CHEMINS
  for entry in "${ENTRIES[@]}"; do
    size="$(du -shc $(paths_of "$entry" | sed 's|[^ ]*|ml/&|g') | tail -1 | cut -f1)"
    printf '%-12s %-10s %s\n' "$(name_of "$entry")" "$size" "$(paths_of "$entry")"
    printf '%-12s %-10s %s\n' "" "" "$(description_of "$entry")"
  done
  echo
  echo "Rien n'a ete envoye. Retirer --dry-run pour publier vers $REPOSITORY."
  exit 0
fi

command -v hf > /dev/null || { echo "hf est requis (pip install huggingface_hub)" >&2; exit 69; }

EXCLUDE_ARGS=()
for pattern in $EXCLUDED; do
  EXCLUDE_ARGS+=(--exclude "$pattern")
done

REVISION=""
for entry in "${ENTRIES[@]}"; do
  name="$(name_of "$entry")"
  for path in $(paths_of "$entry"); do
    echo "Envoi de ml/$path..."
    # Un corpus tenant en un seul fichier n'a ni suppressions a repercuter ni
    # rien a exclure — et `hf upload` avertit a chaque fois qu'il les ignore.
    FOLDER_ARGS=()
    if [ -d "ml/$path" ]; then
      # `--delete '*'` ne porte que sur le chemin publie : les corpus voisins
      # du depot ne sont jamais dans la portee d'une publication partielle.
      FOLDER_ARGS=(--delete "*" ${EXCLUDE_ARGS[@]+"${EXCLUDE_ARGS[@]}"})
    fi
    # `--private` n'a d'effet que si le depot a disparu et se recree : sans
    # lui, il reviendrait public, et FindIt avec.
    output="$(hf upload "$REPOSITORY" "ml/$path" "$path" \
      --repo-type dataset \
      --private \
      ${FOLDER_ARGS[@]+"${FOLDER_ARGS[@]}"} \
      --commit-message "$name : $path" \
      --json)"
    REVISION="$(echo "$output" | sed -n 's|.*/commit/\([0-9a-f]*\).*|\1|p' | tail -1)"
  done
done

[ -n "$REVISION" ] || { echo "hf n'a pas rendu de revision" >&2; exit 70; }

cat > tool/ml_data/lock.env <<EOF
# Les corpus d'entrainement vivent dans un depot Hugging Face prive : des Go
# de photos que LFS facturerait a chaque checkout de CI, et des sources dont
# la licence s'arrete a la recherche.
#
# La revision epinglee ici rend chaque commit reproductible — un vieux commit
# recupere les donnees sur lesquelles il a ete mesure.
#
# Genere par tool/ml_data/publish.sh, a ne pas editer a la main.
DATA_REPOSITORY=$REPOSITORY
DATA_REVISION=$REVISION
EOF

echo
echo "Publie. Reste a committer : tool/ml_data/lock.env -> $REVISION"
