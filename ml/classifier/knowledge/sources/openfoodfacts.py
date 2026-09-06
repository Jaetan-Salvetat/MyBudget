"""Open Food Facts et Open Beauty Facts (ODbL) : marques et noms de produits.

Seuls les nœuds proches de la racine sont retenus : « Yaourts » est tapé par un
utilisateur, « Piment doux de Gascogne » jamais. Les feuilles profondes de la
taxonomie n'apporteraient que du bruit dans une classe déjà majoritaire.

Le classement d'une catégorie alimentaire vit dans
`corpus/receipts/categories.py`, partagé avec le corpus ticket : c'est la même
question posée sur la même taxonomie, et deux réponses feraient apprendre au
modèle une contradiction.
"""

from typing import Iterator

from corpus.receipts.categories import food_family
from knowledge.cache import fetch_json
from knowledge.entities import TIER_KNOWN, Entity
from taxonomy import ONE_TIME

SOURCE = "openfoodfacts"
FOOD_CATEGORIES_URL = "https://static.openfoodfacts.org/data/taxonomies/categories.json"
FOOD_BRANDS_URL = "https://static.openfoodfacts.org/data/taxonomies/brands.json"
BEAUTY_CATEGORIES_URL = "https://static.openbeautyfacts.org/data/taxonomies/categories.json"

MAX_DEPTH = 2
MAX_WORDS = 2
LANGUAGES = ("fr", "en")



def _depths(taxonomy: dict) -> dict[str, int]:
    """Profondeur de chaque nœud, la racine valant zéro."""
    depths: dict[str, int] = {}

    def resolve(key: str, seen: frozenset[str]) -> int:
        if key in depths:
            return depths[key]
        parents = taxonomy.get(key, {}).get("parents", [])
        known = [p for p in parents if p in taxonomy and p not in seen]
        depth = 0 if not known else 1 + min(resolve(p, seen | {key}) for p in known)
        depths[key] = depth
        return depth

    for key in taxonomy:
        resolve(key, frozenset())
    return depths


def _acceptable(name: str | None) -> bool:
    return bool(name) and len(name.split()) <= MAX_WORDS and not any(c.isdigit() for c in name)


def _iter_categories(url: str, filename: str, slug_for, refresh: bool) -> Iterator[Entity]:
    taxonomy = fetch_json(url, filename, refresh)
    depths = _depths(taxonomy)
    for key, body in taxonomy.items():
        if depths.get(key, MAX_DEPTH + 1) > MAX_DEPTH:
            continue
        names = body.get("name", {})
        english = names.get("en", "")
        for language in LANGUAGES:
            name = names.get(language)
            if not _acceptable(name):
                continue
            yield Entity(
                name=name,
                slug=slug_for(english, name),
                source=SOURCE,
                tier=TIER_KNOWN,
                recurrence=ONE_TIME,
            )


def iter_entities(refresh: bool = False) -> Iterator[Entity]:
    yield from _iter_categories(
        FOOD_CATEGORIES_URL, "off_categories.json", food_family, refresh
    )
    yield from _iter_categories(
        BEAUTY_CATEGORIES_URL,
        "obf_categories.json",
        lambda *_: "sante_beaute.esthetique",
        refresh,
    )
    brands = fetch_json(FOOD_BRANDS_URL, "off_brands.json", refresh)
    for body in brands.values():
        names = body.get("name", {})
        name = names.get("xx") or names.get("en") or names.get("fr")
        if not _acceptable(name):
            continue
        yield Entity(
            name=name,
            slug="alimentation.courses",
            source=SOURCE,
            tier=TIER_KNOWN,
            recurrence=ONE_TIME,
        )
