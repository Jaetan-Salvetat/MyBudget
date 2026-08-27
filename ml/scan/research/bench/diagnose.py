"""Diagnostic fin du mode local, rejoué depuis les dumps d'un run device.

Pour chaque ticket : chaque lecture de l'image exécutée seule (passe 1,
retry, fusion), la vérité par ligne alignée sur le golden
(`line_truth.py`), la concordance entre étages, les noms d'articles, les
dégâts OCR vus depuis la transcription, un test adversarial du décodeur
(référence fausse → « vérifie » quand même ?) et une cause racine. Sortie :
un enregistrement JSON par ticket (`results/diagnostics/<run>.jsonl`) et un
rapport agrégé — matrices de confusion par lecture, concordance, calibration
du niveau de confiance.
"""

from __future__ import annotations

import json
import sys
from collections import Counter, defaultdict
from dataclasses import asdict, dataclass, field
from difflib import SequenceMatcher
from pathlib import Path

from bench.device_flow import load_tickets
from bench.failures import ocr_amounts
from bench.scoring import count_edits
from paths import FINDIT_DIR, RESULTS_DIR
from reference.decode_constrained import decode
from reference.decode_roles import decoder_probabilities
from reference.decoded_receipt import receipt_from_labels
from reference.line_features import priced_lines
from reference.line_labels import CLASS_NAMES, ROLE_TO_CLASS
from reference.local_flow import (
    CONFIRM,
    FUSED,
    PASS1,
    RETRY,
    decide_local,
    read,
    sources,
)
from reference.structure import (
    DISCOUNT_WORDS,
    PAYMENT_WORDS,
    TOTAL_WORDS,
    TVA_WORDS,
    ExtractedReceipt,
    _contains,
)
from truth.roles import CONTRIBUTING_ROLES, ITEM, LineTruth, line_truth

DIAGNOSTICS_DIR = RESULTS_DIR / "diagnostics"
TRANSCRIPT_DIRS = {
    "t1test": FINDIT_DIR / "T1-test" / "txt",
    "t1train": FINDIT_DIR / "T1-train" / "txt",
}
ADVERSARIAL_OFFSETS_CENTS = (37, -53, 111)
NAME_MATCH_THRESHOLD = 0.6
LEXICON_PROBES = {
    "total": TOTAL_WORDS,
    "payment": PAYMENT_WORDS,
    "tva": TVA_WORDS,
    "discount": DISCOUNT_WORDS,
}
READINGS = (PASS1, RETRY, FUSED)


@dataclass
class StageResult:
    verified: bool
    edits: int | None
    items: list[tuple[float, float]]
    total: float | None


@dataclass
class TicketDiagnostic:
    name: str
    split: str
    double_validated: bool
    chosen_stage: str
    chosen_edits: int
    stages: dict[str, StageResult]
    concordance: str
    verified_methods: int
    line_confusions: dict[str, list[tuple[str, str]]]
    name_similarities: list[float]
    ocr: dict[str, object]
    adversarial_hits: int
    adversarial_tries: int
    root_cause: str
    notes: list[str] = field(default_factory=list)


def _items(receipt: ExtractedReceipt | None) -> list[tuple[float, float]]:
    if receipt is None:
        return []
    return [(round(i.amount, 2), round(i.discount, 2)) for i in receipt.items]


def _stage(receipt: ExtractedReceipt | None, expected: list[float]) -> StageResult:
    verified = receipt is not None and receipt.checksum_ok
    return StageResult(
        verified=verified,
        edits=count_edits(_items(receipt), expected) if receipt is not None else None,
        items=_items(receipt),
        total=None if receipt is None else receipt.total,
    )


def concordance(stages: dict[str, StageResult]) -> tuple[str, int]:
    """« agree » : tous les étages vérifiés retiennent les mêmes montants ;
    « disagree » : deux étages vérifiés se contredisent — une collision
    quelque part, détectable sans golden."""
    verified = [s for s in stages.values() if s.verified]
    if not verified:
        return "none", 0
    distinct = {tuple(sorted(s.items)) for s in verified}
    return ("agree" if len(distinct) == 1 else "disagree"), len(verified)


def name_similarity(extracted: str, golden: str) -> float:
    return SequenceMatcher(None, extracted.upper(), golden.upper()).ratio()


def _confusions(truths: list[LineTruth], predicted: list[str]) -> list[tuple[str, str]]:
    return [(t.role, p) for t, p in zip(truths, predicted)]


def _tagger_predictions(probas) -> list[str]:
    return [CLASS_NAMES[int(row.argmax())] for row in probas]


def _dp_predictions(lines, probas) -> list[str] | None:
    hypothesis = decode(lines, probas)
    if hypothesis is None:
        return None
    return [CLASS_NAMES[label] for label in hypothesis.labels]


def adversarial_hits(lines, probas, golden_total: float) -> tuple[int, int]:
    """Référence remplacée par une valeur fausse : une collision est une
    solution qui vérifie CETTE valeur fausse. Retrouver le vrai total par
    une autre source (table TVA, espèces − rendu) n'en est pas une."""
    hits = 0
    tries = 0
    for offset in ADVERSARIAL_OFFSETS_CENTS:
        fake_total = round(golden_total + offset / 100, 2)
        if fake_total <= 0:
            continue
        tries += 1
        patched = [
            type(p)(
                p.index,
                p.line,
                fake_total if abs(p.price - golden_total) < 0.005 else p.price,
                p.word,
            )
            for p in lines
        ]
        hypothesis = decode(patched, probas)
        if hypothesis is not None and hypothesis.reference_cents == round(
            fake_total * 100
        ):
            hits += 1
    return hits, tries


def ocr_damage(dump: dict, split: str, doc: str, golden: dict) -> dict[str, object]:
    transcript_path = TRANSCRIPT_DIRS[split] / f"{doc}.json".replace(".json", ".txt")
    result: dict[str, object] = {"transcript": transcript_path.exists()}
    ocr_text = dump.get("fullText", "")
    if transcript_path.exists():
        reference = transcript_path.read_text(encoding="utf-8", errors="replace")
        result["similarity"] = round(
            SequenceMatcher(None, reference.upper(), ocr_text.upper()).ratio(), 3
        )
        result["lexicon_lost"] = [
            name
            for name, lexicon in LEXICON_PROBES.items()
            if _contains(reference, lexicon) and not _contains(ocr_text, lexicon)
        ]
    seen = ocr_amounts(dump)
    expected = [round(float(i["amount"]), 2) for i in golden["receipt"]["items"]]
    result["amounts_missing"] = [
        a
        for a in expected
        if abs(a) >= 0.005 and not any(abs(abs(a) - s) < 0.005 for s in seen)
    ]
    total = round(float(golden["receipt"]["total"]), 2)
    result["total_missing"] = not any(abs(total - s) < 0.005 for s in seen)
    return result


def root_cause(
    chosen_stage: str,
    chosen_edits: int,
    truths: list[LineTruth],
    ml_predicted: list[str],
    ocr: dict[str, object],
) -> str:
    if chosen_stage != CONFIRM:
        return "verified" if chosen_edits == 0 else "verified_wrong"
    if ocr["amounts_missing"]:
        return "ocr_amount_unreadable"
    if ocr["total_missing"]:
        return "ocr_total_unreadable"
    if not any(t.role in ("total", "payment") for t in truths):
        return "reference_line_not_priced"
    wrong_contributing = [
        (t.role, p)
        for t, p in zip(truths, ml_predicted)
        if t.role in CONTRIBUTING_ROLES and p != t.role
    ]
    wrong_noise = [
        (t.role, p)
        for t, p in zip(truths, ml_predicted)
        if t.role not in CONTRIBUTING_ROLES and p in CONTRIBUTING_ROLES
    ]
    if wrong_contributing:
        return "classifier_missed_contributing_line"
    if wrong_noise:
        return "classifier_promoted_noise_line"
    return "reference_not_recognized"


def diagnose_ticket(ticket) -> TicketDiagnostic:
    dump = json.loads(ticket.dump_path.read_text())
    golden = ticket.golden
    expected = [round(float(i["amount"]), 2) for i in golden["receipt"]["items"]]
    readings = {source.name: source for source in sources(dump)}

    stages: dict[str, StageResult] = {}
    confusions: dict[str, list[tuple[str, str]]] = {}
    truths_p1: list[LineTruth] = []
    ml_p1: list[str] = []
    similarities: list[float] = []
    adversarial = (0, 0)
    for name, source in readings.items():
        merged = source.merged
        stages[name] = _stage(read(source), expected)
        priced = priced_lines(merged)
        if not priced:
            continue
        probas = decoder_probabilities(source.roles, priced)
        truths = line_truth(merged, priced, golden)
        tagger_predicted = _tagger_predictions(probas)
        confusions[f"tagger_{name}"] = _confusions(truths, tagger_predicted)
        dp_predicted = _dp_predictions(priced, probas)
        if dp_predicted is not None:
            confusions[f"dp_{name}"] = _confusions(truths, dp_predicted)
        if name == PASS1:
            truths_p1, ml_p1 = truths, tagger_predicted
            adversarial = adversarial_hits(
                priced, probas, round(float(golden["receipt"]["total"]), 2)
            )
            receipt = receipt_from_labels(
                merged, priced, [ROLE_TO_CLASS.get(t.role, 4) for t in truths]
            )
            if receipt is not None:
                golden_names = [
                    t.golden_name for t in truths if t.role == ITEM and t.golden_name
                ]
                for item, golden_name in zip(receipt.items, golden_names):
                    similarities.append(
                        round(name_similarity(item.name, golden_name), 3)
                    )

    outcome = decide_local(dump)
    chosen_edits = count_edits(outcome.amounts, expected)
    agreement, verified_methods = concordance(stages)
    ocr = ocr_damage(dump, ticket.split, ticket.doc, golden)
    return TicketDiagnostic(
        name=ticket.name,
        split=ticket.split,
        double_validated=bool(golden.get("transcript_agrees")),
        chosen_stage=outcome.stage,
        chosen_edits=chosen_edits,
        stages=stages,
        concordance=agreement,
        verified_methods=verified_methods,
        line_confusions=confusions,
        name_similarities=similarities,
        ocr=ocr,
        adversarial_hits=adversarial[0],
        adversarial_tries=adversarial[1],
        root_cause=root_cause(outcome.stage, chosen_edits, truths_p1, ml_p1, ocr),
    )


def _matrix(pairs: list[tuple[str, str]]) -> str:
    truths = sorted({t for t, _ in pairs})
    predicted = sorted({p for _, p in pairs})
    counts = Counter(pairs)
    width = max(len(t) for t in truths) + 2
    header = " " * width + "".join(f"{p:>10}" for p in predicted)
    rows = [header]
    for truth in truths:
        rows.append(
            f"{truth:<{width}}"
            + "".join(f"{counts[(truth, p)]:>10}" for p in predicted)
        )
    return "\n".join(rows)


def report(diagnostics: list[TicketDiagnostic]) -> None:
    total = len(diagnostics)
    print(f"=== diagnostic ({total} tickets)")
    print("\n--- étages (vérifiés / faux vérifiés)")
    for stage in READINGS:
        runs = [d.stages[stage] for d in diagnostics if stage in d.stages]
        if not runs:
            continue
        verified = [r for r in runs if r.verified]
        wrong = [r for r in verified if r.edits]
        print(
            f"  {stage:<12}: {len(verified):>4}/{len(runs):<4} vérifiés, {len(wrong)} faux"
        )

    print("\n--- concordance entre étages vérifiés")
    by_concordance = Counter((d.concordance, d.verified_methods) for d in diagnostics)
    for (agreement, methods), count in sorted(by_concordance.items()):
        wrong = sum(
            1
            for d in diagnostics
            if d.concordance == agreement
            and d.verified_methods == methods
            and d.chosen_edits
            and d.chosen_stage != CONFIRM
        )
        print(
            f"  {agreement:<9} {methods} méthode(s) : {count:>4} tickets, {wrong} faux affichés"
        )

    print("\n--- calibration : taux de faux par niveau de confiance affichable")
    buckets: dict[str, list[int]] = defaultdict(list)
    for d in diagnostics:
        if d.chosen_stage == CONFIRM:
            continue
        key = f"{d.chosen_stage}/{d.concordance}/{min(d.verified_methods, 3)}m"
        buckets[key].append(1 if d.chosen_edits else 0)
    for key, flags in sorted(buckets.items()):
        print(
            f"  {key:<28}: {len(flags):>4} tickets, {sum(flags)} faux ({sum(flags) / len(flags):.1%})"
        )

    print("\n--- causes racines")
    for cause, count in Counter(d.root_cause for d in diagnostics).most_common():
        print(f"  {cause:<36}: {count}")

    for stage in (f"tagger_{PASS1}", f"dp_{PASS1}"):
        pairs = [pair for d in diagnostics for pair in d.line_confusions.get(stage, [])]
        if pairs:
            print(
                f"\n--- confusion lignes {stage} (vérité en ligne, prédit en colonne)"
            )
            print(_matrix(pairs))

    similarities = [s for d in diagnostics for s in d.name_similarities]
    if similarities:
        low = sum(1 for s in similarities if s < NAME_MATCH_THRESHOLD)
        print(
            f"\n--- noms d'articles (lignes vraies) : {len(similarities)} comparés, "
            f"similarité médiane {sorted(similarities)[len(similarities) // 2]:.2f}, "
            f"{low} sous {NAME_MATCH_THRESHOLD} ({low / len(similarities):.1%})"
        )

    hits = sum(d.adversarial_hits for d in diagnostics)
    tries = sum(d.adversarial_tries for d in diagnostics)
    if tries:
        print(
            f"\n--- adversarial décodeur : {hits}/{tries} références fausses « vérifiées » ({hits / tries:.2%})"
        )

    with_transcript = [d for d in diagnostics if d.ocr.get("transcript")]
    if with_transcript:
        sims = sorted(float(d.ocr["similarity"]) for d in with_transcript)
        lost = Counter(
            name for d in with_transcript for name in d.ocr.get("lexicon_lost", [])
        )
        print(
            f"\n--- OCR vs transcription : similarité médiane {sims[len(sims) // 2]:.2f}, "
            f"p10 {sims[len(sims) // 10]:.2f} ; lexiques perdus : {dict(lost)}"
        )


def _load(path: Path) -> list[TicketDiagnostic]:
    diagnostics = []
    for line in path.read_text().splitlines():
        data = json.loads(line)
        data["stages"] = {k: StageResult(**v) for k, v in data["stages"].items()}
        data["line_confusions"] = {
            k: [tuple(pair) for pair in v] for k, v in data["line_confusions"].items()
        }
        diagnostics.append(TicketDiagnostic(**data))
    return diagnostics


def _option(name: str) -> str | None:
    prefix = f"--{name}="
    return next(
        (a.removeprefix(prefix) for a in sys.argv[1:] if a.startswith(prefix)), None
    )


def main() -> None:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    split = _option("split")
    saved = _option("report")
    if saved is not None:
        report(_load(Path(saved)))
        return
    target = args[0] if args else "device_flow"
    tickets = [
        t
        for t in load_tickets(RESULTS_DIR / target)
        if split is None or t.split == split
    ]
    diagnostics = [diagnose_ticket(t) for t in tickets]
    DIAGNOSTICS_DIR.mkdir(parents=True, exist_ok=True)
    out = DIAGNOSTICS_DIR / f"{target}{'_' + split if split else ''}.jsonl"
    with out.open("w") as handle:
        for d in diagnostics:
            handle.write(json.dumps(asdict(d), ensure_ascii=False) + "\n")
    report(diagnostics)
    print(f"\n→ {out}")


if __name__ == "__main__":
    main()
