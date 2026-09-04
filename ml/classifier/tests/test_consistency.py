import random

import torch

from training.consistency import consistency_loss
from training.train import MultiLabelDataCollator


class WordTokenizer:
    def __call__(self, texts, truncation, max_length, padding, return_tensors):
        rows = [[hash(word) % 1000 + 1 for word in text.split()][:max_length] for text in texts]
        width = max(len(row) for row in rows)
        ids = torch.tensor([row + [0] * (width - len(row)) for row in rows])
        return {"input_ids": ids, "attention_mask": (ids != 0).long()}


def features(texts: list[str]) -> list[dict]:
    return [
        {"text": text, "type_labels": 0, "category_labels": 1, "recurrence_labels": 0}
        for text in texts
    ]


def test_consistency_loss_is_zero_for_identical_logits():
    logits = torch.randn(4, 10)
    assert consistency_loss(logits, logits.clone()).item() < 1e-6


def test_consistency_loss_grows_with_disagreement():
    anchor = torch.zeros(2, 5)
    anchor[:, 0] = 5.0
    close = anchor.clone()
    close[:, 1] = 1.0
    far = torch.zeros(2, 5)
    far[:, 4] = 5.0
    assert consistency_loss(close, anchor) < consistency_loss(far, anchor)


def test_consistency_loss_survives_an_empty_selection():
    assert consistency_loss(torch.zeros(0, 5), torch.zeros(0, 5)).item() == 0.0


def test_collator_without_noise_adds_nothing_beyond_the_labels():
    collator = MultiLabelDataCollator(WordTokenizer(), None)
    batch = collator(features(["carrefour market", "plein essence"]))
    assert set(batch) == {
        "input_ids", "attention_mask", "type_labels", "category_labels", "recurrence_labels",
    }


def test_collator_keeps_the_clean_view_of_every_corrupted_row():
    always = random.Random(0)
    always.random = lambda: 0.0
    collator = MultiLabelDataCollator(WordTokenizer(), always)
    texts = ["carrefour market courses", "plein essence station"]
    batch = collator(features(texts))
    assert batch["corrupted"].tolist() == [True, True]
    clean = WordTokenizer()(texts, True, 64, True, "pt")
    assert torch.equal(batch["clean_input_ids"], clean["input_ids"])
    assert not torch.equal(batch["input_ids"], clean["input_ids"])


def test_collator_flags_only_the_rows_the_noise_touched():
    never = random.Random(0)
    never.random = lambda: 1.0
    collator = MultiLabelDataCollator(WordTokenizer(), never)
    batch = collator(features(["carrefour market", "plein essence"]))
    assert "corrupted" not in batch
