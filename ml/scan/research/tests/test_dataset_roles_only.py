"""Le jeu élargi aux tickets dont un montant est illisible."""

from __future__ import annotations

import json

from annotate.dataset import load

RECORD = {
    "image": "t.jpg",
    "lines": [
        {"text": "PAIN 2,50", "words": [
            {"text": "PAIN", "box": [0, 0, 10, 10], "confidence": 0.9},
            {"text": "2,50", "box": [20, 0, 30, 10], "confidence": 0.9},
        ]},
    ],
    "annotation": {"lines": [{"index": 0, "role": "item", "amount": 2.50}]},
    "reason": None,
}


def write(root, corpus, name, reason):
    directory = root / corpus
    directory.mkdir(parents=True, exist_ok=True)
    (directory / name).write_text(json.dumps({**RECORD, "reason": reason}))


def test_les_montants_illisibles_entrent_seulement_avec_roles_only(tmp_path) -> None:
    write(tmp_path, "selection_web", "a.json", None)
    write(tmp_path, "selection_web", "b.json", "montant 1.08 illisible ligne 9")
    assert len(load(root=tmp_path)) == 1
    assert len(load(root=tmp_path, roles_only=True)) == 2


def test_une_somme_fausse_reste_ecartee(tmp_path) -> None:
    """Une somme qui ne tombe pas juste signale un rôle mal attribué : ce
    ticket-là n'apprend rien de bon, même au tagger."""
    write(tmp_path, "selection_web", "a.json", "somme 19.99 ≠ référence 38.98")
    assert load(root=tmp_path, roles_only=True) == []


def test_le_jeu_d_evaluation_reste_strict(tmp_path) -> None:
    write(tmp_path, "photos_pixel", "a.json", "montant 1.08 illisible ligne 9")
    assert load(held_out=True, root=tmp_path, roles_only=True) == []
