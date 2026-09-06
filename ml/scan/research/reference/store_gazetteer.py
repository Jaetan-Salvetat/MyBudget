"""Le répertoire des enseignes, appris de ce que les tickets impriment.

L'enseigne était une pure **sélection de ligne** : le tagger désigne la ligne
la plus probable, et le parsing recopie son texte. Deux échecs en découlent, et
ils représentent 30 des 483 tickets de T1-test — le poste le moins cher à
faire tomber vers 90 % de tickets justes.

- **L'abstention** : sous 0,5 de confiance le modèle ne rend rien, et treize
  tickets n'ont donc aucune enseigne alors que leur logo est lisible.
- **La lecture partielle ou parasite** : `E.Leclerc L`, `ToysMus`,
  `VOTRE AVIS`, `MERCI et` — la ligne recopiée telle quelle, avec ce que
  l'OCR y a laissé.

Or l'enseigne n'est pas un champ libre : c'est un **ensemble quasi fermé**.
Le corpus annoté porte, pour chaque ticket, l'enseigne telle qu'elle est
imprimée — 483 noms distincts sur 4 249 tickets d'entraînement, tête très
lourde. Reconnaître au lieu de recopier répare les deux échecs d'un coup :
un nom connu se retrouve sous l'OCR abîmé, et se rend sous sa forme propre.

Le répertoire ne vient que du jeu d'entraînement (`T1-test` et
`photos_pixel` en sont exclus) : reconnaître une enseigne apprise sur le jeu
d'évaluation ne mesurerait plus rien.

    uv run python -m reference.store_gazetteer   # reconstruit le répertoire
"""

from __future__ import annotations

import json
import re
import unicodedata
from collections import Counter

from annotate.dataset import is_held_out
from paths import ANNOTATIONS_DIR, MODELS_DIR
from reference.structure import levenshtein

GAZETTEER_PATH = MODELS_DIR / "store_gazetteer.json"
HELD_OUT_CORPORA = ("T1-test", "photos_pixel")

# Une entrée courte (`U`, `G20`) ne se cherche pas dans une ligne : elle y
# apparaîtrait partout. Elle doit être la ligne entière.
MIN_CONTAINED_LENGTH = 5

# Une entrée trop longue pour la ligne ne peut pas y tenir ; en deçà, on
# tolère une édition par tranche de caractères — l'OCR d'un logo abîme
# rarement plus.
FUZZY_CHARS_PER_EDIT = 6
FUZZY_MAX_EDITS = 3

# Un nom ambigu doit prouver sa discriminance sur assez de tickets ; en deçà
# de cette part, il annonce autre chose que son enseigne.
MIN_DISCRIMINANT_SUPPORT = 3
MIN_PRECISION = 0.5

NON_ALPHANUMERIC = re.compile(r"[^A-Z0-9 ]+")


def normalize(text: str) -> str:
    folded = unicodedata.normalize("NFKD", text.upper())
    stripped = "".join(c for c in folded if not unicodedata.combining(c))
    return " ".join(NON_ALPHANUMERIC.sub(" ", stripped).split())


def _tolerance(entry: str) -> int:
    return min(len(entry) // FUZZY_CHARS_PER_EDIT, FUZZY_MAX_EDITS)


def _fuzzy_contains(line: str, entry: str) -> bool:
    """L'entrée apparaît dans la ligne à quelques éditions près. La fenêtre
    glisse sur les mots, pas sur les caractères : un logo mal lu perd des
    lettres, il ne se décale pas d'un demi-mot."""
    budget = _tolerance(entry)
    if budget == 0:
        return False
    words = line.split()
    for start in range(len(words)):
        window = ""
        for end in range(start, len(words)):
            window = f"{window} {words[end]}".strip()
            if len(window) > len(entry) + budget:
                break
            if abs(len(window) - len(entry)) <= budget and (
                levenshtein(window, entry) <= budget
            ):
                return True
    return False


class Gazetteer:
    """Les noms d'enseigne connus, du plus long au plus court — la ligne
    « CARREFOUR MARKET » doit rendre l'enseigne complète, pas « CARREFOUR »."""

    def __init__(self, entries: dict[str, str]) -> None:
        self.canonical = entries
        self.keys = sorted(entries, key=len, reverse=True)

    def match(self, text: str) -> str | None:
        line = normalize(text)
        if not line:
            return None
        for key in self.keys:
            if key == line:
                return self.canonical[key]
        for key in self.keys:
            if len(key) >= MIN_CONTAINED_LENGTH and key in line:
                return self.canonical[key]
        for key in self.keys:
            if len(key) >= MIN_CONTAINED_LENGTH and _fuzzy_contains(line, key):
                return self.canonical[key]
        return None


_gazetteer: Gazetteer | None = None


def load() -> Gazetteer:
    global _gazetteer
    if _gazetteer is None:
        _gazetteer = Gazetteer(json.loads(GAZETTEER_PATH.read_text()))
    return _gazetteer


def _training_paths():
    """Les annotations d'entraînement : ni les corpus réservés, ni la tranche
    d'évaluation d'`open_prices` — un répertoire appris sur le jeu qui le juge
    ne mesurerait rien."""
    for corpus in sorted(ANNOTATIONS_DIR.iterdir()):
        if not corpus.is_dir() or corpus.name in HELD_OUT_CORPORA:
            continue
        for path in sorted(corpus.glob("*.json")):
            if not is_held_out(path.stem):
                yield path


TrainingRecord = tuple[str, list[str]]


def _training_records() -> list[tuple[str, list[str]]]:
    """Chaque ticket d'entraînement : l'enseigne annotée telle qu'imprimée et
    ses lignes normalisées."""
    records = []
    for path in _training_paths():
        stored = json.loads(path.read_text())
        store = (stored.get("annotation", {}) or {}).get("store") or ""
        texts = [
            " ".join(word["text"] for word in line["words"])
            for line in stored.get("lines", [])
        ]
        records.append((store.strip(), [normalize(text) for text in texts]))
    return records


def _discriminant(
    entries: dict[str, Counter[str]], receipts: list[tuple[str, list[str]]]
) -> set[str]:
    """Un nom d'enseigne n'entre au répertoire que si le trouver sur une ligne
    annonce vraiment cette enseigne.

    `TOTAL` est une enseigne de station-service — et le mot le plus fréquent
    d'un ticket de caisse. `MARCHE`, `EXPRESS`, `ACCUEIL` ont le même défaut à
    un moindre degré. Aucune liste noire ici : le corpus tranche. Pour chaque
    nom, on compte les tickets d'entraînement dont une ligne le porte, et la
    part d'entre eux dont c'est effectivement l'enseigne. Sous le seuil, le
    nom dit autre chose que l'enseigne, et on le laisse dehors."""
    kept = set()
    for key in entries:
        if len(key) < MIN_CONTAINED_LENGTH:
            kept.add(key)
            continue
        seen = [store for store, texts in receipts if any(key in t for t in texts)]
        if not seen:
            continue
        precision = sum(1 for store in seen if store == key) / len(seen)
        # Un nom qui n'apparaît jamais ailleurs que chez lui n'a rien à
        # prouver de plus, même sur un seul ticket : c'est une boulangerie de
        # quartier, elle ne collisionne avec rien. Le seuil de support ne
        # protège que contre les noms ambigus.
        if precision == 1.0 or (
            len(seen) >= MIN_DISCRIMINANT_SUPPORT and precision >= MIN_PRECISION
        ):
            kept.add(key)
    return kept


def build_from(records: list[TrainingRecord]) -> Gazetteer:
    """Chaque nom normalisé, rendu sous sa graphie la plus fréquente, filtré
    de ceux qui ne distinguent rien."""
    spellings: dict[str, Counter[str]] = {}
    receipts = []
    for store, texts in records:
        key = normalize(store)
        receipts.append((key, texts))
        if key:
            spellings.setdefault(key, Counter())[store] += 1
    kept = _discriminant(spellings, receipts)
    return Gazetteer(
        {
            key: counts.most_common(1)[0][0]
            for key, counts in spellings.items()
            if key in kept and counts
        }
    )


def build() -> Gazetteer:
    return build_from(_training_records())


def main() -> int:
    gazetteer = build()
    GAZETTEER_PATH.parent.mkdir(parents=True, exist_ok=True)
    GAZETTEER_PATH.write_text(
        json.dumps(gazetteer.canonical, ensure_ascii=False, indent=1)
    )
    print(f"{len(gazetteer.canonical)} enseignes → {GAZETTEER_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
