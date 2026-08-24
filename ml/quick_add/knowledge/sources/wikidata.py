"""Wikidata (CC0) : la largeur que les listes écrites à la main n'atteignent pas.

Une classe Wikidata par requête : un échec ou un timeout ne coûte alors qu'une
classe, et le cache disque évite de retaper le service à chaque build.
"""

from typing import Iterator

from knowledge.cache import sparql
from knowledge.entities import TIER_HEAD, TIER_KNOWN, Entity
from knowledge.sources.services import RECURRING_SLUGS
from taxonomy import ONE_TIME, RECURRING

SOURCE = "wikidata"
MAX_WORDS = 5
LIMIT_PER_CLASS = 2500
TARGET_COUNTRIES = frozenset({"Q142", "Q145", "Q30", "Q16", "Q27", "Q408", "Q664", "Q31", "Q39"})

CLASS_TO_SLUG: dict[str, str] = {
    "Q59152282": "loisirs.streaming",
    "Q15590336": "loisirs.musique",
    "Q1110794": "loisirs.livre_presse",
    "Q1137109": "loisirs.jeux_video",
    "Q210167": "loisirs.jeux_video",
    "Q1254596": "numerique.logiciel_service",
    "Q5892272": "numerique.hebergement_domaine",
    "Q1343205": "numerique.stockage_cloud",
    "Q1941618": "numerique.telecom",
    "Q11371": "numerique.telecom",
    "Q1326624": "logement.energie",
    "Q22687": "finance.frais_bancaires",
    "Q2143354": "finance.assurance_habitation",
    "Q46970": "voyage.transport_longue_distance",
    "Q249556": "voyage.transport_longue_distance",
    "Q10438042": "transport.transport_commun",
    "Q19862852": "famille_education.formation",
    "Q664702": "divers.tabac_jeux",
}

QUERY = """
SELECT ?item ?label (GROUP_CONCAT(DISTINCT ?alias; separator="|") AS ?aliases)
       (GROUP_CONCAT(DISTINCT ?country; separator="|") AS ?countries)
WHERE {
  ?item wdt:P31 wd:%(qid)s .
  FILTER NOT EXISTS { ?item wdt:P576 [] }
  ?sitelink schema:about ?item ; schema:isPartOf ?wiki .
  VALUES ?wiki { <https://en.wikipedia.org/> <https://fr.wikipedia.org/> }
  ?item rdfs:label ?label .
  FILTER(LANG(?label) IN ("en", "fr"))
  OPTIONAL { ?item skos:altLabel ?alias . FILTER(LANG(?alias) IN ("en", "fr")) }
  OPTIONAL { ?item wdt:P17 ?countryItem . BIND(STRAFTER(STR(?countryItem), "entity/") AS ?country) }
}
GROUP BY ?item ?label
LIMIT %(limit)d
"""


def _acceptable(name: str) -> bool:
    return bool(name) and len(name.split()) <= MAX_WORDS and not name.startswith("Q")


def iter_entities(refresh: bool = False) -> Iterator[Entity]:
    for qid, slug in CLASS_TO_SLUG.items():
        recurrence = RECURRING if slug in RECURRING_SLUGS else ONE_TIME
        rows = sparql(
            QUERY % {"qid": qid, "limit": LIMIT_PER_CLASS},
            f"wikidata_{qid}.json",
            refresh,
        )
        for row in rows:
            name = row["label"]["value"]
            if not _acceptable(name):
                continue
            raw_aliases = row.get("aliases", {}).get("value", "")
            aliases = [alias for alias in raw_aliases.split("|") if _acceptable(alias)]
            countries = [c for c in row.get("countries", {}).get("value", "").split("|") if c]
            tier = TIER_HEAD if TARGET_COUNTRIES.intersection(countries) else TIER_KNOWN
            yield Entity(
                name=name,
                slug=slug,
                source=SOURCE,
                aliases=aliases,
                tier=tier,
                recurrence=recurrence,
                countries=countries,
            )
