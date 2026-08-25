"""Normalisation d'un libellé de ticket avant le modèle.

Ce qu'une caisse imprime et que personne ne tape : astérisques de tête,
codes-barres, contenances (« 4X125G », « 75CL »), compteurs (« X6 »),
codes de rayon. Tout est en majuscules sans accent : on passe en minuscules,
la forme de l'entraînement. Rien n'est réécrit, on ne fait que retirer.
Doit rester portable en Dart à l'identique.
"""

import re

_LEADING_MARKERS = re.compile(r"^[\s*#!.\-]+")
_TRAILING_MARKERS = re.compile(r"[\s*#!.\-]+$")
_LONG_CODE = re.compile(r"\b\d{5,}\b")
_QUANTITY = re.compile(
    r"\b\d+(?:[.,]\d+)?\s?(?:x\s?\d+(?:[.,]\d+)?\s?)?(?:g|gr|grs|kg|l|cl|ml|mg|m|cm|mm|w|d|p|pl|t|tr|rlx|dos|st|pce|pcs)\b",
    re.IGNORECASE,
)
_COUNT = re.compile(r"(?:\b|(?<=\s))x\s?\d+\b|\b\d+\s?x\b", re.IGNORECASE)
_FRACTION = re.compile(r"\b\d/\d\b")
_PERCENT = re.compile(r"\b\d+(?:[.,]\d+)?\s?%(?:\s?mg)?", re.IGNORECASE)
_LEADING_COUNT = re.compile(r"^\d{1,2}\s+(?=\D)")
_LONE_NUMBER = re.compile(r"\b\d+(?:[.,]\d+)?\b")
_SPACES = re.compile(r"\s+")
_DOT_GLUE = re.compile(r"(?<=[^\W\d])\.(?=[^\W\d])")


def normalize_receipt_line(line: str) -> str:
    text = _LEADING_MARKERS.sub("", line)
    text = _TRAILING_MARKERS.sub("", text)
    text = _LONG_CODE.sub(" ", text)
    text = _PERCENT.sub(" ", text)
    text = _QUANTITY.sub(" ", text)
    text = _COUNT.sub(" ", text)
    text = _FRACTION.sub(" ", text)
    text = _LEADING_COUNT.sub("", text)
    text = _LONE_NUMBER.sub(" ", text)
    text = _DOT_GLUE.sub(" ", text)
    text = text.replace("/", " ")
    text = _SPACES.sub(" ", text).strip(" .,;:-*")
    if not text:
        return line.strip().lower()
    return text.lower()
