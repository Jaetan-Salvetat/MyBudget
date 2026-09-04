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

TABLES = {
    "examples": (EXAMPLES, lambda row: row[0]),
    "verbes": (VERB_PHRASES, lambda row: row),
    "lexique": (LEXICON, lambda row: row),
    "marques": (SERVICES, lambda row: row.lstrip(RECURRING_MARK).split(ALIAS_SEPARATOR)[0]),
}


def shared(tables: dict) -> dict[str, list[str]]:
    """Les textes que deux classes revendiquent, et où ils sont écrits."""
    slugs: dict[str, set[str]] = collections.defaultdict(set)
    sites: dict[str, set[str]] = collections.defaultdict(set)
    for source, (table, text_of) in tables.items():
        for slug, rows in table.items():
            for row in rows:
                text = normalize(text_of(row))
                slugs[text].add(slug)
                sites[text].add(f"{source}:{slug}")
    return {text: sorted(sites[text]) for text, owners in slugs.items() if len(owners) > 1}


def test_no_text_is_claimed_by_two_classes_within_a_source():
    for name, table in TABLES.items():
        assert shared({name: table}) == {}, name


def test_no_text_is_claimed_by_two_classes_across_sources():
    """`SOURCE_PRIORITY` tranche en silence : les marques battent le lexique.

    « cashback » vivait dans `exceptionnel.interets` côté marques et dans
    `exceptionnel.autre_revenu` côté lexique. Rien n'échouait, et la classe
    neuve perdait son mot au profit de l'ancienne sans qu'aucun compteur bouge.
    """
    assert shared(TABLES) == {}
