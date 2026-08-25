"""Construit le ground truth articles/prix depuis les transcriptions FindIt.

Les transcriptions sont du texte parfait ligne par ligne : on fabrique une
géométrie plausible (libellé à gauche, prix à droite) et on passe par la même
structuration que les images. Le texte étant propre, l'extraction y est
fiable ; elle sert de référence article par article pour scorer l'extraction
depuis les images.
"""

from __future__ import annotations

from pathlib import Path

from reference.lines import PhysicalLine, Word
from reference.structure import ExtractedReceipt, extract

LINE_HEIGHT = 30.0
CHAR_WIDTH = 14.0
LINE_GAP = 8.0
RIGHT_COLUMN = 52

from reference.structure import parse_price


def _line_from_text(text: str, row: int) -> PhysicalLine:
    """Les transcriptions ont perdu l'alignement colonne des tickets : on
    replace le dernier token prix au bord droit, comme à l'impression, sinon
    le filtre de colonne rejette les prix des lignes courtes."""
    tokens = [token for token in text.split(" ") if token]
    price_index = None
    for index in range(len(tokens) - 1, -1, -1):
        if parse_price(tokens[index]) is not None:
            price_index = index
            break

    words: list[Word] = []
    top = row * (LINE_HEIGHT + LINE_GAP)
    column = 0
    for index, token in enumerate(tokens):
        if price_index is not None and index == price_index:
            column = max(column, RIGHT_COLUMN - len(token))
        left = column * CHAR_WIDTH
        words.append(
            Word(
                text=token,
                left=left,
                top=top,
                right=left + len(token) * CHAR_WIDTH,
                bottom=top + LINE_HEIGHT,
                confidence=1.0,
            )
        )
        column += len(token) + 1
    return PhysicalLine(words=words)


def extract_from_transcript(path: Path) -> ExtractedReceipt:
    rows = [
        line
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines()
        if line.strip()
    ]
    lines = [
        _line_from_text(text, row) for row, text in enumerate(rows)
    ]
    lines = [line for line in lines if line.words]
    return extract(lines)
