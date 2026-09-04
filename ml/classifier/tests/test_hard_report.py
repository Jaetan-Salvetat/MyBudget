"""La lecture par classe est ce qui rend la cible opposable : elle se teste.

Une moyenne d'ensemble à 88 % peut porter deux classes à 40 %. Le tri et le
seuil qui les font remonter sont la seule logique du rapport, et la seule qui
puisse mentir en silence — un tri par nom au lieu du score, et la pire classe
disparaît en bas d'un tableau de quatre-vingts lignes.
"""

from evaluation.hard import TARGET, classes_below_target, score_by_class
from taxonomy import LABEL_INDEX


def case(slug: str) -> dict:
    return {"category": slug, "type": "expense", "recurrence": "ponctuel", "axis": "abrege"}


def prediction(slug: str) -> dict:
    return {
        "category": LABEL_INDEX[slug],
        "hierarchical": LABEL_INDEX[slug],
        "confidence": 1.0,
        "type": 0,
        "recurrence": 0,
    }


def test_a_class_is_scored_on_its_own_cases():
    """La colonne famille absout une erreur voisine, la colonne stricte non."""
    cases = [case("alimentation.supermarche")] * 4
    predictions = [prediction("alimentation.supermarche")] * 3 + [
        prediction("alimentation.epicerie")
    ]
    assert score_by_class(cases, predictions)["alimentation.supermarche"] == {
        "n": 4,
        "strict": 0.75,
        "family": 1.0,
        "group": 1.0,
        "hierarchical": 0.75,
        "confidence": 1.0,
    }


def test_a_class_is_not_scored_on_another_class_cases():
    cases = [case("alimentation.supermarche"), case("logement.loyer")]
    predictions = [prediction("logement.loyer"), prediction("logement.loyer")]
    scored = score_by_class(cases, predictions)
    assert scored["alimentation.supermarche"]["strict"] == 0.0
    assert scored["logement.loyer"]["strict"] == 1.0


def test_only_the_classes_under_the_target_are_returned():
    scored = {
        "logement.loyer": {"strict": 1.0},
        "divers.don": {"strict": TARGET},
        "salaire.prime": {"strict": TARGET - 0.01},
    }
    assert [slug for slug, _ in classes_below_target(scored)] == ["salaire.prime"]


def test_the_worst_class_comes_first():
    scored = {
        "divers.don": {"strict": 0.5},
        "salaire.prime": {"strict": 0.1},
        "logement.loyer": {"strict": 0.9},
    }
    assert [slug for slug, _ in classes_below_target(scored)] == [
        "salaire.prime",
        "divers.don",
        "logement.loyer",
    ]


def test_classes_tied_on_the_score_are_ordered_by_name():
    scored = {"divers.don": {"strict": 0.4}, "alimentation.marche": {"strict": 0.4}}
    assert [slug for slug, _ in classes_below_target(scored)] == [
        "alimentation.marche",
        "divers.don",
    ]


def test_nothing_is_returned_when_every_class_reaches_the_target():
    assert classes_below_target({"divers.don": {"strict": 1.0}}) == []
