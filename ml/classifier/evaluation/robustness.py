"""Ce que le modèle perd quand l'utilisateur écrit mal.

`generalization.py` mesure des noms jamais vus, écrits correctement. Personne
n'écrit correctement : les accents sautent, la casse part, la ponctuation colle,
les doigts ripent. La question n'est pas « combien tombe-t-il » mais « où » —
un point perdu sur les accents se répare par une règle déterministe, un point
perdu sur une lettre doublée demande de l'entraînement.

Deux colonnes, donc : le texte brut tel qu'il arrive, et le même passé par
`normalize_query`. L'écart entre les deux est ce que la normalisation rend, et
ce que le modèle n'a pas à apprendre.

Les opérateurs d'ici rejouent les mécanismes de `training/corruption.py` avec
d'autres instances : QWERTY quand l'entraînement sert de l'AZERTY, des voyelles
quand il sert des consonnes, une lettre triplée quand il en double une. Mesurer
un modèle avec exactement le bruit qu'on lui a servi ne mesurerait que sa
mémoire ; le bloc « vu à l'entraînement » est là pour la comparaison.

    uv run python -m evaluation.robustness [--limit 2000]
"""

import argparse
import json
import random
from collections import defaultdict

import torch
from transformers import AutoTokenizer

from evaluation.generalization import BATCH_SIZE, MAX_LENGTH, read_rows
from paths import EVAL_DATA_DIR, MODEL_DIR
from serving.normalize import fold_accents, normalize_query
from training.corruption import (
    TRAIN_OPERATORS,
    build_neighbours,
    words_and_candidates,
)
from taxonomy import LABELS
from training.train import BudgetClassifier

QWERTY_ROWS = ("qwertyuiop", "asdfghjkl", "zxcvbnm")
QWERTY_NEIGHBOURS = build_neighbours(QWERTY_ROWS)

ACCENTED = {"e": "éèê", "a": "àâ", "u": "ùû", "i": "î", "o": "ô", "c": "ç"}
GLUING_PUNCTUATION = "&/-,+"
# Les voyelles, quand l'entraînement ne sert que des consonnes : même mécanisme,
# instances jamais vues. Un modèle qui a compris que le bruit ne compte pas tient
# ici ; un modèle qui a appris nos règles s'effondre.
PHONETIC_VOWELS = (
    ("au", "o"), ("eau", "o"), ("ai", "e"), ("ei", "e"), ("ou", "u"),
    ("oi", "wa"), ("er", "e"), ("ent", "an"), ("y", "i"), ("in", "un"),
)
TYPOS_PATH = EVAL_DATA_DIR / "typos.json"
DEFAULT_LIMIT = 2000
SAMPLE_SEED = 7


def strip_accents(text: str, rng: random.Random) -> str:
    return fold_accents(text)


def add_accents(text: str, rng: random.Random) -> str:
    """L'inverse : le clavier du téléphone accentue ce que le corpus n'accentue pas."""
    positions = [index for index, char in enumerate(text) if char.lower() in ACCENTED]
    if not positions:
        return text
    index = rng.choice(positions)
    return text[:index] + rng.choice(ACCENTED[text[index].lower()]) + text[index + 1 :]


def upper_case(text: str, rng: random.Random) -> str:
    return text.upper()


def glue_punctuation(text: str, rng: random.Random) -> str:
    """« père & fils » tapé « père &fils » : la ponctuation mange son espace."""
    spaces = [index for index, char in enumerate(text) if char == " "]
    if not spaces:
        return text
    index = rng.choice(spaces)
    return text[:index] + rng.choice(GLUING_PUNCTUATION) + text[index + 1 :]


def triple_letter(text: str, rng: random.Random) -> str:
    """« amaaazon » : deux fautes d'un coup, au-delà de ce que l'entraînement sert."""
    words, candidates = words_and_candidates(text)
    if not candidates:
        return text
    position = rng.choice(candidates)
    word = words[position]
    index = rng.randrange(len(word))
    words[position] = word[:index] + word[index] * 3 + word[index + 1 :]
    return " ".join(words)


def phonetic_vowels(text: str, rng: random.Random) -> str:
    """Écrire au son, côté voyelles : « oto », « resto u », « wazo »."""
    applicable = [rule for rule in PHONETIC_VOWELS if rule[0] in text.lower()]
    if not applicable:
        return text
    before, after = rng.choice(applicable)
    lowered = text.lower()
    return lowered.replace(before, after, 1)


def qwerty_key(text: str, rng: random.Random) -> str:
    words, candidates = words_and_candidates(text)
    if not candidates:
        return text
    position = rng.choice(candidates)
    word = words[position]
    index = rng.randrange(len(word))
    around = QWERTY_NEIGHBOURS.get(word[index])
    if not around:
        return text
    words[position] = word[:index] + rng.choice(around) + word[index + 1 :]
    return " ".join(words)


NORMALIZATION_OPERATORS = {
    "accents retirés": strip_accents,
    "accents ajoutés": add_accents,
    "majuscules": upper_case,
    "ponctuation collée": glue_punctuation,
}

EVAL_ONLY_OPERATORS = {
    "phonétique voyelles": phonetic_vowels,
    "touche qwerty": qwerty_key,
    "lettre triplée": triple_letter,
}

SEEN_AT_TRAINING = TRAIN_OPERATORS


def predict(model, tokenizer, texts: list[str]) -> list[int]:
    indices: list[int] = []
    for start in range(0, len(texts), BATCH_SIZE):
        encoded = tokenizer(
            texts[start : start + BATCH_SIZE],
            return_tensors="pt",
            padding=True,
            truncation=True,
            max_length=MAX_LENGTH,
        )
        with torch.no_grad():
            output = model(
                input_ids=encoded["input_ids"], attention_mask=encoded["attention_mask"]
            )
        indices += output.category_logits.argmax(dim=-1).tolist()
    return indices


def accuracy(model, tokenizer, texts: list[str], expected: list[int]) -> float:
    predicted = predict(model, tokenizer, texts)
    return sum(p == e for p, e in zip(predicted, expected)) / len(expected)


def sample(rows: list[dict], limit: int) -> list[dict]:
    if limit <= 0 or limit >= len(rows):
        return rows
    return random.Random(SAMPLE_SEED).sample(rows, limit)


def report_real_faults(model, tokenizer) -> None:
    """La faute qu'un francophone fait vraiment, sur un nom que la base connaît."""
    if not TYPOS_PATH.exists():
        return
    cases = json.loads(TYPOS_PATH.read_text(encoding="utf-8"))["cases"]
    by_axis: dict[str, list[dict]] = defaultdict(list)
    for case in cases:
        by_axis[case["axis"]].append(case)

    print(f"\nFautes réelles ({len(cases)} cas, noms connus de la base)")
    print(f"  {'axe':16s}{'écrit juste':>13s}{'tel que tapé':>14s}")
    for axis, group in sorted(by_axis.items()):
        expected = [LABELS.index(case["category"]) for case in group]
        clean = accuracy(
            model, tokenizer, [normalize_query(case["clean"]) for case in group], expected
        )
        typed = accuracy(
            model, tokenizer, [normalize_query(case["input"]) for case in group], expected
        )
        print(f"  {axis:16s}{clean:12.0%}{typed:14.0%}   ({len(group)})")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--limit", type=int, default=DEFAULT_LIMIT)
    options = parser.parse_args()

    rows = sample(read_rows(), options.limit)
    texts = [row["text"] for row in rows]
    expected = [row["category_label"] for row in rows]

    model = BudgetClassifier.from_pretrained(str(MODEL_DIR)).eval()
    tokenizer = AutoTokenizer.from_pretrained(str(MODEL_DIR))

    print(f"Modèle : {MODEL_DIR}")
    print(f"Entités jamais vues : {len(rows)}\n")
    print(f"{'Opérateur':22s}{'brut':>9s}{'normalisé':>12s}")

    clean_raw = accuracy(model, tokenizer, texts, expected)
    clean_norm = accuracy(model, tokenizer, [normalize_query(t) for t in texts], expected)
    print(f"{'(aucun)':22s}{clean_raw:8.1%}{clean_norm:12.1%}")

    blocks = (
        ("Absorbé par la normalisation", NORMALIZATION_OPERATORS),
        ("Jamais vu à l'entraînement", EVAL_ONLY_OPERATORS),
        ("Vu à l'entraînement", SEEN_AT_TRAINING),
    )
    for title, operators in blocks:
        print(f"\n{title}")
        for name, operator in operators.items():
            rng = random.Random(SAMPLE_SEED)
            noisy = [operator(text, rng) for text in texts]
            raw = accuracy(model, tokenizer, noisy, expected)
            normalized = accuracy(
                model, tokenizer, [normalize_query(t) for t in noisy], expected
            )
            print(f"  {name:20s}{raw:8.1%}{normalized:12.1%}")

    report_real_faults(model, tokenizer)


if __name__ == "__main__":
    main()
