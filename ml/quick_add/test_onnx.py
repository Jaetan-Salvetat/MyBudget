"""Vérifie l'artefact réellement livré, pas les poids PyTorch.

L'app n'embarque pas `output/best/` mais son export quantifié en int8. Deux
questions restent ouvertes après `export_onnx.py` : le graphe exporté rend-il
les mêmes décisions que le modèle d'origine, et la quantification a-t-elle coûté
de la justesse ? Ce script répond aux deux avant publication.
"""

import json
import os
from pathlib import Path

import numpy as np
import onnxruntime as ort
import torch
from transformers import AutoTokenizer

from taxonomy import LABELS, canonical
from train import MAX_LENGTH, BudgetClassifier

ROOT = Path(__file__).parent
MODEL_PATH = Path(os.environ.get("QUICK_ADD_MODEL", ROOT / "output" / "best"))
ONNX_PATH = Path(os.environ.get("QUICK_ADD_EXPORT_DIR", ROOT / "output")) / "model.onnx"
CORPORA = ("eval_world.json", "eval_corpus.json")

TYPE_LABELS = ["expense", "income"]
RECURRENCE_LABELS = ["ponctuel", "fixe"]


def _cases(name: str) -> list[dict]:
    return json.loads((ROOT / name).read_text(encoding="utf-8"))["cases"]


def _feed(tokenizer, text: str) -> dict:
    tokens = tokenizer(text, return_tensors="np", truncation=True, max_length=MAX_LENGTH)
    return {
        "input_ids": tokens["input_ids"].astype(np.int64),
        "attention_mask": tokens["attention_mask"].astype(np.int64),
    }


def main() -> None:
    tokenizer = AutoTokenizer.from_pretrained(str(MODEL_PATH))
    session = ort.InferenceSession(str(ONNX_PATH))
    reference = BudgetClassifier.from_pretrained(str(MODEL_PATH))
    reference.eval()

    agreements = 0
    total_cases = 0
    for name in CORPORA:
        cases = _cases(name)
        categories = types = recurrences = 0
        for case in cases:
            feed = _feed(tokenizer, case["input"])
            outputs = session.run(None, feed)

            with torch.no_grad():
                expected = reference(
                    input_ids=torch.from_numpy(feed["input_ids"]),
                    attention_mask=torch.from_numpy(feed["attention_mask"]),
                )
            agreements += all(
                int(np.argmax(onnx_logits)) == int(torch_logits.argmax(-1).item())
                for onnx_logits, torch_logits in zip(
                    outputs,
                    (expected.type_logits, expected.category_logits, expected.recurrence_logits),
                )
            )
            total_cases += 1

            types += TYPE_LABELS[int(np.argmax(outputs[0]))] == case["type"]
            categories += LABELS[int(np.argmax(outputs[1]))] == canonical(case["category"])
            recurrences += RECURRENCE_LABELS[int(np.argmax(outputs[2]))] == case["recurrence"]

        count = len(cases)
        print(
            f"{name:18s} catégorie {categories}/{count} ({categories / count:.0%})  "
            f"type {types}/{count}  récurrence {recurrences}/{count}"
        )

    print(f"\nAccord int8 / PyTorch : {agreements}/{total_cases} ({agreements / total_cases:.1%})")


if __name__ == "__main__":
    main()
