"""Fusionne les sources en une base d'entités unique et sans contradiction.

Deux sources qui donnent deux classes au même nom sont un conflit : il est
tranché par priorité de source, jamais silencieusement par l'ordre d'itération.
Les ambiguïtés réelles — « Casino » l'enseigne contre « casino » le jeu — sont
arbitrées à la main dans OVERRIDES, qui impose la classe sans jamais faire
disparaître le nom : un arbitrage qui supprime « Apple » de la base coûte plus
cher que l'ambiguïté qu'il résout.
"""

import sys
from collections import Counter

from knowledge.entities import Entity, is_latin, normalize, write_entities
from knowledge.sources import lexicon, nsi, openfoodfacts, patterns, services, wikidata
from paths import ENTITIES_PATH

MIN_NAME_LENGTH = 2

SOURCE_PRIORITY: dict[str, int] = {
    services.SOURCE: 5,
    lexicon.SOURCE: 4,
    nsi.SOURCE: 3,
    wikidata.SOURCE: 2,
    openfoodfacts.SOURCE: 1,
    patterns.SOURCE: 1,
}

OVERRIDES: dict[str, str] = {
    "casino": "alimentation.supermarche",
    "match": "alimentation.supermarche",
    "monoprix": "alimentation.supermarche",
    "franprix": "alimentation.supermarche",
    "orange": "numerique.telecom",
    "free": "numerique.telecom",
    "sky": "loisirs.streaming",
    "total": "transport.essence",
    "totalenergies": "transport.essence",
    "shell": "transport.essence",
    "bp": "transport.essence",
    "esso": "transport.essence",
    "avia": "transport.essence",
    "amazon": "shopping.electronique",
    "apple": "shopping.electronique",
    "samsung": "shopping.electronique",
    "google": "numerique.logiciel_service",
    "microsoft": "numerique.logiciel_service",
    "sephora": "sante_beaute.esthetique",
    "fnac": "loisirs.livre_presse",
    "cultura": "loisirs.livre_presse",
    "the sun": "loisirs.livre_presse",
    "action": "shopping.mobilier_deco",
    "sncf": "voyage.transport_longue_distance",
    "uber": "transport.taxi_vtc",
    "lime": "transport.transport_commun",
    "max": "loisirs.streaming",
    "prime": "salaire.prime",
    "bourse": "aide_allocation.bourse",
    "pension": "salaire.retraite",
    "commission": "salaire.prime",
    "deposit": "logement.loyer",
    "service": "transport.entretien_vehicule",
    "spa": "sante_beaute.esthetique",
    "gym": "loisirs.sport",
    "toll": "transport.peage",
    "booking": "voyage.hebergement",
    "bolt": "transport.taxi_vtc",
    "lyft": "transport.taxi_vtc",
    "zalando": "shopping.vetements",
    "wetherspoons": "restauration.bar",
    "baguette": "alimentation.boulangerie",
    "pain": "alimentation.boulangerie",
    "bread": "alimentation.boulangerie",
    "loaf": "alimentation.boulangerie",
}


def _rank(entity: Entity) -> tuple[int, int]:
    return SOURCE_PRIORITY.get(entity.source, 0), entity.tier


def _acceptable(entity: Entity) -> bool:
    return len(entity.key) >= MIN_NAME_LENGTH and is_latin(entity.name)


def collect() -> list[Entity]:
    return [
        entity
        for source in (
            services.iter_entities(),
            lexicon.iter_entities(),
            nsi.iter_entities(),
            wikidata.iter_entities(),
            openfoodfacts.iter_entities(),
            patterns.iter_entities(),
        )
        for entity in source
        if _acceptable(entity)
    ]


def merge(entities: list[Entity]) -> tuple[list[Entity], Counter]:
    """Une entité par nom normalisé, la source la plus fiable l'emporte."""
    best: dict[str, Entity] = {}
    conflicts: Counter = Counter()

    for entity in sorted(entities, key=_rank, reverse=True):
        key = entity.key
        slug = OVERRIDES.get(key, entity.slug)

        current = best.get(key)
        if current is None:
            best[key] = Entity(
                name=entity.name,
                slug=slug,
                source=entity.source,
                aliases=list(entity.aliases),
                tier=entity.tier,
                recurrence=entity.recurrence,
                countries=list(entity.countries),
            )
            continue

        if current.slug == slug:
            current.aliases.extend(entity.aliases)
            current.tier = max(current.tier, entity.tier)
        else:
            conflicts[f"{current.slug} < {slug}"] += 1

    for entity in best.values():
        entity.aliases = [
            alias
            for alias in dict.fromkeys(entity.aliases)
            if normalize(alias) != entity.key
            and len(normalize(alias)) >= MIN_NAME_LENGTH
            and is_latin(alias)
            and OVERRIDES.get(normalize(alias), entity.slug) == entity.slug
        ]
    return list(best.values()), conflicts


def main() -> None:
    raw = collect()
    entities, conflicts = merge(raw)
    total = write_entities(entities, ENTITIES_PATH)

    by_source = Counter(entity.source for entity in entities)
    by_slug = Counter(entity.slug for entity in entities)
    print(f"Entités brutes : {len(raw)}  →  retenues : {total}")
    print("Par source     : " + ", ".join(f"{k}={v}" for k, v in by_source.most_common()))
    print(f"Classes        : {len(by_slug)}")
    print("Plus fournies  : " + ", ".join(f"{k}={v}" for k, v in by_slug.most_common(5)))
    print("Moins fournies : " + ", ".join(f"{k}={v}" for k, v in by_slug.most_common()[-5:]))
    if conflicts:
        print(f"Conflits arbitrés : {sum(conflicts.values())}")
        for pair, count in conflicts.most_common(15):
            print(f"  {count:5d}  {pair}")
    if total == 0:
        sys.exit("Aucune entité produite")


if __name__ == "__main__":
    main()
