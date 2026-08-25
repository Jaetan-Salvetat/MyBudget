"""Emplacements des données du scan — seule source de vérité des chemins.

Aucun module ne remonte l'arborescence à la main : déplacer un corpus se
fait ici, une fois.
"""

from pathlib import Path

RESEARCH_DIR = Path(__file__).resolve().parent
SCAN_DIR = RESEARCH_DIR.parent
PROJECT_ROOT = SCAN_DIR.parent.parent
PIPELINE_DIR = SCAN_DIR / "pipeline"
MODELS_DIR = RESEARCH_DIR / "models"
APP_MODELS_DIR = PROJECT_ROOT / "assets" / "models"

DATA_DIR = SCAN_DIR / "data"
GOLDEN_DIR = DATA_DIR / "golden"
RESULTS_DIR = DATA_DIR / "results"
FINDIT_DIR = DATA_DIR / "raw" / "findit"
CORPUS_DIR = DATA_DIR / "corpus"
SYNTHETIC_DIR = CORPUS_DIR / "synthetic"
