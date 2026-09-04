import torch
import torch.nn.functional as F

from taxonomy import LABELS

FAMILY_LOSS_WEIGHT = 1.0


def family_of(slug: str) -> str:
    return slug.split(".", 1)[0]


FAMILIES: list[str] = list(dict.fromkeys(family_of(slug) for slug in LABELS))
FAMILY_INDEX: dict[str, int] = {name: index for index, name in enumerate(FAMILIES)}
CATEGORY_FAMILY = torch.tensor([FAMILY_INDEX[family_of(slug)] for slug in LABELS])


def membership() -> torch.Tensor:
    table = torch.zeros(len(FAMILIES), len(LABELS), dtype=torch.bool)
    table[CATEGORY_FAMILY, torch.arange(len(LABELS))] = True
    return table


def family_logits(category_logits: torch.Tensor, table: torch.Tensor) -> torch.Tensor:
    expanded = category_logits.unsqueeze(1).expand(-1, table.shape[0], -1)
    masked = expanded.masked_fill(~table.unsqueeze(0), float("-inf"))
    return torch.logsumexp(masked, dim=-1)


def family_labels(category_labels: torch.Tensor) -> torch.Tensor:
    return CATEGORY_FAMILY.to(category_labels.device)[category_labels]


def family_loss(
    category_logits: torch.Tensor, category_labels: torch.Tensor, table: torch.Tensor
) -> torch.Tensor:
    return F.cross_entropy(family_logits(category_logits, table), family_labels(category_labels))


def decode_within_family(category_logits: torch.Tensor, table: torch.Tensor) -> torch.Tensor:
    best_family = family_logits(category_logits, table).argmax(dim=-1)
    allowed = table.to(category_logits.device)[best_family]
    return category_logits.masked_fill(~allowed, float("-inf")).argmax(dim=-1)
