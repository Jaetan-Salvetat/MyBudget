"""Emplacements du projet — seule source de vérité des chemins.

Le modèle sert deux consommateurs (quick-add et scan) : ses artefacts et ses
corpus ne sont la propriété d'aucun des deux.
"""

import os
from pathlib import Path

CLASSIFIER_DIR = Path(__file__).resolve().parent
ML_DIR = CLASSIFIER_DIR.parent
PROJECT_ROOT = ML_DIR.parent

TAXONOMY_PATH = PROJECT_ROOT / "assets" / "categories.json"

DATASET_DIR = CLASSIFIER_DIR / "dataset"
CACHE_DIR = DATASET_DIR / "cache"
ENTITIES_PATH = DATASET_DIR / "entities.jsonl"

OUTPUT_DIR = Path(os.environ.get("CLASSIFIER_OUTPUT", CLASSIFIER_DIR / "output"))
MODEL_DIR = Path(os.environ.get("CLASSIFIER_MODEL", CLASSIFIER_DIR / "output" / "best"))

# L'ONNX vit avec les poids dont il sort, et n'a pas de reglage propre : un
# export et des poids qui se choisissent separement finissent par diverger, et
# c'est ce qui a fait publier cinq versions du meme modele perime.
ONNX_PATH = MODEL_DIR / "model.onnx"

EVAL_DATA_DIR = CLASSIFIER_DIR / "evaluation" / "data"
WORLD_CORPUS = EVAL_DATA_DIR / "world.json"
QUICK_ADD_CORPUS = EVAL_DATA_DIR / "quick_add.json"
RECEIPTS_CORPUS = EVAL_DATA_DIR / "receipts.json"

SCAN_GOLDEN_DIR = ML_DIR / "scan" / "data" / "golden"

# Open Prices (ODbL) : le seul corpus public où un libellé de caisse français
# arrive avec la vérité de son produit. Moissonné par l'étude scan, lu ici.
OPEN_PRICES_PATH = ML_DIR / "scan" / "data" / "raw" / "open_prices.parquet"
