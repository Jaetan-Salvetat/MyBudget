"""Flow local complet rejoué depuis un dump OCR device (passe 1 + retry).

règles (checksum) → retry (checksum, garde-fou) → classifieur argmax
(re-checksum) → décodage sous contrainte → non vérifié. C'est LA décision de
référence : le bench la mesure, le portage Dart (`pipeline/lib/src/flow.dart`)
la reproduit, `check_parity.py` vérifie l'égalité ticket par ticket.
"""

from __future__ import annotations

from dataclasses import dataclass

from decode_constrained import extract_constrained
from flow import FlowPolicy, decide
from lines import PhysicalLine, Word, cluster_lines, deskew_words
from structure import ExtractedReceipt, extract, merge_price_fragments
from structure_ml import extract_ml

POLICY = FlowPolicy(retry_must_not_lose_value=True, confirm_prefill="local")

LOCAL = "local"
LOCAL_RETRY = "local_retry"
LOCAL_ML = "local_ml"
LOCAL_DP = "local_dp"
CONFIRM = "confirm"
VERIFIED_STAGES = (LOCAL, LOCAL_RETRY, LOCAL_ML, LOCAL_DP)


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


def decide_local(dump: dict, use_ml: bool = True, use_dp: bool = True) -> LocalOutcome:
    passes = _passes(dump)
    local = extract(passes[0])
    retry = extract(passes[1]) if len(passes) > 1 else None
    outcome = decide(local, retry, None, None, POLICY)
    if outcome.stage != CONFIRM or not use_ml:
        return LocalOutcome(outcome.stage, outcome.items, outcome.total)
    rescued = classifier_rescue(passes, use_dp=use_dp)
    if rescued is None:
        return LocalOutcome(CONFIRM, outcome.items, outcome.total)
    stage, receipt = rescued
    return LocalOutcome(stage, _items_of(receipt.items), receipt.total)
