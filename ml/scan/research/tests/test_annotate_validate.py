"""Le filtre qui décide si une annotation entre dans le corpus d'entraînement.

L'annotation vient d'un modèle : elle est plausible, jamais garantie. Deux
contrôles indépendants la trient — aucun montant qui ne soit lisible sur sa
ligne, et une somme d'articles qui retombe sur la référence imprimée.
"""

from __future__ import annotations

from annotate.validate import rejection_reason
from reference.lines import PhysicalLine, Word


def line(text: str) -> PhysicalLine:
    return PhysicalLine(
        words=[
            Word(text=token, left=0, top=0, right=10, bottom=10, confidence=None)
            for token in text.split()
        ]
    )


LINES = [
    line("CARREFOUR CITY"),
    line("PAIN 2,50"),
    line("LAIT 1,20"),
    line("REMISE -0,30"),
    line("TOTAL A PAYER 3,40"),
]
VALID = {
    "lines": [
        {"index": 0, "role": "header"},
        {"index": 1, "role": "item", "amount": 2.50},
        {"index": 2, "role": "item", "amount": 1.20},
        {"index": 3, "role": "discount", "amount": 0.30},
        {"index": 4, "role": "total", "amount": 3.40},
    ]
}


def annotation_with(**overrides) -> dict:
    entries = [dict(entry) for entry in VALID["lines"]]
    for index, changes in overrides.items():
        entries[int(index)].update(changes)
    return {"lines": entries}


def test_accepte_une_annotation_dont_la_somme_retombe_sur_le_total() -> None:
    assert rejection_reason(VALID, LINES) is None


def test_rejette_une_somme_qui_ne_retombe_pas() -> None:
    assert rejection_reason(annotation_with(**{"2": {"amount": 1.30}}), LINES)


def test_rejette_un_montant_absent_de_sa_ligne() -> None:
    """Le seul garde-fou contre une hallucination : le montant annoté doit
    être lisible dans les mots de la ligne."""
    reason = rejection_reason(annotation_with(**{"1": {"amount": 9.99}}), LINES)
    assert reason is not None and "9.99" in reason


def test_rejette_une_annotation_incomplete() -> None:
    partial = {"lines": VALID["lines"][:3]}
    assert rejection_reason(partial, LINES)


def test_rejette_un_role_inconnu() -> None:
    assert rejection_reason(annotation_with(**{"0": {"role": "entete"}}), LINES)


def test_rejette_un_ticket_sans_article() -> None:
    empty = {
        "lines": [
            {"index": index, "role": "footer"} for index in range(len(LINES))
        ]
    }
    assert rejection_reason(empty, LINES)


def test_accepte_une_remise_portee_par_la_ligne_de_l_article() -> None:
    """L'OCR fusionne deux lignes du ticket : l'article porte sa remise."""
    lines = [line("PAIN 2,50 -0,50"), line("TOTAL 2,00")]
    annotation = {
        "lines": [
            {"index": 0, "role": "item", "amount": 2.50, "discount": 0.50},
            {"index": 1, "role": "total", "amount": 2.00},
        ]
    }
    assert rejection_reason(annotation, lines) is None


def test_le_sous_total_sert_de_reference_sans_total() -> None:
    lines = [line("PAIN 2,50"), line("SUBTOTAL 2,50")]
    annotation = {
        "lines": [
            {"index": 0, "role": "item", "amount": 2.50},
            {"index": 1, "role": "subtotal", "amount": 2.50},
        ]
    }
    assert rejection_reason(annotation, lines) is None


def test_rejette_un_ticket_sans_reference() -> None:
    lines = [line("PAIN 2,50"), line("MERCI")]
    annotation = {
        "lines": [
            {"index": 0, "role": "item", "amount": 2.50},
            {"index": 1, "role": "footer"},
        ]
    }
    assert rejection_reason(annotation, lines)


def test_accepte_un_montant_soude_par_l_ocr() -> None:
    """« 19 » et « 1,08 » collés en « 1911,08 » : le montant reste lisible."""
    lines = [line("APTA VINAIGRE 1911,08 EUR"), line("TOTAL 1,08")]
    annotation = {
        "lines": [
            {"index": 0, "role": "item", "amount": 1.08},
            {"index": 1, "role": "total", "amount": 1.08},
        ]
    }
    assert rejection_reason(annotation, lines) is None


def test_accepte_un_prix_dont_l_ocr_a_perdu_le_separateur() -> None:
    lines = [line("DC-VIENNOISERIE LS I 1 57 EUR A"), line("TOTAL 1,57")]
    annotation = {
        "lines": [
            {"index": 0, "role": "item", "amount": 1.57},
            {"index": 1, "role": "total", "amount": 1.57},
        ]
    }
    assert rejection_reason(annotation, lines) is None


def test_la_somme_peut_retomber_sur_le_sous_total_hors_taxe() -> None:
    """Ticket américain : le total inclut la taxe, les articles non."""
    lines = [line("BURGER 20,95"), line("SUBTOTAL 20,95"), line("TOTAL 22,50")]
    annotation = {
        "lines": [
            {"index": 0, "role": "item", "amount": 20.95},
            {"index": 1, "role": "subtotal", "amount": 20.95},
            {"index": 2, "role": "total", "amount": 22.50},
        ]
    }
    assert rejection_reason(annotation, lines) is None
