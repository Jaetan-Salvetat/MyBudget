import random

import pytest

from corpus.quick_add.build import (
    CLASS_SAMPLE_CAP,
    CLASS_SAMPLE_FLOOR,
    _samples_for_class,
    _split_entities,
    _surface_forms,
)
from knowledge.build import OVERRIDES, SOURCE_PRIORITY, merge
from knowledge.entities import TIER_HEAD, TIER_KNOWN, Entity, normalize
from knowledge.mapping_nsi import OSM_PATH_TO_SLUG
from knowledge.sources import lexicon, patterns, services
from serving.normalize import normalize_query
from taxonomy import (
    ACTIVE_LABELS,
    DEPRECATED,
    LABELS,
    NUM_EXPENSE,
    ONE_TIME,
    RECURRING,
    canonical,
    type_of,
)


def test_labels_are_unique_and_ordered():
    assert len(LABELS) == len(set(LABELS))
    assert 0 < NUM_EXPENSE < len(LABELS)


def test_deprecated_slugs_resolve_to_an_active_slug():
    for slug, replacement in DEPRECATED.items():
        assert canonical(slug) == replacement
        assert replacement in ACTIVE_LABELS


def test_type_follows_the_taxonomy_sections():
    assert type_of(LABELS[0]) == 0
    assert type_of(LABELS[NUM_EXPENSE]) == 1


def test_nsi_mapping_only_targets_known_slugs():
    for path, slug in OSM_PATH_TO_SLUG.items():
        assert canonical(slug) in LABELS, path


def test_overrides_only_target_known_slugs():
    for name, slug in OVERRIDES.items():
        assert slug in LABELS, name
        assert normalize(name) == name, name


def test_every_active_slug_has_hand_written_vocabulary():
    covered = {entity.slug for entity in lexicon.iter_entities()}
    assert set(ACTIVE_LABELS) - covered == set()


def test_curated_sources_produce_usable_names():
    for source in (services.iter_entities(), lexicon.iter_entities(), patterns.iter_entities()):
        for entity in source:
            assert entity.name.strip() == entity.name
            assert entity.key
            assert entity.slug in LABELS


def test_normalize_strips_case_accents_and_punctuation():
    assert normalize("Café  Crème !") == "cafe creme"
    assert normalize("E.Leclerc") == "e leclerc"


def test_entity_rejects_a_slug_outside_the_taxonomy():
    with pytest.raises(ValueError):
        Entity(name="x", slug="pas.une.classe", source="test")


def test_entity_resolves_a_deprecated_slug():
    for slug, replacement in DEPRECATED.items():
        assert Entity(name="x", slug=slug, source="test").slug == replacement


def test_surfaces_drop_duplicate_forms():
    entity = Entity(name="Free", slug="numerique.telecom", source="test", aliases=["free", "Free Mobile"])
    assert entity.surfaces == ["Free", "Free Mobile"]


def test_merge_keeps_the_most_reliable_source():
    low = Entity(name="Picard", slug="divers.autre", source="openfoodfacts")
    high = Entity(name="picard", slug="alimentation.courses", source="services")
    merged, conflicts = merge([low, high])
    assert len(merged) == 1
    assert merged[0].slug == "alimentation.courses"
    assert sum(conflicts.values()) == 1


def test_merge_enforces_overrides_against_any_source():
    wrong = Entity(name="Orange", slug="alimentation.courses", source="services")
    right = Entity(name="Orange", slug="numerique.telecom", source="nsi")
    merged, _ = merge([wrong, right])
    assert [entity.slug for entity in merged] == ["numerique.telecom"]


def test_an_override_never_makes_a_name_disappear():
    """Un arbitrage impose la classe, il ne supprime pas l'entité."""
    other = "divers.autre"
    entities = [
        Entity(name=name, slug=other if slug != other else "divers.don", source="nsi")
        for name, slug in OVERRIDES.items()
    ]
    merged, _ = merge(entities)
    resolved = {entity.key: entity.slug for entity in merged}
    for name, slug in OVERRIDES.items():
        assert resolved.get(name) == slug, name


def test_an_alias_never_steals_the_name_of_another_entity():
    """« McDonald's PlayPlace » porte l'alias « McDonald's », qui est une entité."""
    playground = Entity(
        name="McDonald's PlayPlace",
        slug="famille_education.activites_enfants",
        source="nsi",
        aliases=["McDonald's"],
    )
    restaurant = Entity(name="McDonald's", slug="restauration.fast_food", source="nsi")
    merged, _ = merge([playground, restaurant])
    by_name = {entity.name: entity for entity in merged}
    assert by_name["McDonald's PlayPlace"].aliases == []
    assert by_name["McDonald's"].slug == "restauration.fast_food"


def test_an_alias_claimed_by_two_classes_goes_to_the_most_reliable():
    station = Entity(
        name="Station Service E.Leclerc",
        slug="transport.carburant",
        source="nsi",
        aliases=["leclerc"],
    )
    market = Entity(
        name="E.Leclerc Drive",
        slug="alimentation.courses",
        source="services",
        aliases=["leclerc"],
    )
    merged, _ = merge([station, market])
    owners = {entity.slug for entity in merged if "leclerc" in entity.aliases}
    assert owners == {"alimentation.courses"}


def test_an_ambiguous_alias_is_given_to_nobody():
    """Deux sources de même rang qui se disputent un alias : on ne tranche pas."""
    first = Entity(name="Bistrot A", slug="restauration.bar", source="nsi", aliases=["chez leo"])
    second = Entity(name="Cave B", slug="alimentation.courses", source="nsi", aliases=["chez leo"])
    merged, _ = merge([first, second])
    assert all("chez leo" not in entity.aliases for entity in merged)


def test_merge_unions_aliases_of_the_same_entity():
    first = Entity(name="Netflix", slug="loisirs.streaming", source="services", aliases=["netflix fr"])
    second = Entity(name="netflix", slug="loisirs.streaming", source="nsi", aliases=["Netflix Inc"])
    merged, _ = merge([first, second])
    assert len(merged) == 1
    assert set(merged[0].aliases) == {"netflix fr", "Netflix Inc"}


def test_merge_promotes_the_best_tier():
    tail = Entity(name="Aldi", slug="alimentation.courses", source="nsi", tier=TIER_KNOWN)
    head = Entity(name="aldi", slug="alimentation.courses", source="nsi", tier=TIER_HEAD)
    merged, _ = merge([tail, head])
    assert merged[0].tier == TIER_HEAD


def _fake_entities(count: int, slug: str = "alimentation.courses") -> list[Entity]:
    return [
        Entity(name=f"Enseigne {index}", slug=slug, source="services", tier=TIER_HEAD)
        for index in range(count)
    ]


def test_split_never_lets_a_name_cross_sides():
    entities = _fake_entities(200)
    train, held_out = _split_entities(entities, random.Random(1))
    assert held_out
    assert {entity.key for entity in train}.isdisjoint({entity.key for entity in held_out})
    assert len(train) + len(held_out) == len(entities)


def test_split_keeps_at_least_one_entity_for_training():
    train, held_out = _split_entities(_fake_entities(1), random.Random(1))
    assert len(train) == 1
    assert held_out == []


def test_class_budget_never_exceeds_the_cap():
    rows = _samples_for_class(
        "alimentation.courses",
        _fake_entities(4000),
        random.Random(2),
        CLASS_SAMPLE_CAP,
        CLASS_SAMPLE_FLOOR,
    )
    assert len(rows) == CLASS_SAMPLE_CAP


def test_a_thin_class_is_amplified_beyond_its_entity_count():
    entities = _fake_entities(3, slug="exceptionnel.don_recu")
    rows = _samples_for_class(
        "exceptionnel.don_recu", entities, random.Random(2), CLASS_SAMPLE_CAP, CLASS_SAMPLE_FLOOR
    )
    assert len(rows) >= 10 * len(entities)
    assert len(rows) == len({row["text"] for row in rows})


def test_samples_carry_the_labels_of_their_class():
    rows = _samples_for_class(
        "salaire.salaire_net",
        _fake_entities(20, slug="salaire.salaire_net"),
        random.Random(3),
        CLASS_SAMPLE_CAP,
        0,
    )
    index = LABELS.index("salaire.salaire_net")
    assert rows
    for row in rows:
        assert row["category_label"] == index
        assert row["type_label"] == 1
        assert row["text"].strip() == row["text"]


def test_surface_forms_start_with_the_bare_name():
    entity = Entity(name="Carrefour", slug="alimentation.courses", source="services")
    forms = _surface_forms(entity, 6, random.Random(4))
    assert forms[0] == ("carrefour", ONE_TIME)
    assert len(forms) == len({normalize(text) for text, _ in forms})


def test_surface_forms_are_written_in_the_form_the_app_sends():
    entity = Entity(name="Père & Fils", slug="alimentation.courses", source="services")
    forms = _surface_forms(entity, 20, random.Random(4))
    assert forms[0] == ("pere & fils", ONE_TIME)
    for text, _ in forms:
        assert text == normalize_query(text), text


def test_a_subscription_wording_makes_the_sample_recurring():
    entity = Entity(name="Basic-Fit", slug="loisirs.sport", source="services")
    forms = _surface_forms(entity, 200, random.Random(5))
    marked = [text for text, recurrence in forms if recurrence == RECURRING]
    assert marked
    for text in marked:
        assert any(
            word in text.lower()
            for word in ("abonnement", "abo ", "mensuel", "mensualite", "cotisation",
                         "prelevement", "echeance", "du mois", "les mois", "renouvellement",
                         "forfait", "reconduction", "par mois", "chaque mois", "annuel")
        ), text


# Les utilisateurs de l'app ecrivent en francais : une tournure anglaise dans le
# corpus consomme du budget de classe pour une phrase que personne ne tapera.
ENGLISH_PHRASING = (
    "paid for", "bought", "spent on", "picked up", "ordered", "payment for",
    "purchase", "bill for", "received", "got paid", "earned", "refunded",
    "yesterday", "this morning", "tonight", "last night", "last week", "last month",
    "today", "this weekend", "in january", "in december", "on monday", "on sunday",
    "with friends", "for work", "for the house", "for the kids", "online",
    "in store", "for the month", "takeaway", "with the family",
    "quick ", "cheap ", "on sale", "small ",
    "subscription", "monthly", "membership", "direct debit", "every month",
)


def test_the_generated_phrasing_carries_no_english():
    entity = Entity(name="Carrefour", slug="alimentation.courses", source="services")
    for text, _ in _surface_forms(entity, 400, random.Random(7)):
        lowered = text.lower()
        assert not any(marker in lowered for marker in ENGLISH_PHRASING), text


def test_french_phrasing_offers_enough_variety_to_fill_a_budget():
    entity = Entity(name="Carrefour", slug="alimentation.courses", source="services")
    forms = _surface_forms(entity, 60, random.Random(8))
    assert len(forms) == 60
    assert len({text for text, _ in forms}) == 60


def test_source_priority_covers_every_source():
    used = {services.SOURCE, lexicon.SOURCE, patterns.SOURCE}
    assert used <= set(SOURCE_PRIORITY)
