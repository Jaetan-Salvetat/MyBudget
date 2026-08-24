"""Politique de décision du flow scan complet.

local (checksum) → retry prétraité (checksum) → escalade cloud
(re-checksum sur la sortie cloud) → écran de confirmation pré-rempli.
Logique pure, sans I/O : c'est elle que le bench calibre et que le
portage Dart reproduira.
"""

from __future__ import annotations

from dataclasses import dataclass

from structure import ExtractedReceipt

LOCAL = "local"
LOCAL_RETRY = "local_retry"
CLOUD = "cloud"
CONFIRM = "confirm"

AUTO_STAGES = (LOCAL, LOCAL_RETRY, CLOUD)

CloudItems = list[tuple[float, float]]


@dataclass(frozen=True)
class FlowPolicy:
    tolerance: float = 0.005
    cross_check_local_total: bool = False
    confirm_prefill: str = "cloud"
    retry_must_not_lose_value: bool = False


@dataclass(frozen=True)
class FlowOutcome:
    stage: str
    items: CloudItems
    total: float | None


def _items_of(receipt: ExtractedReceipt) -> CloudItems:
    return [
        (round(item.amount, 2), round(item.discount, 2))
        for item in receipt.items
    ]


def _local_total(
    local: ExtractedReceipt, retry: ExtractedReceipt | None
) -> float | None:
    if local.total is not None:
        return local.total
    return retry.total if retry is not None else None


def _retry_loses_value(
    local: ExtractedReceipt,
    retry: ExtractedReceipt,
    policy: FlowPolicy,
) -> bool:
    """Un retry qui somme moins que la passe 1 a perdu des articles : son
    checksum peut passer par collision de substitution sur le total (vu sur
    corpus), on l'envoie en confirmation plutôt que de valider en silence."""
    if not policy.retry_must_not_lose_value:
        return False
    return retry.items_sum < local.items_sum - policy.tolerance


def cloud_accepts(
    cloud_items: CloudItems,
    cloud_total: float | None,
    local_total: float | None,
    policy: FlowPolicy,
) -> bool:
    if cloud_total is None:
        return False
    items_sum = round(
        sum(amount - discount for amount, discount in cloud_items), 2
    )
    if abs(items_sum - cloud_total) > policy.tolerance:
        return False
    if (
        policy.cross_check_local_total
        and local_total is not None
        and abs(cloud_total - local_total) > policy.tolerance
    ):
        return False
    return True


def decide(
    local: ExtractedReceipt,
    retry: ExtractedReceipt | None,
    cloud_items: CloudItems | None,
    cloud_total: float | None,
    policy: FlowPolicy,
) -> FlowOutcome:
    if local.checksum_ok:
        return FlowOutcome(LOCAL, _items_of(local), local.total)
    if (
        retry is not None
        and retry.checksum_ok
        and not _retry_loses_value(local, retry, policy)
    ):
        return FlowOutcome(LOCAL_RETRY, _items_of(retry), retry.total)

    if cloud_items is not None and cloud_accepts(
        cloud_items, cloud_total, _local_total(local, retry), policy
    ):
        return FlowOutcome(CLOUD, cloud_items, cloud_total)

    if cloud_items is not None and policy.confirm_prefill == "cloud":
        return FlowOutcome(CONFIRM, cloud_items, cloud_total)
    best_local = retry if retry is not None else local
    return FlowOutcome(CONFIRM, _items_of(best_local), best_local.total)
