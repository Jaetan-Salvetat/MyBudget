"""Chargement du corpus annoté."""

from __future__ import annotations

import json

import pytest

from annotate.dataset import AnnotatedReceipt, load, role_counts

RECORD = {
    "image": "ticket.jpg",
    "lines": [
        {"text": "PAIN 2,50", "words": [
            {"text": "PAIN", "box": [0, 0, 10, 10], "confidence": 0.9},
            {"text": "2,50", "box": [20, 0, 30, 10], "confidence": 0.9},
        ]},
        {"text": "TOTAL 2,50", "words": [
            {"text": "TOTAL", "box": [0, 20, 10, 30], "confidence": 0.9},
            {"text": "2,50", "box": [20, 20, 30, 30], "confidence": 0.9},
        ]},
    ],
    "annotation": {"lines": [
        {"index": 1, "role": "total", "amount": 2.50},
        {"index": 0, "role": "item", "amount": 2.50},
    ]},
    "reason": None,
}


def write(root, corpus: str, name: str, record: dict) -> None:
    directory = root / corpus
    directory.mkdir(parents=True, exist_ok=True)
    (directory / name).write_text(json.dumps(record))


def test_charge_les_annotations_acceptees_dans_l_ordre_des_lignes(tmp_path) -> None:
    write(tmp_path, "selection_web", "a.json", RECORD)
    [receipt] = load(root=tmp_path)
    assert receipt.roles == ["item", "total"]
    assert receipt.amounts == [2.50, 2.50]


def test_ignore_les_annotations_rejetees(tmp_path) -> None:
    write(tmp_path, "selection_web", "a.json", {**RECORD, "reason": "somme ≠ total"})
    assert load(root=tmp_path) == []


def test_separe_le_jeu_reserve_a_l_evaluation(tmp_path) -> None:
    """Les photos téléphone ne doivent jamais servir à entraîner."""
    write(tmp_path, "selection_web", "a.json", RECORD)
    write(tmp_path, "photos_pixel", "b.json", RECORD)
    assert [r.corpus for r in load(root=tmp_path)] == ["selection_web"]
    assert [r.corpus for r in load(held_out=True, root=tmp_path)] == ["photos_pixel"]


def test_refuse_des_sequences_desynchronisees() -> None:
    with pytest.raises(ValueError, match="longueurs différentes"):
        AnnotatedReceipt("t", "c", [], ["item"], [1.0], [None], [None])


def test_compte_les_roles(tmp_path) -> None:
    write(tmp_path, "selection_web", "a.json", RECORD)
    counts = role_counts(load(root=tmp_path))
    assert counts["item"] == 1 and counts["total"] == 1 and counts["noise"] == 0


def test_charge_la_ligne_du_libelle_rattache(tmp_path) -> None:
    """Le corpus dit quel article porte son libellé ailleurs : c'est la
    vérité du modèle de lien."""
    record = json.loads(json.dumps(RECORD))
    record["lines"].insert(0, {"text": "PAIN DE CAMPAGNE", "words": [
        {"text": "PAIN", "box": [0, 0, 10, 10], "confidence": 0.9},
    ]})
    record["annotation"]["lines"] = [
        {"index": 0, "role": "item_label", "amount": None},
        {"index": 1, "role": "item", "amount": 2.50, "label_index": 0},
        {"index": 2, "role": "total", "amount": 2.50},
    ]
    write(tmp_path, "selection_web", "a.json", record)
    [receipt] = load(root=tmp_path)
    assert receipt.label_indexes == [None, 0, None]
