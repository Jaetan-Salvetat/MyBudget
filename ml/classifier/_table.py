import json
from corpus.receipts import openprices as op
from corpus.receipts.labels import ITEM_OVERRIDES
from serving.normalize import normalize_receipt_line
from paths import RECEIPTS_CORPUS

table = op.labels()
rows = [r for r in json.loads(RECEIPTS_CORPUS.read_text()) if r["split"] == "test"]
inside = [r for r in rows if normalize_receipt_line(r["name"]) in table]
by_override = [r for r in rows if r["name"] in ITEM_OVERRIDES]
print(f"T1-test retenu : {len(rows)} articles")
print(f"  dont l'écriture est dans la table Open Prices : {len(inside)} ({len(inside)/len(rows):.1%})")
print(f"  dont la vérité vient d'une surcharge manuelle : {len(by_override)}")

golden = json.loads((op.OPEN_PRICES_PATH.parent.parent / "golden" / "T1-test").exists() and "[]" or "[]")
# couverture sur TOUT le golden T1-test, pas seulement ce qui a une vérité
import pathlib
from paths import SCAN_GOLDEN_DIR
total = matched = 0
for path in sorted((SCAN_GOLDEN_DIR / "T1-test").glob("*.json")):
    receipt = json.loads(path.read_text(encoding="utf-8"))["receipt"]
    for item in receipt["items"]:
        total += 1
        matched += normalize_receipt_line(item["name"]) in table
print(f"\nSur TOUS les articles de T1-test ({total}) : {matched} trouvés dans la table ({matched/total:.1%})")
