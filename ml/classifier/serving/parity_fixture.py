"""Écrit les références de parité Python → Dart de `serving/normalize.py`.

Deux entrées, deux fixtures : les libellés des golden FindIt pour le ticket,
les noms d'entités et une poignée de saisies mal écrites pour le quick-add. Le
port Dart doit produire exactement les mêmes chaînes, sinon le modèle recevrait
à l'inférence un texte qu'il n'a pas vu à l'entraînement.
"""

import json
import random
import sys

from knowledge.entities import read_entities
from paths import ENTITIES_PATH, PROJECT_ROOT, SCAN_GOLDEN_DIR
from serving.normalize import normalize_query, normalize_receipt_line

GOLDEN_DIR = SCAN_GOLDEN_DIR
FIXTURE_DIR = PROJECT_ROOT / "ml/scan/pipeline/test/fixtures"
RECEIPT_FIXTURE_PATH = FIXTURE_DIR / "receipt_line_normalization.json"
QUERY_FIXTURE_PATH = FIXTURE_DIR / "query_normalization.json"
QUERY_SAMPLE = 3000
SEED = 42

# Ce qu'un utilisateur tape et qu'aucun nom d'entité ne contient : la
# ponctuation collée, l'apostrophe typographique du clavier iOS, l'espace
# insécable des copier-coller, la casse hurlante.
HAND_WRITTEN_QUERIES = [
    "Father &son", "father& son", "FATHER&SON", "Père & Fils",
    "aujourd’hui", "Aujourd'hui", "MARCHE  PEAGE", "Marché péage crèche",
    "week—end", "C&A", "H&M", "Franprix\u00a0Paris", "Läderach",
    "restaurant!!!", "?", "  ", "N°42", "L'Occitane", "Häagen-Dazs",
    "Straße", "café/thé", "coiffeur,manucure", "TÉLÉPHONE + INTERNET",
]


def receipt_pairs() -> list[list[str]]:
    lines: set[str] = set()
    for path in sorted(GOLDEN_DIR.glob("T1-*/*.json")):
        receipt = json.loads(path.read_text(encoding="utf-8"))["receipt"]
        if receipt.get("store"):
            lines.add(receipt["store"])
        lines.update(item["name"] for item in receipt["items"])
    return [[line, normalize_receipt_line(line)] for line in sorted(lines)]


def query_pairs() -> list[list[str]]:
    names = sorted({entity.name for entity in read_entities(ENTITIES_PATH)})
    sample = random.Random(SEED).sample(names, min(QUERY_SAMPLE, len(names)))
    return [
        [query, normalize_query(query)]
        for query in sorted(set(sample + HAND_WRITTEN_QUERIES))
    ]


def write(pairs: list[list[str]], path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(pairs, ensure_ascii=False, indent=0), encoding="utf-8")
    print(f"{len(pairs)} lignes → {path.relative_to(PROJECT_ROOT)}")


def main() -> None:
    write(receipt_pairs(), RECEIPT_FIXTURE_PATH)
    write(query_pairs(), QUERY_FIXTURE_PATH)


if __name__ == "__main__":
    sys.exit(main())
