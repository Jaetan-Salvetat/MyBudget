import torch

from taxonomy import LABELS
from training.hierarchy import (
    CATEGORY_FAMILY,
    FAMILIES,
    decode_within_family,
    family_labels,
    family_logits,
    family_loss,
    family_of,
    membership,
)


def test_every_category_belongs_to_exactly_one_family():
    table = membership()
    assert table.shape == (len(FAMILIES), len(LABELS))
    assert table.sum(dim=0).tolist() == [1] * len(LABELS)


def test_families_follow_the_taxonomy_groups_in_order():
    assert FAMILIES[0] == "alimentation"
    assert FAMILIES[-1] == "exceptionnel"
    assert family_of("transfert.remboursement_ami") == "transfert"
    assert CATEGORY_FAMILY[LABELS.index("salaire.prime")] == FAMILIES.index("salaire")


def test_family_logits_are_the_log_of_the_summed_member_probabilities():
    table = membership()
    logits = torch.randn(3, len(LABELS))
    probabilities = torch.softmax(logits, dim=-1)
    expected = torch.log(probabilities @ table.float().T)
    observed = torch.log_softmax(family_logits(logits, table), dim=-1)
    assert torch.allclose(observed, expected, atol=1e-5)


def test_family_labels_follow_the_category_labels():
    labels = torch.tensor([LABELS.index("logement.eau"), LABELS.index("salaire.retraite")])
    assert family_labels(labels).tolist() == [FAMILIES.index("logement"), FAMILIES.index("salaire")]


def test_family_loss_vanishes_when_all_mass_sits_in_the_right_family():
    table = membership()
    logits = torch.full((1, len(LABELS)), -50.0)
    logits[0, LABELS.index("logement.eau")] = 50.0
    labels = torch.tensor([LABELS.index("logement.energie")])
    assert family_loss(logits, labels, table).item() < 1e-6


def test_family_loss_grows_when_the_mass_leaves_the_family():
    table = membership()
    logits = torch.full((1, len(LABELS)), -50.0)
    logits[0, LABELS.index("shopping.vetements")] = 50.0
    labels = torch.tensor([LABELS.index("logement.energie")])
    assert family_loss(logits, labels, table).item() > 10


def test_decode_within_family_prefers_the_best_member_of_the_best_family():
    table = membership()
    logits = torch.full((1, len(LABELS)), 0.0)
    for slug, value in (
        ("logement.eau", 2.0),
        ("logement.energie", 1.9),
        ("logement.charges", 1.8),
        ("shopping.vetements", 2.1),
    ):
        logits[0, LABELS.index(slug)] = value
    assert logits.argmax(dim=-1).item() == LABELS.index("shopping.vetements")
    assert decode_within_family(logits, table).item() == LABELS.index("logement.eau")
