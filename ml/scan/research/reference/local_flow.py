"""Flow local complet rejoué depuis un dump OCR device (passe 1 + retry).

Sur la passe 1 : règles (checksum) → classifieur argmax (re-checksum) →
décodage sous contrainte → tagger de rôles. Si rien ne vérifie, seulement
alors le retry
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
from reference.header_ml import predicted_roles
from reference.lines import PhysicalLine, Word, cluster_lines, deskew_words
from reference.structure import (
    ExtractedItem,
    ExtractedReceipt,
    extract,
    merge_price_fragments,
)
from reference.structure_ml import extract_ml
from reference.structure_roles import extract_roles

POLICY = FlowPolicy(retry_must_not_lose_value=True, confirm_prefill="local")

LOCAL = "local"
LOCAL_RETRY = "local_retry"
LOCAL_ML = "local_ml"
LOCAL_DP = "local_dp"
LOCAL_ROLES = "local_roles"
LOCAL_FUSED = "local_fused"
CONFIRM = "confirm"
VERIFIED_STAGES = (LOCAL, LOCAL_RETRY, LOCAL_ML, LOCAL_DP, LOCAL_ROLES, LOCAL_FUSED)


@dataclass(frozen=True)
class LocalOutcome:
    """Les articles retenus, libellés compris.

    Le libellé n'est pas décoratif : c'est lui qui décide de la catégorie, donc
    de la ligne de budget. Le portage Dart le remonte depuis toujours
    (`FlowOutcome.items` porte des `ExtractedItem`) ; la référence Python ne
    gardait que les montants, et aucune mesure ne pouvait donc voir un libellé
    rattaché au mauvais prix."""

    stage: str
    items: list[ExtractedItem]
    total: float | None

    @property
    def verified(self) -> bool:
        return self.stage in VERIFIED_STAGES

    @property
    def amounts(self) -> list[tuple[float, float]]:
        """Montants seuls — ce que compare le scoreur historique et la
        vérification de parité avec le device."""
        return [(round(i.amount, 2), round(i.discount, 2)) for i in self.items]


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
    passes: list[list[PhysicalLine]],
    use_dp: bool = True,
    use_roles: bool = True,
) -> tuple[str, ExtractedReceipt] | None:
    """Les seconds avis, du plus ancien au plus récent, tous jugés au
    checksum.

    Le tagger de rôles passe **en dernier**, et c'est délibéré : sur une même
    passe, un ticket qu'un étage antérieur fait boucler garde exactement la
    lecture qu'il avait. Il peut en revanche vérifier en passe 1 ce qu'un
    étage antérieur n'aurait vérifié qu'en passe 2 — l'étiquette d'étage
    change alors, jamais les montants. Mesuré sur les 483 tickets de T1-test :
    3 tickets gagnés, **0 lecture modifiée**.

    Le gain se joue ailleurs que sur les scans à plat : sur 20 photos réelles
    annotées, où les règles seules ne vérifient que 20 % des tickets, l'étage
    fait passer la chaîne de 65 % à 75 %."""
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
    if use_roles:
        for lines, merged in zip(passes, merged_passes):
            receipt = extract_roles(merged, predicted_roles(lines))
            if receipt is not None and receipt.checksum_ok:
                return LOCAL_ROLES, receipt
    return None


def _receipt_of_stage(
    stage: str, local: ExtractedReceipt, retry: ExtractedReceipt | None
) -> ExtractedReceipt:
    """Le ticket dont la décision a retenu les articles — `decide` ne rend que
    des montants, les libellés se reprennent à la source."""
    if stage == LOCAL_RETRY and retry is not None:
        return retry
    if stage == CONFIRM and retry is not None:
        return retry
    return local


def _decide_pass(
    local: ExtractedReceipt,
    retry: ExtractedReceipt | None,
    rescue_passes: list[list[PhysicalLine]],
    use_ml: bool,
    use_dp: bool,
    use_roles: bool = True,
) -> LocalOutcome:
    outcome = decide(local, retry, None, None, POLICY)
    if outcome.stage != CONFIRM or not use_ml:
        receipt = _receipt_of_stage(outcome.stage, local, retry)
        return LocalOutcome(outcome.stage, receipt.items, outcome.total)
    rescued = classifier_rescue(rescue_passes, use_dp=use_dp, use_roles=use_roles)
    if rescued is None:
        receipt = _receipt_of_stage(CONFIRM, local, retry)
        return LocalOutcome(CONFIRM, receipt.items, outcome.total)
    stage, receipt = rescued
    return LocalOutcome(stage, receipt.items, receipt.verified_total)


def fused_rescue(passes: list[list[PhysicalLine]]) -> ExtractedReceipt | None:
    """Dernier étage gratuit : les deux passes fusionnées ligne à ligne, le
    décodeur arbitrant les montants qui diffèrent. Sortie re-checksummée."""
    fused = fuse_passes(passes[0], passes[1])
    merged = [merge_price_fragments(line) for line in fused.lines]
    receipt = extract_constrained(merged, alternatives=fused.alternatives)
    if receipt is not None and receipt.checksum_ok:
        return receipt
    return None


def decide_local(
    dump: dict,
    use_ml: bool = True,
    use_dp: bool = True,
    use_roles: bool = True,
) -> LocalOutcome:
    passes = _passes(dump)
    local = extract(passes[0])
    outcome = _decide_pass(local, None, [passes[0]], use_ml, use_dp, use_roles)
    if outcome.verified or len(passes) < 2:
        return outcome
    outcome = _decide_pass(
        local, extract(passes[1]), [passes[1]], use_ml, use_dp, use_roles
    )
    if outcome.verified or not (use_ml and use_dp):
        return outcome
    receipt = fused_rescue(passes)
    if receipt is None:
        return outcome
    return LocalOutcome(LOCAL_FUSED, receipt.items, receipt.verified_total)
