"""Deux sources écrites à la main ne peuvent pas donner deux classes au même texte.

Un découpage de taxonomie écrit le vocabulaire de la classe neuve sans retirer
celui de l'ancienne, et rien ne le signale. Le mot part alors dans l'ancienne
classe quand le merge de `knowledge.build` l'arbitre par priorité de source, et
il disparaît quand les deux étiquettes atteignent le corpus, où
`drop_contradictory_texts` retire le texte.

Mesuré sur `run_v7` : « RSA » était dans `aide_allocation.aide_sociale` et
`aide_allocation.allocation_familiale`, « URSSAF » dans `finance.charges_pro` et
`finance.impots_taxes`, « vélo » dans `loisirs.sport` et
`transport.achat_vehicule`. La forme nue de chacun sortait du corpus, et un
cinquième à un quart des lignes restantes tiraient vers l'ancienne classe. Les
trois classes concernées sont les plus basses du rapport par classe.

Le test ne porte que sur ce qui est écrit à la main : entre deux sources
moissonnées, deux classes pour un nom est une ambiguïté du monde, arbitrée par
`SOURCE_PRIORITY`. Ici, c'est toujours un oubli.
"""

import collections

from corpus.quick_add.examples import EXAMPLES
from corpus.quick_add.verbs import VERB_PHRASES
from knowledge.entities import normalize
from knowledge.sources.lexicon import LEXICON
from knowledge.sources.services import SERVICES

RECURRING_MARK = "~"
ALIAS_SEPARATOR = "|"


def owners(table: dict[str, list], text_of) -> dict[str, set[str]]:
    claimed: dict[str, set[str]] = collections.defaultdict(set)
    for slug, rows in table.items():
        for row in rows:
            claimed[normalize(text_of(row))].add(slug)
    return claimed


def shared(table: dict[str, list], text_of=lambda row: row) -> dict[str, set[str]]:
    return {text: slugs for text, slugs in owners(table, text_of).items() if len(slugs) > 1}


def test_no_example_is_claimed_by_two_classes():
    assert shared(EXAMPLES, lambda row: row[0]) == {}


def test_no_verb_phrase_is_claimed_by_two_classes():
    assert shared(VERB_PHRASES) == {}


def test_no_common_noun_is_claimed_by_two_classes():
    assert shared(LEXICON) == {}


def test_no_brand_is_claimed_by_two_classes():
    assert shared(SERVICES, lambda row: row.lstrip(RECURRING_MARK).split(ALIAS_SEPARATOR)[0]) == {}
