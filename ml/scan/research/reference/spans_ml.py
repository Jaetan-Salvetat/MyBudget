"""Le libellé d'un article, décidé mot à mot sur la ligne qui le porte.

Le modèle de lien désigne la ligne ; ce modèle-ci dit quels mots de cette
ligne composent le nom. Il remplace la coupe de colonne des règles
(`_label_zone`) et le nettoyage par expressions régulières (`_clean_name`) :
un ticket imprime plusieurs colonnes de nombres, et une coupe unique laisse
passer le code article à gauche comme la quantité à droite.

Le décodage impose ce que le libellé est par nature — **un intervalle contigu
de mots portant des lettres** — et rien de plus. Aucun seuil : l'intervalle
retenu est simplement celui dont la somme des log-odds est la plus forte, et
un mot n'y entre que s'il rapporte plus qu'il ne coûte.
"""

from __future__ import annotations

import math

import joblib
import numpy as np

from paths import SPAN_MODEL_PATH
from reference.lines import PhysicalLine
from reference.word_features import featurize

# Un libellé nomme un article : il porte des lettres. Deux, pour écarter
# l'initiale isolée qu'un OCR laisse traîner à côté d'un nombre.
MIN_LETTERS = 2
PROBABILITY_CLIP = 1e-6

_model = None


def load_span_model():
    global _model
    if _model is None:
        _model = joblib.load(SPAN_MODEL_PATH)
    return _model


def _logit(probability: float) -> float:
    clipped = min(max(probability, PROBABILITY_CLIP), 1 - PROBABILITY_CLIP)
    return math.log(clipped / (1 - clipped))


def _letters(texts: list[str], start: int, end: int) -> int:
    return sum(char.isalpha() for text in texts[start:end] for char in text)


def best_span(
    texts: list[str], probabilities: list[float]
) -> tuple[int, int] | None:
    """L'intervalle `[début, fin)` de log-odds maximale parmi ceux qui portent
    des lettres, ou None si la ligne n'en porte aucune."""
    if not texts:
        return None
    odds = [_logit(probability) for probability in probabilities]
    best: tuple[float, int, int] | None = None
    span = None
    for start in range(len(texts)):
        running = 0.0
        for end in range(start + 1, len(texts) + 1):
            running += odds[end - 1]
            if _letters(texts, start, end) < MIN_LETTERS:
                continue
            score = (running, end - start, -start)
            if best is None or score > best:
                best = score
                span = (start, end)
    return span


def span_text(texts: list[str], span: tuple[int, int]) -> str:
    return " ".join(texts[span[0] : span[1]]).strip()


def label_probabilities(lines: list[PhysicalLine]) -> list[list[float]]:
    """Pour chaque mot de chaque ligne, la probabilité qu'il appartienne au
    libellé d'un article."""
    rows = featurize(lines)
    flat = [vector for line in rows for vector in line]
    if not flat:
        return [[] for _ in rows]
    scores = load_span_model().predict_proba(np.array(flat))[:, 1]
    probabilities = []
    cursor = 0
    for line in rows:
        probabilities.append([float(value) for value in scores[cursor : cursor + len(line)]])
        cursor += len(line)
    return probabilities


def label_of(line: PhysicalLine, probabilities: list[float]) -> str | None:
    """Le libellé que porte cette ligne, ou None si elle n'en porte pas."""
    texts = [word.text for word in line.words]
    span = best_span(texts, probabilities)
    return span_text(texts, span) if span is not None else None
