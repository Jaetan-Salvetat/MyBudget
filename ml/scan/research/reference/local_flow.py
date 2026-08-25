"""Flow local complet rejoué depuis un dump OCR device (passe 1 + retry).

Sur la passe 1 : règles (checksum) → classifieur argmax (re-checksum) →
décodage sous contrainte. Si rien ne vérifie, seulement alors le retry
(2e OCR prétraité, l'étage cher) : règles (garde-fou) → classifieur →
décodeur. Mesuré : même précision qu'en tentant le retry avant le
classifieur, moitié moins de retries. C'est LA décision de référence : le
bench la mesure, le portage Dart (`pipeline/lib/src/flow.dart`) la
reproduit, `check_parity.py` vérifie l'égalité ticket par ticket.
"""

from __future__ import annotations

from dataclasses import dataclass

from reference.decode_constrained import extract_constrained
from reference.flow import FlowPolicy, decide
from reference.fuse_passes import fuse_passes
from reference.lines import PhysicalLine, Word, cluster_lines, deskew_words
from reference.structure import ExtractedReceipt, extract, merge_price_fragments
from reference.structure_ml import extract_ml

POLICY = FlowPolicy(retry_must_not_lose_value=True, confirm_prefill="local")

LOCAL = "local"
LOCAL_RETRY = "local_retry"
LOCAL_ML = "local_ml"
LOCAL_DP = "local_dp"
LOCAL_FUSED = "local_fused"
CONFIRM = "confirm"
VERIFIED_STAGES = (LOCAL, LOCAL_RETRY, LOCAL_ML, LOCAL_DP, LOCAL_FUSED)


@dataclass(frozen=True)
class LocalOutcome:
    stage: str
    items: list[tuple[float, float]]
    total: float | None

    @property
    def verified(self) -> bool:
        return self.stage in VERIFIED_STAGES


def clustered_lines(dump: dict) -> list[PhysicalLine]:
    words = []
    angles = []
    for block in dump["blocks"]:
        for line in block["lines"]:
            if line.get("angle") is not None:
                angles.append(line["angle"])
            for element in line["elements"]:
                left, top, right, bottom = element["box"]
                words.append(
                    Word(
                        text=element["text"],
                        left=left,
                        top=top,
                        right=right,
                        bottom=bottom,
                        confidence=element.get("confidence"),
                    )
                )
    angle = sorted(angles)[len(angles) // 2] if angles else 0.0
    return cluster_lines(deskew_words(words, angle))


def _passes(dump: dict) -> list[list[PhysicalLine]]:
    passes = [clustered_lines(dump)]
    if "ocrRetry" in dump:
        passes.append(clustered_lines(dump["ocrRetry"]))
    return passes


def classifier_rescue(
    passes: list[list[PhysicalLine]], use_dp: bool = True
) -> tuple[str, ExtractedReceipt] | None:
    merged_passes = [[merge_price_fragments(line) for line in p] for p in passes]
    for merged in merged_passes:
        receipt = extract_ml(merged)
        if receipt is not None and receipt.checksum_ok:
            return LOCAL_ML, receipt
    if use_dp:
        for merged in merged_passes:
            receipt = extract_constrained(merged)
            if receipt is not None and receipt.checksum_ok:
                return LOCAL_DP, receipt
    return None


def _items_of(receipt_items) -> list[tuple[float, float]]:
    return [(round(i.amount, 2), round(i.discount, 2)) for i in receipt_items]


def _decide_pass(
    local: ExtractedReceipt,
    retry: ExtractedReceipt | None,
    rescue_passes: list[list[PhysicalLine]],
    use_ml: bool,
    use_dp: bool,
) -> LocalOutcome:
    outcome = decide(local, retry, None, None, POLICY)
    if outcome.stage != CONFIRM or not use_ml:
        return LocalOutcome(outcome.stage, outcome.items, outcome.total)
    rescued = classifier_rescue(rescue_passes, use_dp=use_dp)
    if rescued is None:
        return LocalOutcome(CONFIRM, outcome.items, outcome.total)
    stage, receipt = rescued
    return LocalOutcome(stage, _items_of(receipt.items), receipt.verified_total)


def fused_rescue(passes: list[list[PhysicalLine]]) -> ExtractedReceipt | None:
    """Dernier étage gratuit : les deux passes fusionnées ligne à ligne, le
    décodeur arbitrant les montants qui diffèrent. Sortie re-checksummée."""
    fused = fuse_passes(passes[0], passes[1])
    merged = [merge_price_fragments(line) for line in fused.lines]
    receipt = extract_constrained(merged, alternatives=fused.alternatives)
    if receipt is not None and receipt.checksum_ok:
        return receipt
    return None


def decide_local(dump: dict, use_ml: bool = True, use_dp: bool = True) -> LocalOutcome:
    passes = _passes(dump)
    local = extract(passes[0])
    outcome = _decide_pass(local, None, [passes[0]], use_ml, use_dp)
    if outcome.verified or len(passes) < 2:
        return outcome
    outcome = _decide_pass(local, extract(passes[1]), [passes[1]], use_ml, use_dp)
    if outcome.verified or not (use_ml and use_dp):
        return outcome
    receipt = fused_rescue(passes)
    if receipt is None:
        return outcome
    return LocalOutcome(LOCAL_FUSED, _items_of(receipt.items), receipt.verified_total)
