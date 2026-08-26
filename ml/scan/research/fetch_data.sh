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

echo "== Wikimedia Commons (ticket FR)"
mkdir -p corpus/mixed
curl -sL -o corpus/mixed/wm_creperie_tante_lucie.jpg \
  "https://commons.wikimedia.org/wiki/Special:FilePath/Tickets_de_caisse_de_la_crêperie_Tante_Lucie.jpg"

echo "== Open Prices (tickets FR photographiés, ODbL / images CC BY-SA)"
(cd ../research && uv run python -m corpus.open_prices)

echo "== Sélections dérivées + corpus synthétique"
(cd ../research && uv run python -m corpus.rebuild && uv run python -m corpus.generate)

echo "Terminé. Les dumps OCR se régénèrent via le harnais (voir ../README.md)."
