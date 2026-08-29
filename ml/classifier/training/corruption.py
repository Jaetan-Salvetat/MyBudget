"""Bruit de frappe ajouté à la volée, jamais figé dans le corpus.

Écrire `aamazon` dans `train.jsonl` ferait apprendre `aamazon` en plus
d'`amazon` : une entrée de dictionnaire de plus, exactement ce qu'on ne veut
pas. Corrompre au moment où le lot part dans le modèle donne une faute
différente à chaque epoch — le modèle ne voit jamais deux fois la même et n'a
rien à retenir sinon que le bruit ne compte pas. C'est au modèle de comprendre
que `aamazon` est `amazon`, pas à une table de correction en amont.

Ne vivent ici que les fautes qui survivent à la normalisation : la casse et les
accents sont traités par `serving/normalize.py`, les faire apprendre au modèle
serait dépenser deux fois. Restent les fautes de lettres et les espaces perdus,
que rien en amont ne peut réparer.

`evaluation/robustness.py` garde en réserve de quoi mesurer la généralisation du
bruit lui-même : le même mécanisme, jamais la même instance. Le clavier AZERTY
ici, QWERTY là-bas ; les digrammes de consonnes ici, les voyelles là-bas ; la
lettre doublée ici, triplée là-bas. C'est la seule façon de distinguer un modèle
qui a compris l'invariance d'un modèle qui a appris nos opérateurs.
"""

import random
from typing import Callable

AZERTY_ROWS = ("azertyuiop", "qsdfghjklm", "wxcvbn")

# Écrire au son, côté consonnes : « farmacie », « koiffeur », « batème ». Les
# règles de voyelles (« oto » pour auto, « wazo » pour oiseau) sont tenues en
# réserve pour l'évaluation — même mécanisme, autres instances.
PHONETIC_CONSONANTS = (
    ("ph", "f"), ("qu", "k"), ("ck", "k"), ("ss", "s"), ("th", "t"),
    ("gu", "g"), ("sc", "s"), ("tt", "t"), ("ll", "l"), ("mm", "m"),
    ("nn", "n"), ("rr", "r"), ("pp", "p"), ("ff", "f"), ("cc", "c"),
)

CORRUPTION_RATIO = 0.3
SECOND_FAULT_RATIO = 0.25
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


def swap_letters(word: str, rng: random.Random) -> str:
    index = rng.randrange(len(word) - 1)
    return word[:index] + word[index + 1] + word[index] + word[index + 2 :]


def phonetic_consonant(word: str, rng: random.Random) -> str:
    applicable = [rule for rule in PHONETIC_CONSONANTS if rule[0] in word]
    if not applicable:
        return word
    before, after = rng.choice(applicable)
    return word.replace(before, after, 1)


def split_word(word: str, rng: random.Random) -> str:
    """L'espace de trop : « carre four », le doigt qui frappe la barre trop tôt."""
    cut = rng.randrange(2, len(word) - 1)
    return f"{word[:cut]} {word[cut:]}"


def words_and_candidates(text: str) -> tuple[list[str], list[int]]:
    words = text.split(" ")
    return words, [
        index
        for index, word in enumerate(words)
        if len(word) >= MIN_WORD_LENGTH and word.isalpha()
    ]


def on_a_word(operator: Callable[[str, random.Random], str]):
    """Une faute tombe sur un mot assez long pour la porter, jamais sur un nombre."""

    def apply(text: str, rng: random.Random) -> str:
        words, candidates = words_and_candidates(text)
        if not candidates:
            return text
        index = rng.choice(candidates)
        words[index] = operator(words[index], rng)
        return " ".join(words)

    return apply


def lost_space(text: str, rng: random.Random) -> str:
    """« carrefour city » tapé d'un seul tenant : deux mots collés en un."""
    words = text.split(" ")
    joinable = [
        index
        for index in range(len(words) - 1)
        if words[index].isalpha()
        and words[index + 1].isalpha()
        and max(len(words[index]), len(words[index + 1])) >= MIN_WORD_LENGTH
    ]
    if not joinable:
        return text
    index = rng.choice(joinable)
    return " ".join(
        words[:index] + [words[index] + words[index + 1]] + words[index + 2 :]
    )


TRAIN_OPERATORS = {
    "doublement": on_a_word(double_letter),
    "omission": on_a_word(drop_letter),
    "touche_voisine": on_a_word(neighbour_key),
    "insertion": on_a_word(insert_key),
    "transposition": on_a_word(swap_letters),
    "phonetique": on_a_word(phonetic_consonant),
    "mot_coupe": on_a_word(split_word),
    "espace_perdu": lost_space,
}


def corrupt(text: str, rng: random.Random) -> str:
    """Une faute dans un texte sur trois, deux fautes dans un quart de ceux-là."""
    if rng.random() >= CORRUPTION_RATIO:
        return text
    operators = list(TRAIN_OPERATORS.values())
    noisy = rng.choice(operators)(text, rng)
    if rng.random() < SECOND_FAULT_RATIO:
        noisy = rng.choice(operators)(noisy, rng)
    return noisy
