"""Comparaison de flows, à vérité, lectures et post-traitement identiques.

Seule change la façon dont les lignes sont étiquetées : mêmes lectures OCR,
mêmes modèles de libellé, même métrique. Ce qui se compare est donc bien le
flow.

C'est ce bench qui a tranché la cascade. Six étages — règles, argmax du
classifieur V2, décodage sous contrainte, tagger de rôles, sur chaque
lecture — rendaient **341 tickets justes sur 483**. Un seul étiqueteur suivi
d'un seul décodeur en rend 341 aussi, avec quatre tickets à montant faux en
moins. La cascade et le classifieur V2 ont été supprimés sur ce résultat ;
ce module reste pour que la prochaine idée de flow se juge pareil.

    uv run python -m bench.flows [--split=t1test|t1train] [--limit=N]
"""

from __future__ import annotations

import json
import sys
from collections import Counter
from concurrent.futures import ProcessPoolExecutor

from bench.exactness import SILENT, ExtractedName, receipt_exactness
from bench.vision_local import SPLIT_DIRS, _images
from ocr.pipeline import dump_for
from paths import GOLDEN_DIR
from reference.header_ml import date_of, predicted_roles, store_of
from reference.labels_ml import label_offsets, relabel
from reference.local_flow import Source, decide_local, read, sources
from reference.spans_ml import label_probabilities
from reference.structure import ExtractedReceipt
from reference.structure_roles import extract_roles


def flow_shipped(items: list[Source], dump: dict):
    """Le flow tel qu'il tourne : la première lecture qui prouve sa somme."""
    outcome = decide_local(dump)
    if not outcome.verified:
        return None
    receipt = ExtractedReceipt(
        store=None,
        date=None,
        total=outcome.total,
        subtotal=None,
        payment=None,
        items=outcome.items,
    )
    return outcome.source, receipt, outcome.lines


def flow_first_pass(items: list[Source], dump: dict):
    """Sans second OCR : ce que la passe 1 prouve seule. L'écart avec le flow
    dit ce que le retry et la fusion rapportent vraiment."""
    receipt = read(items[0])
    return ("passe1", receipt, items[0].lines) if receipt is not None else None


def flow_fused_first(items: list[Source], dump: dict):
    """Sans enchaînement : les deux passes fusionnées d'emblée, un seul
    décodage. Le retry n'est plus un rattrapage mais une lecture parmi deux,
    et c'est le décodeur qui arbitre les montants qui divergent.

    Si cette variante égale le flow, l'enchaînement passe 1 → retry → fusion
    ne se justifie plus que par la latence du second OCR."""
    fused = items[-1] if len(items) == 3 else items[0]
    receipt = read(fused)
    return (fused.name, receipt, fused.lines) if receipt is not None else None


def flow_argmax(items: list[Source], dump: dict):
    """Le tagger sans décodeur : son argmax structuré tel quel. L'écart avec
    le flow est ce que le décodage sous contrainte apporte — et ce qu'il
    risque."""
    for source in items:
        receipt = extract_roles(source.merged, predicted_roles(source.lines))
        if receipt is not None and receipt.checksum_ok:
            return f"argmax/{source.name}", receipt, source.lines
    return None


VARIANTS = {
    "flow": flow_shipped,
    "passe1 seule": flow_first_pass,
    "fusion d'emblée": flow_fused_first,
    "argmax sans DP": flow_argmax,
}


def _read(lines, receipt: ExtractedReceipt) -> dict:
    """Enseigne, date et libellés : identiques pour toutes les variantes, pour
    que la comparaison ne porte que sur l'étiquetage des montants."""
    from reference.header_ml import role_probabilities

    roles = role_probabilities(lines)
    offsets = label_offsets(lines)
    spans = label_probabilities(lines)
    return {
        "store": store_of(lines, roles),
        "date": date_of(lines, roles),
        "total": receipt.verified_total,
        "items": [
            {"name": i.name, "amount": i.amount, "discount": i.discount}
            for i in relabel(receipt.items, lines, offsets, spans)
        ],
    }


def _run_one(image) -> dict:
    dump = dump_for(image)
    items = list(sources(dump))
    out = {"doc": image.stem}
    for name, variant in VARIANTS.items():
        found = variant(items, dump)
        out[name] = (
            None if found is None else {"stage": found[0], **_read(found[2], found[1])}
        )
    return out


def _score(reading: dict | None, reference: dict) -> dict:
    if reading is None:
        return {"verified": False}
    exactness = receipt_exactness(
        reading["store"],
        reading["date"],
        reading["total"],
        [
            ExtractedName(i["name"], i["amount"], i["discount"])
            for i in reading["items"]
        ],
        {"receipt": reference},
    )
    return {
        "verified": True,
        "stage": reading["stage"],
        "wrong": exactness.wrong,
        "silent": exactness.silent,
    }


def run(split: str, limit: int | None) -> list[dict]:
    from truth.golden import best_reference
    from truth.references import alternatives

    golden_dir = GOLDEN_DIR / SPLIT_DIRS[split]
    scored = []
    with ProcessPoolExecutor() as pool:
        for result in pool.map(_run_one, _images(split, limit)):
            golden = json.loads((golden_dir / f"{result['doc']}.json").read_text())
            reference, _ = best_reference(
                golden["receipt"], alternatives(SPLIT_DIRS[split], result["doc"])
            )
            if reference is None:
                continue
            scored.append(
                {
                    "doc": result["doc"],
                    **{name: _score(result[name], reference) for name in VARIANTS},
                }
            )
    return scored


def report(scored: list[dict]) -> None:
    total = len(scored)
    print(f"\n=== {total} tickets jugés (vérité golden arbitrée)\n")
    header = (
        f"{'variante':<16}{'vérifiés':>12}{'parfaits':>12}"
        f"{'silencieux':>12}{'montant faux':>14}"
    )
    print(header)
    print("-" * len(header))
    for name in VARIANTS:
        rows = [row[name] for row in scored]
        verified = [r for r in rows if r["verified"]]
        exact = [r for r in verified if not r["wrong"]]
        silent = [r for r in verified if any(k in SILENT for k in r["silent"])]
        wrong_amount = [r for r in verified if "montant" in r["wrong"]]
        print(
            f"{name:<16}{len(verified):>7} {len(verified) / total:>4.0%}"
            f"{len(exact):>7} {len(exact) / total:>4.0%}"
            f"{len(silent):>7} {len(silent) / max(len(verified), 1):>4.0%}"
            f"{len(wrong_amount):>9}"
        )
    print("\n=== lectures retenues")
    for name in VARIANTS:
        stages = Counter(
            row[name].get("stage") for row in scored if row[name]["verified"]
        )
        print(f"  {name:<16}{dict(stages.most_common(6))}")


def main(argv: list[str]) -> int:
    split = "t1test"
    limit = None
    for argument in argv:
        if argument.startswith("--split="):
            split = argument.split("=", 1)[1]
        elif argument.startswith("--limit="):
            limit = int(argument.split("=", 1)[1])
    report(run(split, limit))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
