"""Fusionne les sources en une base d'entités unique et sans contradiction.

Deux sources qui donnent deux classes au même nom sont un conflit : il est
tranché par priorité de source, jamais silencieusement par l'ordre d'itération.
Les ambiguïtés réelles — « Casino » l'enseigne contre « casino » le jeu — sont
arbitrées à la main dans OVERRIDES, qui impose la classe sans jamais faire
disparaître le nom : un arbitrage qui supprime « Apple » de la base coûte plus
cher que l'ambiguïté qu'il résout.
"""

import sys
from collections import Counter, defaultdict

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
    "casino": "alimentation.courses",
    "match": "alimentation.courses",
    "monoprix": "alimentation.courses",
    "franprix": "alimentation.courses",
    "orange": "numerique.telecom",
    "free": "numerique.telecom",
    "sky": "loisirs.streaming",
    "total": "transport.carburant",
    "totalenergies": "transport.carburant",
    "shell": "transport.carburant",
    "bp": "transport.carburant",
    "esso": "transport.carburant",
    "avia": "transport.carburant",
    "amazon": "shopping.electronique",
    "apple": "shopping.electronique",
    "samsung": "shopping.electronique",
    "google": "numerique.logiciel_service",
    "microsoft": "numerique.logiciel_service",
    "sephora": "sante_beaute.cosmetiques",
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
    "booking": "voyage.sejour",
    "bolt": "transport.taxi_vtc",
    "lyft": "transport.taxi_vtc",
    "zalando": "shopping.vetements",
    "wetherspoons": "restauration.bar",
    "baguette": "alimentation.pain_patisserie",
    "pain": "alimentation.pain_patisserie",
    "bread": "alimentation.pain_patisserie",
    "loaf": "alimentation.pain_patisserie",
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


def _arbitrate_aliases(best: dict[str, Entity]) -> Counter:
    """Un alias ne peut désigner qu'une classe, et jamais voler un nom d'entité.

    « McDonald's PlayPlace » porte l'alias « McDonald's », qui est le nom d'une
    autre entité : sans arbitrage, le corpus sort « mcdonald's » étiqueté
    activités enfants *et* fast-food, et le modèle apprend une contradiction. Le
    nom canonique l'emporte toujours sur l'alias ; entre deux alias, la source
    la plus fiable ; à égalité, personne — une ambiguïté qu'on ne sait pas
    trancher ne s'apprend pas.
    """
    claims: dict[str, list[Entity]] = defaultdict(list)
    for entity in best.values():
        for alias in entity.aliases:
            claims[normalize(alias)].append(entity)

    arbitrated: Counter = Counter()
    for key, claimants in claims.items():
        named = best.get(key)
        slugs = {entity.slug for entity in claimants}
        if named is not None:
            slugs.add(named.slug)
        if len(slugs) == 1:
            continue

        if named is not None:
            winner = named.slug
        else:
            ranked = sorted(claimants, key=_rank, reverse=True)
            winner = ranked[0].slug if _rank(ranked[0]) > _rank(ranked[1]) else None

        for claimant in claimants:
            if claimant.slug == winner:
                continue
            claimant.aliases = [
                alias for alias in claimant.aliases if normalize(alias) != key
            ]
            arbitrated[f"alias {claimant.slug} < {winner or 'ambigu'}"] += 1
    return arbitrated


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
    conflicts.update(_arbitrate_aliases(best))
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
