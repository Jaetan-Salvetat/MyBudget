"""Chargement du corpus annoté.

Le filtre est rejoué au chargement : rien sur le disque ne dit si un ticket
entre ou non, c'est `validate` qui tranche, sur la version courante de ses
règles.
"""

from __future__ import annotations

import json

import pytest

from annotate.dataset import AnnotatedReceipt, load, role_counts

RECORD = {
    "image": "ticket.jpg",
    "lines": [
        {
            "words": [
                {"text": "PAIN", "box": [0, 0, 10, 10], "confidence": 0.9},
                {"text": "2,50", "box": [20, 0, 30, 10], "confidence": 0.9},
            ]
        },
        {
            "words": [
                {"text": "TOTAL", "box": [0, 20, 10, 30], "confidence": 0.9},
                {"text": "2,50", "box": [20, 20, 30, 30], "confidence": 0.9},
            ]
        },
    ],
    "annotation": {
        "lines": [{"role": "item", "amount": 2.50}, {"role": "total", "amount": 2.50}],
        "store": None,
        "date": None,
    },
    "provenance": {"model": "m", "prompt": "p", "date": "2026-08-26"},
}


def write(root, corpus: str, name: str, record: dict) -> None:
    directory = root / corpus
    directory.mkdir(parents=True, exist_ok=True)
    (directory / name).write_text(json.dumps(record))


def test_charge_les_annotations_acceptees_dans_l_ordre_des_lignes(tmp_path) -> None:
    write(tmp_path, "mixed", "a.json", RECORD)
    [receipt] = load(root=tmp_path)
    assert receipt.roles == ["item", "total"]
    assert receipt.amounts == [2.50, 2.50]


def test_ignore_les_annotations_que_le_filtre_rejette(tmp_path) -> None:
    """Une somme qui ne retombe pas sur le total : le chargeur s'en aperçoit
    seul, sans qu'un verdict ait été écrit à côté."""
    faux = json.loads(json.dumps(RECORD))
    faux["annotation"]["lines"][0]["amount"] = 1.30
    write(tmp_path, "mixed", "a.json", faux)
    assert load(root=tmp_path) == []


def test_separe_le_jeu_reserve_a_l_evaluation(tmp_path) -> None:
    """Les photos téléphone ne doivent jamais servir à entraîner."""
    write(tmp_path, "mixed", "a.json", RECORD)
    write(tmp_path, "photos_pixel", "b.json", RECORD)
    assert [r.corpus for r in load(root=tmp_path)] == ["mixed"]
    assert [r.corpus for r in load(held_out=True, root=tmp_path)] == ["photos_pixel"]


def test_refuse_des_sequences_desynchronisees() -> None:
    with pytest.raises(ValueError, match="longueurs différentes"):
        AnnotatedReceipt(
            "t",
            "c",
            [],
            ["item"],
            [1.0],
            [None],
            [None],
            [None],
            [None],
            [None],
            None,
            None,
        )


def test_charge_le_conditionnement(tmp_path) -> None:
    """Le format sort du nom et devient un champ : c'est ce qui rend la
    frontière du libellé décidable, des deux côtés."""
    record = json.loads(json.dumps(RECORD))
    record["annotation"]["lines"][0] |= {"name": "PAIN", "size": "400G"}
    write(tmp_path, "mixed", "a.json", record)
    receipt = load(root=tmp_path)[0]
    assert receipt.names[0] == "PAIN"
    assert receipt.sizes == ["400G", None]


def test_un_ticket_annote_sans_conditionnement_reste_lisible(tmp_path) -> None:
    """Le corpus déjà annoté n'a pas le champ : il se charge quand même, le
    conditionnement simplement inconnu."""
    write(tmp_path, "mixed", "a.json", RECORD)
    assert load(root=tmp_path)[0].sizes == [None, None]


def test_compte_les_roles(tmp_path) -> None:
    write(tmp_path, "mixed", "a.json", RECORD)
    counts = role_counts(load(root=tmp_path))
    assert counts["item"] == 1 and counts["total"] == 1 and counts["noise"] == 0


def test_charge_la_ligne_du_libelle_rattache(tmp_path) -> None:
    """Le corpus dit quel article porte son libellé ailleurs : c'est la
    vérité du modèle de lien."""
    record = json.loads(json.dumps(RECORD))
    record["lines"].insert(
        0,
        {
            "words": [
                {"text": "PAIN", "box": [0, 0, 10, 10], "confidence": 0.9},
            ]
        },
    )
    record["annotation"]["lines"] = [
        {"role": "item_label"},
        {"role": "item", "amount": 2.50, "label_index": 0},
        {"role": "total", "amount": 2.50},
    ]
    write(tmp_path, "mixed", "a.json", record)
    [receipt] = load(root=tmp_path)
    assert receipt.label_indexes == [None, 0, None]


def test_ignore_un_ticket_sans_ligne_lue(tmp_path) -> None:
    write(
        tmp_path,
        "mixed",
        "a.json",
        {
            "image": "vide.jpg",
            "lines": [],
            "annotation": {"lines": [], "store": None, "date": None},
            "provenance": RECORD["provenance"],
        },
    )
    assert load(root=tmp_path) == []
