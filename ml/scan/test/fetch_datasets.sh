#!/usr/bin/env bash
# Reconstruit les corpus d'images (non versionnés) depuis leurs sources.
# Prérequis : CLI kaggle configurée, curl, unzip, uv.
set -euo pipefail
cd "$(dirname "$0")"

echo "== Find it! (ICPR 2018) — seul dataset public de tickets FR"
echo "   Officiel (formulaire) : http://findit.univ-lr.fr/download-the-dataset/"
echo "   Miroir utilisé : kaggle srjpdl/findit-dataset"
if [ ! -d dataset_findit/T1-test ]; then
  kaggle datasets download srjpdl/findit-dataset -p /tmp/findit --unzip
  mkdir -p dataset_findit
  cp -R /tmp/findit/FindIt-Dataset-Test/FindIt-Dataset-Test/T1-test dataset_findit/
  cp /tmp/findit/FindIt-Dataset-Test/FindIt-Dataset-Test/T1-Test-GT.xml dataset_findit/
  cp -R /tmp/findit/FindIt-Dataset-Train/T1-train dataset_findit/
  cp -R /tmp/findit/FindIt-Dataset-Train/T2-Train dataset_findit/T2-train
fi

echo "== ExpressExpense SRD (200 photos US, licence MIT)"
if [ ! -d /tmp/srd ]; then
  curl -sL -o /tmp/srd.zip "https://expressexpense.com/large-receipt-image-dataset-SRD.zip"
  echo "c8eb0f2d286da5ab742e7a5b59f15147  /tmp/srd.zip" | md5sum -c - 2>/dev/null \
    || [ "$(md5 -q /tmp/srd.zip)" = "c8eb0f2d286da5ab742e7a5b59f15147" ]
  mkdir -p /tmp/srd && unzip -q -o /tmp/srd.zip -d /tmp/srd
fi

echo "== Wikimedia Commons (2 tickets FR)"
mkdir -p corpus_web
curl -sL -o corpus_web/wm_rappel_produit.jpg \
  "https://commons.wikimedia.org/wiki/Special:FilePath/2023-02-19_23-37-01_-_Ticket_de_caisse_rappel_de_produit.jpg"
curl -sL -o corpus_web/wm_creperie_tante_lucie.jpg \
  "https://commons.wikimedia.org/wiki/Special:FilePath/Tickets_de_caisse_de_la_crêperie_Tante_Lucie.jpg"

echo "== Sélections dérivées + corpus synthétique"
uv run python analysis/rebuild_corpora.py
uv run python analysis/generate_corpus.py

echo "Terminé. Les dumps OCR se régénèrent via le harnais (voir ../README.md)."
