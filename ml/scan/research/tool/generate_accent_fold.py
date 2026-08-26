"""Génère la table de repli d'accents du pipeline Dart depuis Unicode.

Python déplie les accents avec `unicodedata.normalize("NFD")`, qui couvre tout
le latin étendu ; Dart n'a pas d'équivalent en bibliothèque standard et
travaillait sur une table écrite à la main, forcément incomplète — « Ố »
(vietnamien, U+1ED0) y manquait et faisait diverger les trigrammes hachés
entre la référence et le device.

Compléter la table à la main reviendrait à attendre le prochain caractère
manquant. Elle est donc dérivée d'Unicode, pour toutes les lettres latines
décomposables.

    uv run python -m tool.generate_accent_fold
"""

from __future__ import annotations

import unicodedata

from paths import PIPELINE_DIR

# Latin-1 supplement, latin étendu A/B, latin étendu additionnel : tout ce
# qu'un ticket européen ou une translittération peut porter.
RANGES = ((0x00C0, 0x0250), (0x1E00, 0x1F00))
OUTPUT_PATH = PIPELINE_DIR / "lib" / "src" / "accent_fold.dart"

HEADER = '''/// Repli des lettres accentuées vers leur lettre de base.
///
/// **Généré par `research/tool/generate_accent_fold.py`, ne pas éditer.**
/// La table dérive d'`unicodedata.normalize("NFD")` : c'est elle qui garantit
/// que Dart replie exactement comme la référence Python, y compris sur les
/// caractères que l'OCR sort rarement — une entrée manquante décale les
/// trigrammes hachés et fait décider le device autrement.
library;

const Map<String, String> accentFold = {'''


def folded(char: str) -> str | None:
    decomposed = unicodedata.normalize("NFD", char)
    base = "".join(c for c in decomposed if not unicodedata.combining(c))
    return base if base and base != char else None


def table() -> list[str]:
    rows = []
    for start, end in RANGES:
        for code_point in range(start, end):
            char = chr(code_point)
            if not char.isalpha():
                continue
            base = folded(char)
            if base is not None:
                rows.append(f"  '{char}': '{base}',")
    return rows


def main() -> None:
    rows = table()
    OUTPUT_PATH.write_text("\n".join([HEADER, *rows, "};", ""]))
    print(f"{len(rows)} entrées → {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
