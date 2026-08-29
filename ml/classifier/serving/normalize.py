"""Ce que le modèle reçoit vraiment : la forme canonique d'un texte.

Deux entrées, une seule forme. Le scan apporte ce qu'une caisse imprime
(astérisques de tête, codes-barres, contenances, majuscules sans accent), le
quick-add ce qu'un utilisateur tape (casse libre, accents oubliés, ponctuation
collée). Les deux sont ramenés ici à la même écriture — minuscules, sans
accents, ponctuation décollée — avant le tokenizer, à l'entraînement comme à
l'inférence.

Ce que la normalisation traite, le modèle n'a pas à l'apprendre : « father
&son » et « Father & Son » sont la même chaîne avant de l'atteindre, et aucune
capacité n'est dépensée à retenir cette équivalence.

Doit rester portable en Dart à l'identique :
`ml/scan/pipeline/lib/src/normalize.dart`, appliqué par le scan sur chaque
libellé et par `QuickAddClassifierService` sur chaque saisie.
"""

import re
import unicodedata

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

_APOSTROPHES = "’‘‛`´ʼ"
_DASHES = "–—‒―−"
_SPACED_PUNCTUATION = "&+/\\,;:!?()[]{}<>|=\"«»*#~"
_TRANSLATION = str.maketrans(
    {
        **{char: "'" for char in _APOSTROPHES},
        **{char: "-" for char in _DASHES},
        " ": " ",
        " ": " ",
    }
)
_PUNCTUATION = _SPACED_PUNCTUATION + ".'-_@%"
# La classe est écrite en toutes lettres et non `[^\w\s]` : `\w` couvre les
# lettres accentuées chez Python et l'ASCII seul chez Dart, et le miroir
# divergerait sur « ø » ou « æ ».
_REPEATED_PUNCTUATION = re.compile(f"([{re.escape(_PUNCTUATION)}])\\1+")
_SPACE_OUT = re.compile(f"([{re.escape(_SPACED_PUNCTUATION)}])")


# Latin-1, latin étendu A/B, grec, cyrillique, latin étendu additionnel : les
# mêmes plages que `ml/scan/research/tool/generate_accent_fold.py`, qui écrit la
# table du port Dart. Le repli passe par la majuscule parce que la casse n'est
# pas bijective — « ß » y devient « SS » et « ı » « I » — et que Dart n'a pas
# d'équivalent de NFD : c'est cette table, et non NFD, qui fait la parité.
_FOLD_RANGES = ((0x00C0, 0x0250), (0x0370, 0x0530), (0x1E00, 0x1F00))


def _fold_table() -> dict[str, str]:
    table: dict[str, str] = {}
    for start, end in _FOLD_RANGES:
        for code_point in range(start, end):
            char = chr(code_point)
            decomposed = unicodedata.normalize("NFD", char.upper())
            base = "".join(c for c in decomposed if not unicodedata.combining(c))
            if base and base != char:
                table[char] = base
    return table


_FOLD = _fold_table()


# Un texte peut arriver décomposé (macOS et iOS écrivent « café » en NFD) : la
# lettre est alors nue et l'accent la suit en caractère séparé, qu'aucune table
# de précomposés ne peut attraper. Les blocs de diacritiques combinants sont
# donc retirés à part — mêmes plages des deux côtés du miroir.
_COMBINING_RANGES = (
    (0x0300, 0x0370), (0x1AB0, 0x1B00), (0x1DC0, 0x1E00),
    (0x20D0, 0x2100), (0xFE20, 0xFE30),
)


def _is_combining(char: str) -> bool:
    code_point = ord(char)
    return any(start <= code_point < end for start, end in _COMBINING_RANGES)


def fold_accents(text: str) -> str:
    """« crèche » et « creche » sont le même mot : personne n'accentue au clavier."""
    return "".join(
        _FOLD.get(char, char) for char in text if not _is_combining(char)
    )


def normalize_query(text: str) -> str:
    """La forme canonique : minuscules, sans accents, ponctuation décollée."""
    folded = fold_accents(text).lower()
    folded = folded.translate(_TRANSLATION)
    folded = _REPEATED_PUNCTUATION.sub(r"\1", folded)
    folded = _SPACE_OUT.sub(r" \1 ", folded)
    return _SPACES.sub(" ", folded).strip()


def normalize_receipt_line(line: str) -> str:
    """Un libellé de caisse, débarrassé de ce que personne ne tape.

    Rien n'est réécrit, on ne fait que retirer : marqueurs de tête,
    codes-barres, contenances (« 4X125G »), compteurs (« X6 »), codes de rayon.
    """
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
    return normalize_query(text if text else line)
