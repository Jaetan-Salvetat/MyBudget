"""Lectures concurrentes d'un ticket, pour arbitrer un golden bancal."""

from __future__ import annotations

from truth.references import receipt_from_annotation


def word(text: str, left: float, top: float) -> dict:
    return {"text": text, "box": [left, top, left + 40, top + 10], "confidence": 1.0}


def line(*words: dict) -> dict:
    return {"text": " ".join(w["text"] for w in words), "words": list(words)}


RECORD = {
    "lines": [
        line(word("PAIN", 0, 0), word("2,50", 100, 0)),
        line(word("REMISE", 0, 20), word("0,50", 100, 20)),
        line(word("POIRES", 0, 40)),
        line(word("0,500", 0, 60), word("2,00", 60, 60), word("1,00", 100, 60)),
        line(word("TOTAL", 0, 80), word("3,00", 100, 80)),
    ],
    "annotation": {
        "lines": [
            {"index": 0, "role": "item", "amount": 2.50},
            {"index": 1, "role": "discount", "amount": 0.50},
            {"index": 2, "role": "item_label", "amount": None},
            {"index": 3, "role": "item", "amount": 1.00, "label_index": 2},
            {"index": 4, "role": "total", "amount": 3.00},
        ]
    },
}


def test_les_lignes_annotees_donnent_un_recu_complet() -> None:
    receipt = receipt_from_annotation(RECORD)
    assert receipt["total"] == 3.00
    assert [(i["name"], i["amount"], i["discount"]) for i in receipt["items"]] == [
        ("PAIN", 2.50, 0.50),
        ("POIRES", 1.00, 0.0),
    ]


def test_la_remise_se_deduit_de_l_article_qui_precede() -> None:
    receipt = receipt_from_annotation(RECORD)
    assert receipt["items"][0]["discount"] == 0.50


def test_le_libelle_vient_de_la_ligne_designee() -> None:
    """Le prix d'une pesée est sur sa propre ligne : le nom est ailleurs, et
    l'annotation dit où."""
    assert receipt_from_annotation(RECORD)["items"][1]["name"] == "POIRES"


def test_un_ticket_sans_annotation_ne_donne_rien() -> None:
    assert receipt_from_annotation({"lines": [], "annotation": None}) is None


def test_une_ligne_sans_montant_lu_n_invente_pas_d_article() -> None:
    record = {
        "lines": [line(word("PAIN", 0, 0))],
        "annotation": {"lines": [{"index": 0, "role": "item", "amount": None}]},
    }
    assert receipt_from_annotation(record)["items"] == []
