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
EXPORT_DIR = Path(os.environ.get("CLASSIFIER_EXPORT_DIR", CLASSIFIER_DIR / "output"))

EVAL_DATA_DIR = CLASSIFIER_DIR / "evaluation" / "data"
WORLD_CORPUS = EVAL_DATA_DIR / "world.json"
QUICK_ADD_CORPUS = EVAL_DATA_DIR / "quick_add.json"
RECEIPTS_CORPUS = EVAL_DATA_DIR / "receipts.json"

SCAN_GOLDEN_DIR = ML_DIR / "scan" / "data" / "golden"
