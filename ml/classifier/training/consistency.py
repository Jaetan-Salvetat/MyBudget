import torch
import torch.nn.functional as F

CONSISTENCY_WEIGHT = 1.0


def consistency_loss(noisy_logits: torch.Tensor, anchor_logits: torch.Tensor) -> torch.Tensor:
    if noisy_logits.shape[0] == 0:
        return noisy_logits.sum()
    return F.kl_div(
        F.log_softmax(noisy_logits, dim=-1),
        F.softmax(anchor_logits, dim=-1),
        reduction="batchmean",
    )
