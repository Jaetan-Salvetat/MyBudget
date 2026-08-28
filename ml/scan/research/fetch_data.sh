#!/usr/bin/env bash
# Reconstruit les corpus d'images (non versionnés) depuis leurs sources.
# Prérequis : CLI kaggle configurée, curl, unzip, uv.
set -euo pipefail
cd "$(dirname "$0")/../data"

echo "== Find it! (ICPR 2018) — seul dataset public de tickets FR"
echo "   Officiel (formulaire) : http://findit.univ-lr.fr/download-the-dataset/"
echo "   Miroir utilisé : kaggle srjpdl/findit-dataset"
if [ ! -d raw/findit/T1-test ]; then
  kaggle datasets download srjpdl/findit-dataset -p /tmp/findit --unzip
  mkdir -p raw/findit
  cp -R /tmp/findit/FindIt-Dataset-Test/FindIt-Dataset-Test/T1-test raw/findit/
  cp /tmp/findit/FindIt-Dataset-Test/FindIt-Dataset-Test/T1-Test-GT.xml raw/findit/
  cp -R /tmp/findit/FindIt-Dataset-Train/T1-train raw/findit/
  cp -R /tmp/findit/FindIt-Dataset-Train/T2-Train raw/findit/T2-train
fi

echo "== Sélections dérivées + corpus synthétique"
(cd ../research && uv run python -m corpus.rebuild && uv run python -m corpus.generate)

echo
echo "Ce script ne reconstruit QUE ce qui est déterministe : FindIt, les"
echo "sélections dérivées et le synthétique (seed 42)."
echo
echo "  photos_pixel, open_prices et mixed → ./tool/scan_data/fetch.sh"
echo
echo "Elles ne se reconstruisent pas : open_prices est un jeu vivant dont le"
echo "dump grossit chaque jour, donc un re-fetch rendrait un AUTRE corpus que"
echo "celui sur lequel les annotations ont été faites. Pour l'agrandir"
echo "délibérément : uv run python -m corpus.open_prices, puis republier."
echo
echo "Les dumps OCR se régénèrent via le harnais (voir ../README.md)."
