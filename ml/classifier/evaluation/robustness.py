"""Ce que le modèle perd quand l'utilisateur écrit mal.

`generalization.py` mesure des noms jamais vus, écrits correctement. Personne
n'écrit correctement : les accents sautent, la casse part, la ponctuation colle,
les doigts ripent. La question n'est pas « combien tombe-t-il » mais « où » —
un point perdu sur les accents se répare par une règle déterministe, un point
perdu sur une lettre doublée demande de l'entraînement.

Deux colonnes, donc : le texte brut tel qu'il arrive, et le même passé par
`normalize_query`. L'écart entre les deux est ce que la normalisation rend, et
ce que le modèle n'a pas à apprendre.

Les opérateurs d'ici sont tenus à l'écart de ceux de `training/corruption.py` :
mesurer un modèle avec le bruit qu'on lui a servi ne mesure que sa mémoire.
Seul le bloc « déjà vus » les rejoue, pour comparaison.

    uv run python -m evaluation.robustness [--limit 2000]
"""

import argparse
import random

import torch
from transformers import AutoTokenizer

from evaluation.generalization import BATCH_SIZE, MAX_LENGTH, read_rows
from paths import MODEL_DIR
from serving.normalize import fold_accents, normalize_query
from training.corruption import MIN_WORD_LENGTH, TRAIN_OPERATORS, build_neighbours
from training.train import BudgetClassifier

QWERTY_ROWS = ("qwertyuiop", "asdfghjkl", "zxcvbnm")
QWERTY_NEIGHBOURS = build_neighbours(QWERTY_ROWS)

ACCENTED = {"e": "éèê", "a": "àâ", "u": "ùû", "i": "î", "o": "ô", "c": "ç"}
GLUING_PUNCTUATION = "&/-,+"
PHONETIC = (
    ("ph", "f"), ("qu", "k"), ("au", "o"), ("ai", "e"), ("ei", "e"), ("ou", "u"),
    ("y", "i"), ("x", "ks"), ("ck", "k"), ("ss", "s"), ("th", "t"), ("gu", "g"),
    ("eau", "o"), ("er", "é"), ("ent", "an"), ("oi", "wa"),
)
DEFAULT_LIMIT = 2000
SAMPLE_SEED = 7


def _words(text: str) -> tuple[list[str], list[int]]:
    words = text.split(" ")
    return words, [
        index
        for index, word in enumerate(words)
        if len(word) >= MIN_WORD_LENGTH and word.isalpha()
    ]


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


def transpose(text: str, rng: random.Random) -> str:
    words, candidates = _words(text)
    if not candidates:
        return text
    position = rng.choice(candidates)
    word = words[position]
    index = rng.randrange(len(word) - 1)
    words[position] = word[:index] + word[index + 1] + word[index] + word[index + 2 :]
    return " ".join(words)


def phonetic(text: str, rng: random.Random) -> str:
    """Écrire au son : « farmacie », « boulangerie » → « boulanjerie »."""
    applicable = [(before, after) for before, after in PHONETIC if before in text.lower()]
    if not applicable:
        return text
    before, after = rng.choice(applicable)
    lowered = text.lower()
    return lowered.replace(before, after, 1)


def qwerty_key(text: str, rng: random.Random) -> str:
    words, candidates = _words(text)
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


def lost_space(text: str, rng: random.Random) -> str:
    """« carrefour city » tapé d'un seul tenant : rien en amont ne le recolle."""
    spaces = [index for index, char in enumerate(text) if char == " "]
    if not spaces:
        return text
    index = rng.choice(spaces)
    return text[:index] + text[index + 1 :]


NORMALIZATION_OPERATORS = {
    "accents retirés": strip_accents,
    "accents ajoutés": add_accents,
    "majuscules": upper_case,
    "ponctuation collée": glue_punctuation,
}

EVAL_ONLY_OPERATORS = {
    "transposition": transpose,
    "phonétique": phonetic,
    "touche qwerty": qwerty_key,
    "espace perdu": lost_space,
}


def _always(operator):
    """Les opérateurs d'entraînement tirent au sort ; ici on mesure à coup sûr."""

    def apply(text: str, rng: random.Random) -> str:
        words, candidates = _words(text)
        if not candidates:
            return text
        position = rng.choice(candidates)
        words[position] = operator(words[position], rng)
        return " ".join(words)

    return apply


SEEN_AT_TRAINING = {name: _always(op) for name, op in TRAIN_OPERATORS.items()}


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


if __name__ == "__main__":
    main()
