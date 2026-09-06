"""Vérifie l'artefact réellement livré, pas les poids PyTorch.

L'app n'embarque pas `output/best/` mais son export quantifié en int8. Deux
questions restent ouvertes après `export_onnx.py` : le graphe exporté rend-il
les mêmes décisions que le modèle d'origine, et la quantification a-t-elle coûté
de la justesse ? Ce script répond aux deux avant publication.
"""

import json
from pathlib import Path

import numpy as np
import onnxruntime as ort
import torch
from transformers import AutoTokenizer

from paths import MODEL_DIR, ONNX_PATH, QUICK_ADD_CORPUS, WORLD_CORPUS
from serving.normalize import normalize_query
from taxonomy import LABELS, canonical
from training.train import MAX_LENGTH, BudgetClassifier

MODEL_PATH = MODEL_DIR
CORPORA = (WORLD_CORPUS, QUICK_ADD_CORPUS)

TYPE_LABELS = ["expense", "income"]
RECURRENCE_LABELS = ["ponctuel", "fixe"]


def _cases(path: Path) -> list[dict]:
    return json.loads(path.read_text(encoding="utf-8"))["cases"]


def _feed(tokenizer, text: str) -> dict:
    """Le corpus est écrit comme l'utilisateur tape ; le modèle lit la forme canonique."""
    tokens = tokenizer(
        normalize_query(text), return_tensors="np", truncation=True, max_length=MAX_LENGTH
    )
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
    for corpus_path in CORPORA:
        cases = _cases(corpus_path)
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
            f"{corpus_path.stem:18s} catégorie {categories}/{count} ({categories / count:.0%})  "
            f"type {types}/{count}  récurrence {recurrences}/{count}"
        )

    print(f"\nAccord int8 / PyTorch : {agreements}/{total_cases} ({agreements / total_cases:.1%})")


if __name__ == "__main__":
    main()
