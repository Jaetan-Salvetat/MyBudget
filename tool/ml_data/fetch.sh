#!/usr/bin/env bash
# Recupere les corpus d'entrainement depuis le depot Hugging Face prive.
#
#   ./tool/ml_data/fetch.sh                    # tout (~6,5 Go)
#   ./tool/ml_data/fetch.sh annotations        # ~57 Mo, suffit a entrainer
#   ./tool/ml_data/fetch.sh --list             # ce que contient le depot
#
# Le depot est PRIVE : il faut y avoir acces et s'etre authentifie une fois
# par `hf auth login`.
#
# La revision epinglee dans lock.env est celle sur laquelle le commit courant
# a ete mesure. Se placer sur un vieux commit et relancer ce script rend les
# donnees de l'epoque, sans rien avoir a chercher.
#
# Ne sont pas ici : `synthetic` et les selections FindIt derivees, que
# ml/scan/research/fetch_data.sh regenere a l'identique.
set -euo pipefail

# Surchargeable pour que les tests exercent le script sur un depot factice.
ROOT="${ML_DATA_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

source tool/ml_data/registry.env
source tool/ml_data/lock.env

LIST=0
ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --list) LIST=1 ;;
    -*) echo "usage: ./tool/ml_data/fetch.sh [corpus...] [--list]" >&2; exit 64 ;;
    *) ARGS+=("$1") ;;
  esac
  shift
done

name_of() { echo "${1%%|*}"; }
paths_of() { local rest="${1#*|}"; echo "${rest%%|*}"; }
description_of() { echo "${1##*|}"; }

known_names() {
  local entry
  for entry in "${SUBSETS[@]}"; do name_of "$entry"; done
}

if [ "$LIST" -eq 1 ]; then
  for entry in "${SUBSETS[@]}"; do
    printf '%-12s %s\n' "$(name_of "$entry")" "$(description_of "$entry")"
  done
  exit 0
fi

for wanted in ${ARGS[@]+"${ARGS[@]}"}; do
  if ! known_names | grep -qx "$wanted"; then
    echo "Corpus inconnu : $wanted" >&2
    echo "Connus : $(known_names | paste -sd', ' -)" >&2
    exit 64
  fi
done

# Un fetch sans revision prendrait la tete du depot : les donnees ne seraient
# plus celles sur lesquelles ce commit a ete mesure, et rien ne le dirait.
[ -n "${DATA_REVISION:-}" ] || {
  echo "Aucune revision epinglee dans tool/ml_data/lock.env" >&2
  exit 65
}

command -v hf > /dev/null || { echo "hf est requis (pip install huggingface_hub)" >&2; exit 69; }

INCLUDE_ARGS=()
for entry in "${SUBSETS[@]}"; do
  name="$(name_of "$entry")"
  if [ ${#ARGS[@]} -gt 0 ]; then
    printf '%s\n' "${ARGS[@]}" | grep -qx "$name" || continue
  fi
  for path in $(paths_of "$entry"); do
    # Un corpus est un dossier, `open_prices` est un fichier : lui demander
    # `open_prices.parquet/*` ne ramenerait rien, en silence.
    case "$path" in
      *.parquet|*.jsonl|*.json) INCLUDE_ARGS+=(--include "$path") ;;
      *) INCLUDE_ARGS+=(--include "$path/*") ;;
    esac
  done
done

# Un seul --local-dir pour tous les corpus : le depot est un miroir de ml/,
# donc chaque fichier tombe deja au bon endroit.
hf download "$DATA_REPOSITORY" \
  --repo-type dataset \
  --revision "$DATA_REVISION" \
  --local-dir ml \
  "${INCLUDE_ARGS[@]}"

echo
echo "Corpus installes sous ml/, revision $DATA_REVISION"
