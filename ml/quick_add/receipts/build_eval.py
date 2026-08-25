"""Joint golden FindIt × étiquettes manuelles → `eval_receipts.json`.

Chaque ligne : ticket, split (T1-train / T1-test), enseigne, libellé imprimé,
catégorie attendue. Le split est celui du dataset FindIt : tout ce qui
apprend des libellés de tickets doit le faire sur T1-train seulement.
"""

import json
import sys
from collections import Counter
from pathlib import Path

from receipts.labels import EXCLUDED_ITEMS, EXCLUDED_STORES, ITEM_OVERRIDES, STORE_LABELS

ROOT = Path(__file__).resolve().parents[3]
GOLDEN_DIR = ROOT / "ml" / "scan" / "test" / "golden"
OUTPUT_PATH = Path(__file__).resolve().parents[1] / "eval_receipts.json"
SPLITS = {"T1-train": "train", "T1-test": "test"}


def label_for(store: str, name: str) -> str | None:
    if store in EXCLUDED_STORES or name in EXCLUDED_ITEMS:
        return None
    override = ITEM_OVERRIDES.get(name)
    if override is not None:
        return override
    return STORE_LABELS.get(store)


def build() -> list[dict]:
    rows: list[dict] = []
    unknown_stores: Counter[str] = Counter()
    for folder, split in SPLITS.items():
        for path in sorted((GOLDEN_DIR / folder).glob("*.json")):
            receipt = json.loads(path.read_text(encoding="utf-8"))["receipt"]
            store = receipt.get("store") or ""
            if store not in STORE_LABELS and store not in EXCLUDED_STORES:
                unknown_stores[store] += 1
            for item in receipt["items"]:
                category = label_for(store, item["name"])
                if category is None:
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
    if unknown_stores:
        raise ValueError(f"Enseignes sans étiquette : {dict(unknown_stores)}")
    return rows


def main() -> None:
    rows = build()
    OUTPUT_PATH.write_text(json.dumps(rows, ensure_ascii=False, indent=1), encoding="utf-8")
    per_split = Counter(row["split"] for row in rows)
    per_class = Counter(row["category"] for row in rows)
    print(f"{len(rows)} articles → {OUTPUT_PATH.name} ; {dict(per_split)}")
    for slug, count in per_class.most_common():
        print(f"  {slug:45} {count}")


if __name__ == "__main__":
    sys.exit(main())
