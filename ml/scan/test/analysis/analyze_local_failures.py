"""Taxonomie des échecs du mode local sur un run de suite device.

Objectif produit : ~99 % de validation directe en local. Ce script classe
chaque ticket `confirm` pour dire où investir :

- `golden_non_checksummable` : la somme du golden ne retombe pas sur son
  propre total — plafond structurel, aucun pipeline par checksum ne peut
  auto-valider ce ticket ;
- `ocr_montants_absents` : des montants d'articles du golden n'apparaissent
  nulle part dans le texte OCR (passe 1 + retry) — à attaquer côté image
  (variantes de prétraitement, l'oracle checksum permet le best-of-N) ;
- `total_non_lu` : les articles sont là mais aucune référence (total,
  sous-total, CB) n'a été lue — à attaquer côté récupération du total ;
- `structuration` : tout est dans l'OCR, la référence est lue, mais
  l'extraction ne mappe pas — à attaquer côté règles / classifieur V2.

Signale aussi les quasi-réussites : |somme − total| = exactement un article
manqué.
"""

from __future__ import annotations

import json
import re
import sys
from collections import Counter
from pathlib import Path

from score_device_flow import EXCLUDED_PATH, STAGE_NAMES, load_tickets

ROOT = Path(__file__).parent.parent
AMOUNT_PATTERN = re.compile(r"\d{1,4}[.,]\d{2}")
EPSILON = 0.005


def ocr_amounts(dump: dict) -> set[float]:
    texts = [dump.get("fullText", "")]
    if "ocrRetry" in dump:
        texts.append(dump["ocrRetry"].get("fullText", ""))
    amounts: set[float] = set()
    for text in texts:
        compact = re.sub(r"(\d)[.,]\s(\d{2})", r"\1.\2", text)
        for source in (text, compact):
            amounts.update(
                float(m.replace(",", ".")) for m in AMOUNT_PATTERN.findall(source)
            )
    return amounts


def golden_checksummable(golden: dict) -> bool:
    receipt = golden["receipt"]
    total = receipt.get("total")
    if total is None:
        return False
    items_sum = round(
        sum(i["amount"] - abs(i.get("discount") or 0) for i in receipt["items"]), 2
    )
    return abs(items_sum - round(float(total), 2)) < EPSILON


def golden_amounts(golden: dict) -> list[float]:
    return [
        round(float(i["amount"]), 2)
        for i in golden["receipt"]["items"]
        if abs(i["amount"]) >= EPSILON
    ]


def missing_ocr_amounts(ticket) -> list[float]:
    seen = ocr_amounts(json.loads(ticket.dump_path.read_text()))
    return [
        a
        for a in golden_amounts(ticket.golden)
        if not any(abs(abs(a) - s) < EPSILON for s in seen)
    ]


def hopeless_reason(ticket) -> str | None:
    """Raison d'exclusion du corpus de travail : aucun pipeline par checksum
    ne peut valider ce ticket, quelles que soient les règles."""
    if not golden_checksummable(ticket.golden):
        return "golden_non_checksummable"
    if missing_ocr_amounts(ticket):
        return "ocr_montants_absents"
    return None


def write_excluded(tickets) -> None:
    lines = [
        "# tickets hors corpus de travail (analyze_local_failures.py --write-excluded)"
    ]
    reasons = [(t.name, hopeless_reason(t)) for t in tickets]
    for name, reason in reasons:
        if reason is not None:
            lines.append(f"{name}  {reason}")
    EXCLUDED_PATH.write_text("\n".join(lines) + "\n")
    print(f"{sum(1 for _, r in reasons if r)} tickets exclus -> {EXCLUDED_PATH}")


def classify(ticket) -> tuple[str, bool]:
    golden = ticket.golden
    if not golden_checksummable(golden):
        return "golden_non_checksummable", False

    expected = golden_amounts(golden)
    missing_in_ocr = missing_ocr_amounts(ticket)

    best = ticket.flow.get("retry") or ticket.flow["pass1"]
    no_reference = (
        best["total"] is None and best["subtotal"] is None and best["payment"] is None
    )

    items_sum = round(sum(i["amount"] - i["discount"] for i in best["items"]), 2)
    golden_total = round(float(golden["receipt"]["total"]), 2)
    delta = round(golden_total - items_sum, 2)
    near_miss = any(abs(a - delta) < EPSILON for a in expected)

    if missing_in_ocr:
        return "ocr_montants_absents", near_miss
    if no_reference:
        return "total_non_lu", near_miss
    return "structuration", near_miss


def main() -> None:
    args = [a for a in sys.argv[1:] if a != "--write-excluded"]
    results_dir = ROOT / "results" / (args[0] if args else "device_flow")
    if "--write-excluded" in sys.argv:
        write_excluded(load_tickets(results_dir, excluded=set()))
        return
    tickets = load_tickets(results_dir)
    ceiling_fail = sum(1 for t in tickets if not golden_checksummable(t.golden))
    print(
        f"plafond corpus : {len(tickets) - ceiling_fail}/{len(tickets)} golden "
        f"checksummables ({(len(tickets) - ceiling_fail) / len(tickets):.1%})"
    )

    confirms = [t for t in tickets if STAGE_NAMES[t.flow["stage"]] == "confirm"]
    categories: Counter[str] = Counter()
    near_misses: Counter[str] = Counter()
    examples: dict[str, list[str]] = {}
    for ticket in confirms:
        category, near = classify(ticket)
        categories[category] += 1
        if near:
            near_misses[category] += 1
        examples.setdefault(category, []).append(ticket.name)

    auto = len(tickets) - len(confirms)
    print(
        f"local direct : {auto}/{len(tickets)} ({auto / len(tickets):.1%}), "
        f"confirm : {len(confirms)}"
    )
    print("\nrépartition des confirm :")
    for category, count in categories.most_common():
        near = near_misses.get(category, 0)
        print(
            f"  {category:<26}: {count:>4} ({count / len(confirms):.0%})"
            f"  dont quasi-réussites (1 article d'écart) : {near}"
        )
        for name in examples[category][:5]:
            print(f"      {name}")


if __name__ == "__main__":
    main()
