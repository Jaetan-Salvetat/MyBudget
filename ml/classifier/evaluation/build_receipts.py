"""Joint golden FindIt × vérité d'article → `evaluation/data/receipts.json`.

Chaque ligne : ticket, split (T1-train / T1-test), enseigne, libellé imprimé,
catégorie attendue. Le split est celui du dataset FindIt : tout ce qui apprend
des libellés de tickets doit le faire sur T1-train seulement.

La catégorie attendue vient de l'**article**, jamais de l'enseigne — voir
`corpus/receipts/truth.py`. Un article que ni les surcharges ni le répertoire
de libellés réels ne savent classer sort du corpus : mesurer contre une vérité
recopiée du magasin ne mesurait pas la catégorisation d'un article, et c'est
elle que le flow doit rendre. L'enseigne reste dans la ligne, pour lire les
résultats, pas pour les fabriquer.
"""

import json
import sys
from collections import Counter

from corpus.receipts.labels import EXCLUDED_STORES
from corpus.receipts.openprices import labels as real_labels
from corpus.receipts.truth import item_label
from paths import RECEIPTS_CORPUS, SCAN_GOLDEN_DIR

GOLDEN_DIR = SCAN_GOLDEN_DIR
OUTPUT_PATH = RECEIPTS_CORPUS
SPLITS = {"T1-train": "train", "T1-test": "test"}


def build(labels: dict[str, str]) -> tuple[list[dict], Counter]:
    rows: list[dict] = []
    skipped: Counter[str] = Counter()
    for folder, split in SPLITS.items():
        for path in sorted((GOLDEN_DIR / folder).glob("*.json")):
            receipt = json.loads(path.read_text(encoding="utf-8"))["receipt"]
            store = receipt.get("store") or ""
            if store in EXCLUDED_STORES:
                continue
            for item in receipt["items"]:
                category = item_label(item["name"], labels)
                if category is None:
                    skipped[split] += 1
                    continue
                rows.append(
                    {
                        "ticket": f"{folder}/{path.stem}",
                        "split": split,
                        "store": store,
                        "name": item["name"],
                        "category": category,
                    }
                )
    return rows, skipped


def main() -> None:
    rows, skipped = build(real_labels())
    OUTPUT_PATH.write_text(json.dumps(rows, ensure_ascii=False, indent=1), encoding="utf-8")
    per_split = Counter(row["split"] for row in rows)
    per_class = Counter(row["category"] for row in rows)
    print(f"{len(rows)} articles → {OUTPUT_PATH.name} ; {dict(per_split)}")
    print(f"sans vérité d'article, écartés : {dict(skipped)}")
    for slug, count in per_class.most_common():
        print(f"  {slug:45} {count}")


if __name__ == "__main__":
    sys.exit(main())
