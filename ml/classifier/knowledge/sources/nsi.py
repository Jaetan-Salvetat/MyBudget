"""Name Suggestion Index : les enseignes physiques du monde entier (BSD-3)."""

import json
from collections import Counter
from pathlib import Path
from typing import Iterator

from knowledge.cache import fetch
from knowledge.entities import TIER_HEAD, TIER_KNOWN, Entity
from knowledge.mapping_nsi import IGNORED_PREFIXES, OSM_PATH_TO_SLUG

NSI_URL = "https://cdn.jsdelivr.net/npm/name-suggestion-index@latest/dist/nsi.json"
NSI_FILE = "nsi.json"
SOURCE = "nsi"
BRAND_PREFIX = "brands/"

TARGET_MARKETS = frozenset({"fr", "gb", "us", "ca", "ie", "au", "nz", "be", "ch", "001"})
NAME_TAGS = ("name", "name:fr", "name:en", "brand", "brand:fr", "brand:en", "alt_name")


def _countries(item: dict) -> list[str]:
    included = item.get("locationSet", {}).get("include", [])
    return sorted({value.lower() for value in included if isinstance(value, str)})


def _names(item: dict) -> tuple[str, list[str]]:
    tags = item.get("tags", {})
    canonical_name = item.get("displayName") or tags.get("name") or tags.get("brand")
    aliases = [tags[tag] for tag in NAME_TAGS if tags.get(tag)]
    aliases += item.get("matchNames", [])
    return canonical_name, aliases


def load(refresh: bool = False) -> tuple[list[Entity], Counter]:
    """Retourne les enseignes exploitables et le compte des chemins ignorés."""
    path: Path = fetch(NSI_URL, NSI_FILE, refresh)
    index = json.loads(path.read_text(encoding="utf-8"))["nsi"]

    entities: list[Entity] = []
    skipped: Counter = Counter()
    for full_path, body in index.items():
        if full_path.startswith(IGNORED_PREFIXES):
            continue
        if not full_path.startswith(BRAND_PREFIX):
            continue
        osm_path = full_path[len(BRAND_PREFIX) :]
        slug = OSM_PATH_TO_SLUG.get(osm_path)
        if slug is None:
            skipped[osm_path] += len(body["items"])
            continue

        for item in body["items"]:
            name, aliases = _names(item)
            if not name:
                continue
            countries = _countries(item)
            tier = TIER_HEAD if TARGET_MARKETS.intersection(countries) else TIER_KNOWN
            entities.append(
                Entity(
                    name=name,
                    slug=slug,
                    source=SOURCE,
                    aliases=aliases,
                    tier=tier,
                    countries=countries,
                )
            )
    return entities, skipped


def iter_entities(refresh: bool = False) -> Iterator[Entity]:
    yield from load(refresh)[0]
