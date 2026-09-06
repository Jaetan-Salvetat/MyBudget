"""Le jeu élargi aux tickets dont un montant est illisible.

Le checksum protège les montants, pas l'étiquetage : un ticket écarté parce
que l'OCR a soudé un code à son prix garde des rôles exploitables. C'est la
seule cause de rejet qui ouvre cette porte, et elle est reconnue par son
type, jamais par le texte du verdict.
"""

from __future__ import annotations

import json

from annotate.dataset import load

LINES = [
    {"words": [
        {"text": "PAIN", "box": [0, 0, 10, 10], "confidence": 0.9},
        {"text": "2,50", "box": [20, 0, 30, 10], "confidence": 0.9},
    ]},
    {"words": [
        {"text": "LAIT", "box": [0, 20, 10, 30], "confidence": 0.9},
        {"text": "1,20", "box": [20, 20, 30, 30], "confidence": 0.9},
    ]},
    {"words": [
        {"text": "TOTAL", "box": [0, 40, 10, 50], "confidence": 0.9},
        {"text": "3,70", "box": [20, 40, 30, 50], "confidence": 0.9},
    ]},
]
ACCEPTE = [
    {"role": "item", "amount": 2.50},
    {"role": "item", "amount": 1.20},
    {"role": "total", "amount": 3.70},
]
# Le montant n'est lisible nulle part sur sa ligne : hallucination possible
# sur le prix, rôles toujours plausibles.
MONTANT_ILLISIBLE = [
    {"role": "item", "amount": 9.99},
    {"role": "item", "amount": 1.20},
    {"role": "total", "amount": 3.70},
]
# Tous les montants sont lisibles, mais l'un des articles est pris pour du
# bruit : la somme le dit, et ce ticket-là n'apprend plus rien de bon.
SOMME_FAUSSE = [
    {"role": "item", "amount": 2.50},
    {"role": "noise"},
    {"role": "total", "amount": 3.70},
]


def write(root, corpus, name, entries) -> None:
    directory = root / corpus
    directory.mkdir(parents=True, exist_ok=True)
    (directory / name).write_text(json.dumps({
        "image": name.replace(".json", ".jpg"),
        "lines": LINES,
        "annotation": {"lines": entries, "store": None, "date": None},
        "provenance": {"model": "m", "prompt": "p", "date": "2026-08-26"},
    }))


def test_les_montants_illisibles_entrent_seulement_avec_roles_only(tmp_path) -> None:
    write(tmp_path, "mixed", "a.json", ACCEPTE)
    write(tmp_path, "mixed", "b.json", MONTANT_ILLISIBLE)
    assert len(load(root=tmp_path)) == 1
    assert len(load(root=tmp_path, roles_only=True)) == 2


def test_une_somme_fausse_reste_ecartee(tmp_path) -> None:
    """Une somme qui ne tombe pas juste signale un rôle mal attribué : ce
    ticket-là n'apprend rien de bon, même au tagger."""
    write(tmp_path, "mixed", "a.json", SOMME_FAUSSE)
    assert load(root=tmp_path, roles_only=True) == []


def test_le_jeu_d_evaluation_reste_strict(tmp_path) -> None:
    write(tmp_path, "photos_pixel", "a.json", MONTANT_ILLISIBLE)
    assert load(held_out=True, root=tmp_path, roles_only=True) == []
