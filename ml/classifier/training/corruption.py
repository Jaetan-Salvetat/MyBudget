"""Bruit de frappe ajouté à la volée, jamais figé dans le corpus.

Écrire `aamazon` dans `train.jsonl` ferait apprendre `aamazon` en plus
d'`amazon` : une entrée de dictionnaire de plus, exactement ce qu'on ne veut
pas. Corrompre au moment où le lot part dans le modèle donne une faute
différente à chaque epoch — le modèle ne voit jamais deux fois la même et n'a
rien à retenir sinon que le bruit ne compte pas.

Ne vivent ici que les fautes qui survivent à la normalisation : la casse, les
accents et la ponctuation collée sont déjà traités par `serving/normalize.py`,
les faire apprendre au modèle serait dépenser deux fois. Restent les fautes de
lettres, que rien en amont ne peut réparer.

Les opérateurs d'évaluation (`evaluation/robustness.py`) sont tenus à l'écart
de ceux-ci : mesurer avec le bruit de l'entraînement ne mesurerait rien.
"""

import random

AZERTY_ROWS = ("azertyuiop", "qsdfghjklm", "wxcvbn")

CORRUPTION_RATIO = 0.3
MIN_WORD_LENGTH = 4


def build_neighbours(rows: tuple[str, ...]) -> dict[str, str]:
    """Les touches qu'un doigt trop rapide atteint à la place de la bonne."""
    neighbours: dict[str, set[str]] = {}
    for row_index, row in enumerate(rows):
        for column, key in enumerate(row):
            around = neighbours.setdefault(key, set())
            for other_row in (row_index - 1, row_index, row_index + 1):
                if not 0 <= other_row < len(rows):
                    continue
                for other_column in (column - 1, column, column + 1):
                    if not 0 <= other_column < len(rows[other_row]):
                        continue
                    around.add(rows[other_row][other_column])
            around.discard(key)
    return {key: "".join(sorted(around)) for key, around in neighbours.items()}


AZERTY_NEIGHBOURS = build_neighbours(AZERTY_ROWS)


def double_letter(word: str, rng: random.Random) -> str:
    index = rng.randrange(len(word))
    return word[:index] + word[index] + word[index:]


def drop_letter(word: str, rng: random.Random) -> str:
    index = rng.randrange(len(word))
    return word[:index] + word[index + 1 :]


def neighbour_key(word: str, rng: random.Random) -> str:
    index = rng.randrange(len(word))
    around = AZERTY_NEIGHBOURS.get(word[index])
    if not around:
        return word
    return word[:index] + rng.choice(around) + word[index + 1 :]


def insert_key(word: str, rng: random.Random) -> str:
    index = rng.randrange(len(word))
    around = AZERTY_NEIGHBOURS.get(word[index])
    if not around:
        return word
    return word[:index] + rng.choice(around) + word[index:]


TRAIN_OPERATORS = {
    "doublement": double_letter,
    "omission": drop_letter,
    "touche_voisine": neighbour_key,
    "insertion": insert_key,
}


def _candidates(words: list[str]) -> list[int]:
    return [
        index
        for index, word in enumerate(words)
        if len(word) >= MIN_WORD_LENGTH and word.isalpha()
    ]


def corrupt(text: str, rng: random.Random) -> str:
    """Une faute, sur un mot, dans un texte sur trois."""
    if rng.random() >= CORRUPTION_RATIO:
        return text
    words = text.split(" ")
    candidates = _candidates(words)
    if not candidates:
        return text
    index = rng.choice(candidates)
    operator = rng.choice(list(TRAIN_OPERATORS.values()))
    words[index] = operator(words[index], rng)
    return " ".join(words)
