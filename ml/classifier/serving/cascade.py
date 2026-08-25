"""La décision de catégorie d'un ticket scanné, telle que l'app l'applique.

La taxonomie est une taxonomie de marchands : la classe naturelle d'un
article est celle de son enseigne. Le modèle est donc appelé deux fois —
sur l'en-tête d'enseigne, sur chaque libellé — et les prédictions
d'articles ne servent qu'à deux choses :

1. remplacer l'enseigne quand elle est illisible ou incertaine : la classe
   du ticket devient le vote des articles, pondéré par leur confiance ;
2. sortir un article de la classe du ticket quand il appartient à une
   famille budgétaire distincte (vêtement, animalerie, pharmacie, jouet…)
   avec assez de confiance — et seulement dans une enseigne alimentaire, la
   seule qui vende de tout.

Seuils balayés sur T1-train, vérifiés sur T1-test (`evaluate.py --cascade`).
Portée en Dart à l'identique (`ReceiptCategorizer`).
"""

from collections import defaultdict
from dataclasses import dataclass

STORE_MIN_CONFIDENCE = 0.9
ITEM_OVERRIDE_MIN_CONFIDENCE = 0.8
GENERALIST_PREFIX = "alimentation."

OVERRIDE_FAMILIES = frozenset({
    "shopping.vetements", "shopping.electronique", "shopping.mobilier_deco",
    "divers.animaux", "divers.tabac_jeux", "divers.cadeau_offert",
    "loisirs.livre_presse", "loisirs.musique", "loisirs.jeux_video", "loisirs.sport",
    "sante_beaute.pharmacie", "sante_beaute.esthetique",
    "famille_education.fournitures", "famille_education.activites_enfants",
    "logement.travaux", "transport.essence", "transport.entretien_vehicule",
})


@dataclass(frozen=True)
class Prediction:
    slug: str
    confidence: float


def ticket_category(store: Prediction | None, items: list[Prediction]) -> Prediction:
    """L'enseigne si elle est lisible et sûre, sinon le vote des articles."""
    if store is not None and store.confidence >= STORE_MIN_CONFIDENCE:
        return store
    votes: dict[str, float] = defaultdict(float)
    for item in items:
        votes[item.slug] += item.confidence
    if not votes:
        return store if store is not None else Prediction("divers.autre", 0.0)
    slug, weight = max(votes.items(), key=lambda entry: entry[1])
    return Prediction(slug, weight / len(items))


def item_category(ticket: Prediction, item: Prediction) -> str:
    if (
        ticket.slug.startswith(GENERALIST_PREFIX)
        and item.slug in OVERRIDE_FAMILIES
        and item.confidence >= ITEM_OVERRIDE_MIN_CONFIDENCE
    ):
        return item.slug
    return ticket.slug
