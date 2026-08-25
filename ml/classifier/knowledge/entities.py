"""Modèle commun à toutes les sources de connaissance."""

import json
import re
import unicodedata
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable, Iterator

from taxonomy import LABELS, ONE_TIME, canonical

_PUNCTUATION = re.compile(r"[^\w\s]", flags=re.UNICODE)
_SPACES = re.compile(r"\s+")

TIER_HEAD = 3
TIER_KNOWN = 2
TIER_TAIL = 1


def is_latin(name: str) -> bool:
    """Un nom en écriture non latine ne sera jamais tapé par un utilisateur FR/EN."""
    letters = [c for c in name if c.isalpha()]
    if not letters:
        return False
    return all("LATIN" in unicodedata.name(c, "") for c in letters)


def normalize(name: str) -> str:
    """Forme comparable d'un nom : minuscules, sans accents ni ponctuation."""
    decomposed = unicodedata.normalize("NFD", name.casefold())
    stripped = "".join(c for c in decomposed if unicodedata.category(c) != "Mn")
    return _SPACES.sub(" ", _PUNCTUATION.sub(" ", stripped)).strip()


@dataclass(slots=True)
class Entity:
    """Un nom que l'utilisateur peut taper, et ce qu'il vaut pour le budget."""

    name: str
    slug: str
    source: str
    aliases: list[str] = field(default_factory=list)
    tier: int = TIER_KNOWN
    recurrence: int = ONE_TIME
    countries: list[str] = field(default_factory=list)

    def __post_init__(self) -> None:
        self.slug = canonical(self.slug)
        if self.slug not in LABELS:
            raise ValueError(f"Slug hors taxonomie : {self.slug} ({self.name})")

    @property
    def key(self) -> str:
        return normalize(self.name)

    @property
    def surfaces(self) -> list[str]:
        """Le nom canonique puis ses alias, sans doublon de forme normalisée."""
        seen: set[str] = set()
        out: list[str] = []
        for candidate in [self.name, *self.aliases]:
            form = normalize(candidate)
            if not form or form in seen:
                continue
            seen.add(form)
            out.append(candidate)
        return out

    def to_json(self) -> dict:
        return {
            "name": self.name,
            "slug": self.slug,
            "source": self.source,
            "aliases": self.aliases,
            "tier": self.tier,
            "recurrence": self.recurrence,
            "countries": self.countries,
        }

    @staticmethod
    def from_json(row: dict) -> "Entity":
        return Entity(
            name=row["name"],
            slug=row["slug"],
            source=row["source"],
            aliases=row.get("aliases", []),
            tier=row.get("tier", TIER_KNOWN),
            recurrence=row.get("recurrence", ONE_TIME),
            countries=row.get("countries", []),
        )


def write_entities(entities: Iterable[Entity], path: Path) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)
    count = 0
    with path.open("w", encoding="utf-8") as handle:
        for entity in entities:
            handle.write(json.dumps(entity.to_json(), ensure_ascii=False) + "\n")
            count += 1
    return count


def read_entities(path: Path) -> Iterator[Entity]:
    with path.open(encoding="utf-8") as handle:
        for line in handle:
            if line.strip():
                yield Entity.from_json(json.loads(line))
