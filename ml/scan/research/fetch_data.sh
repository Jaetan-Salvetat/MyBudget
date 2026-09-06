#!/usr/bin/env bash
# Reconstruit ce qui est DÉTERMINISTE : les sélections dérivées de FindIt et le
# corpus synthétique (seed 42). Rien d'autre — tout ce qui ne se reconstruit
# pas vit dans le dépôt Hugging Face privé.
#
#   ./tool/ml_data/fetch.sh      # les corpus, dont FindIt dont ceci dérive
#   ./fetch_data.sh              # puis les sélections et le synthétique
#
# Prérequis : uv, et `ml/scan/data/raw/findit/` déjà récupéré.
set -euo pipefail
cd "$(dirname "$0")"

if [ ! -d ../data/raw/findit/T1-test ]; then
  echo "FindIt absent : ./tool/ml_data/fetch.sh findit" >&2
  exit 66
fi

echo "== Sélections dérivées + corpus synthétique"
uv run python -m corpus.rebuild
uv run python -m corpus.generate

echo
echo "Les sélections gardent les mêmes ids et les mêmes noms de fichiers, donc"
echo "caches et benchs restent comparables d'une reconstruction à l'autre."
