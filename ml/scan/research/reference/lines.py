"""Reconstruit les lignes physiques d'un ticket depuis la sortie ML Kit.

ML Kit regroupe le texte en blocs/lignes selon sa propre logique de paragraphe,
qui casse les colonnes des tickets (libellé à gauche, prix à droite). On repart
des éléments (mots) et on re-clusterise par recouvrement vertical des boîtes.
"""

from __future__ import annotations

import json
import math
from dataclasses import dataclass
from pathlib import Path

MIN_VERTICAL_OVERLAP_RATIO = 0.4


@dataclass(frozen=True)
class Word:
    text: str
    left: float
    top: float
    right: float
    bottom: float
    confidence: float | None

    @property
    def center_y(self) -> float:
        return (self.top + self.bottom) / 2

    @property
    def height(self) -> float:
        return self.bottom - self.top


@dataclass(frozen=True)
class PhysicalLine:
    words: list[Word]

    @property
    def text(self) -> str:
        return " ".join(word.text for word in self.words)

    @property
    def top(self) -> float:
        return min(word.top for word in self.words)

    @property
    def bottom(self) -> float:
        return max(word.bottom for word in self.words)

    @property
    def min_confidence(self) -> float | None:
        scores = [w.confidence for w in self.words if w.confidence is not None]
        return min(scores) if scores else None


def load_words(result_path: Path) -> tuple[list[Word], dict]:
    data = json.loads(result_path.read_text())
    words: list[Word] = []
    for block in data["blocks"]:
        for line in block["lines"]:
            for element in line["elements"]:
                left, top, right, bottom = element["box"]
                words.append(
                    Word(
                        text=element["text"],
                        left=left,
                        top=top,
                        right=right,
                        bottom=bottom,
                        confidence=element.get("confidence"),
                    )
                )
    return words, data


def median_angle(data: dict) -> float:
    """Angle dominant du texte en degrés, tel que mesuré par ML Kit ligne par
    ligne. Zéro quand aucun angle n'est disponible (iOS)."""
    angles = [
        line["angle"]
        for block in data["blocks"]
        for line in block["lines"]
        if line.get("angle") is not None
    ]
    if not angles:
        return 0.0
    angles.sort()
    return angles[len(angles) // 2]


def deskew_words(words: list[Word], angle_degrees: float) -> list[Word]:
    """Tourne les boîtes de -angle autour de l'origine pour ramener les lignes
    à l'horizontale avant le clustering. Sans ça, une photo inclinée de 4°
    décale la colonne des prix d'une ligne et demie en haut du ticket."""
    if abs(angle_degrees) < 0.2:
        return words
    radians = math.radians(-angle_degrees)
    cos, sin = math.cos(radians), math.sin(radians)

    def rotate(x: float, y: float) -> tuple[float, float]:
        return x * cos - y * sin, x * sin + y * cos

    deskewed: list[Word] = []
    for word in words:
        center_x, center_y = rotate(
            (word.left + word.right) / 2, (word.top + word.bottom) / 2
        )
        half_width = (word.right - word.left) / 2
        half_height = (word.bottom - word.top) / 2
        deskewed.append(
            Word(
                text=word.text,
                left=center_x - half_width,
                top=center_y - half_height,
                right=center_x + half_width,
                bottom=center_y + half_height,
                confidence=word.confidence,
            )
        )
    return deskewed


def _vertical_overlap_ratio(word: Word, line: PhysicalLine) -> float:
    overlap = min(word.bottom, line.bottom) - max(word.top, line.top)
    if overlap <= 0:
        return 0.0
    return overlap / min(word.height, line.bottom - line.top)


def cluster_lines(words: list[Word]) -> list[PhysicalLine]:
    ordered = sorted(words, key=lambda w: w.center_y)
    lines: list[list[Word]] = []
    for word in ordered:
        placed = False
        for line_words in lines:
            line = PhysicalLine(words=line_words)
            if _vertical_overlap_ratio(word, line) >= MIN_VERTICAL_OVERLAP_RATIO:
                line_words.append(word)
                placed = True
                break
        if not placed:
            lines.append([word])
    result = [
        PhysicalLine(words=sorted(line_words, key=lambda w: w.left))
        for line_words in lines
    ]
    result.sort(key=lambda line: line.top)
    return result
