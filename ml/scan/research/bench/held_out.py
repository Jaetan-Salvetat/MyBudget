"""La métrique produit sur des photos réelles et récentes.

Tout se mesurait jusqu'ici sur T1-test : 415 scans à plat d'une enseigne de
2017, plus 20 photos. Le corpus d'entraînement, lui, avait grossi d'un facteur
cinq avec des photos de contributeurs prises entre 2024 et 2026 sur 337
enseignes — et rien n'en était réservé à l'évaluation.

Ce bench juge la tranche réservée (`annotate.dataset.is_held_out`). La vérité
est l'annotation elle-même : elle porte l'enseigne, la date, les rôles, les
montants et — depuis qu'on le lui demande — le **nom** de chaque article. Elle
ne passe par aucun golden, et le filtre au checksum garantit que sa somme
retombe sur la référence imprimée.

Ce que ce bench ne mesure pas : l'OCR. Les lignes viennent du corpus, donc de
la même passe Apple Vision que l'annotateur a vue. Il juge la structuration,
pas la lecture — et c'est exactement ce qui sépare 70 % de 90 %.

    uv run python -m bench.held_out [--corpus=open_prices] [--limit=N]
"""

from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path

from annotate.dataset import AnnotatedReceipt, load
from bench.exactness import SILENT, ExtractedName, receipt_exactness
from paths import ANNOTATIONS_DIR
from reference.decode_roles import extract_role_constrained
from reference.header_ml import date_of, role_probabilities, store_of
from reference.labels_ml import label_offsets, relabel
from reference.spans_ml import label_probabilities
from reference.structure import merge_price_fragments
from truth.references import receipt_from_annotation

DEFAULT_CORPUS = "open_prices"


def _truth(receipt: AnnotatedReceipt) -> dict | None:
    """La vérité au format de la métrique, relue du fichier d'annotation."""
    path = ANNOTATIONS_DIR / receipt.corpus / f"{Path(receipt.name).stem}.json"
    if not path.exists():
        return None
    return receipt_from_annotation(json.loads(path.read_text()))


def _read(receipt: AnnotatedReceipt) -> dict | None:
    merged = [merge_price_fragments(line) for line in receipt.lines]
    roles = role_probabilities(receipt.lines)
    extracted = extract_role_constrained(merged, role_probas=roles)
    if extracted is None or not extracted.checksum_ok:
        return None
    offsets = label_offsets(receipt.lines)
    spans = label_probabilities(receipt.lines)
    return {
        "store": store_of(receipt.lines, roles),
        "date": date_of(receipt.lines, roles),
        "total": extracted.verified_total,
        "items": relabel(extracted.items, receipt.lines, offsets, spans),
    }


def run(corpus: str, limit: int | None) -> list[dict]:
    receipts = [r for r in load(held_out=True) if r.corpus == corpus]
    scored = []
    for receipt in receipts[:limit] if limit else receipts:
        truth = _truth(receipt)
        if truth is None or not truth["items"]:
            continue
        reading = _read(receipt)
        if reading is None:
            scored.append({"name": receipt.name, "verified": False})
            continue
        exactness = receipt_exactness(
            reading["store"],
            reading["date"],
            reading["total"],
            [ExtractedName(i.name, i.amount, i.discount) for i in reading["items"]],
            {"receipt": truth},
        )
        scored.append(
            {
                "name": receipt.name,
                "verified": True,
                "wrong": exactness.wrong,
                "silent": exactness.silent,
            }
        )
    return scored


def report(scored: list[dict]) -> None:
    total = len(scored)
    if not total:
        print("aucun ticket à juger")
        return
    verified = [row for row in scored if row["verified"]]
    exact = [row for row in verified if not row["wrong"]]
    silent = [row for row in verified if any(k in SILENT for k in row["silent"])]
    print(f"\n=== {total} tickets d'évaluation, vérité annotée")
    print(f"  vérifiés         : {len(verified)} ({len(verified) / total:.1%})")
    print(f"  tickets parfaits : {len(exact)} ({len(exact) / total:.1%})")
    postes: Counter[str] = Counter()
    for row in verified:
        for poste in row["wrong"]:
            postes[poste] += 1
    print("\n  où part le reste (sur les vérifiés) :")
    for poste, count in postes.most_common():
        print(f"    {poste:<18}{count:>4} ({count / max(len(verified), 1):.0%})")
    print(
        f"\n  erreurs silencieuses : {len(silent)} "
        f"({len(silent) / max(len(verified), 1):.1%} des vérifiés)"
    )


def main(argv: list[str]) -> int:
    corpus = DEFAULT_CORPUS
    limit = None
    for argument in argv:
        if argument.startswith("--corpus="):
            corpus = argument.split("=", 1)[1]
        elif argument.startswith("--limit="):
            limit = int(argument.split("=", 1)[1])
    report(run(corpus, limit))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
