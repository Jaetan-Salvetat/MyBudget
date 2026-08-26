"""Le filtre qui décide si une annotation entre dans le corpus d'entraînement.

L'annotation vient d'un modèle : elle est plausible, jamais garantie. Deux
contrôles indépendants la trient — aucun montant qui ne soit lisible sur sa
ligne, et une somme d'articles qui retombe sur la référence imprimée.

Le verdict est typé : c'est lui qui décide de l'entrée dans le corpus, et
une cause reconnue à la phrase près se briserait à la première reformulation.
"""

from __future__ import annotations

from annotate.validate import Cause, rejection
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
VALID = [
    {"role": "header"},
    {"role": "item", "amount": 2.50},
    {"role": "item", "amount": 1.20},
    {"role": "discount", "amount": 0.30},
    {"role": "total", "amount": 3.40},
]


def entries_with(**overrides) -> list[dict]:
    entries = [dict(entry) for entry in VALID]
    for index, changes in overrides.items():
        entries[int(index)].update(changes)
    return entries


def test_accepte_une_annotation_dont_la_somme_retombe_sur_le_total() -> None:
    assert rejection(VALID, LINES) is None


def test_rejette_une_somme_qui_ne_retombe_pas() -> None:
    """La remise prise pour un article : tous les montants restent lisibles,
    seul le total trahit le rôle mal attribué."""
    verdict = rejection(entries_with(**{"3": {"role": "item"}}), LINES)
    assert verdict is not None and verdict.cause is Cause.SUM_MISMATCH


def test_rejette_un_montant_absent_de_sa_ligne() -> None:
    """Le seul garde-fou contre une hallucination : le montant annoté doit
    être lisible dans les mots de la ligne."""
    verdict = rejection(entries_with(**{"1": {"amount": 9.99}}), LINES)
    assert verdict is not None and verdict.cause is Cause.UNREADABLE_AMOUNT
    assert "9.99" in verdict.detail


def test_rejette_une_annotation_incomplete() -> None:
    verdict = rejection(VALID[:3], LINES)
    assert verdict is not None and verdict.cause is Cause.MALFORMED


def test_rejette_un_role_inconnu() -> None:
    verdict = rejection(entries_with(**{"0": {"role": "entete"}}), LINES)
    assert verdict is not None and verdict.cause is Cause.MALFORMED


def test_rejette_un_ticket_sans_article() -> None:
    verdict = rejection([{"role": "footer"} for _ in LINES], LINES)
    assert verdict is not None and verdict.cause is Cause.NO_ITEM


def test_accepte_une_remise_portee_par_la_ligne_de_l_article() -> None:
    """L'OCR fusionne deux lignes du ticket : l'article porte sa remise."""
    lines = [line("PAIN 2,50 -0,50"), line("TOTAL 2,00")]
    entries = [
        {"role": "item", "amount": 2.50, "discount": 0.50},
        {"role": "total", "amount": 2.00},
    ]
    assert rejection(entries, lines) is None


def test_le_sous_total_sert_de_reference_sans_total() -> None:
    lines = [line("PAIN 2,50"), line("SUBTOTAL 2,50")]
    entries = [
        {"role": "item", "amount": 2.50},
        {"role": "subtotal", "amount": 2.50},
    ]
    assert rejection(entries, lines) is None


def test_rejette_un_ticket_sans_reference() -> None:
    lines = [line("PAIN 2,50"), line("MERCI")]
    entries = [{"role": "item", "amount": 2.50}, {"role": "footer"}]
    verdict = rejection(entries, lines)
    assert verdict is not None and verdict.cause is Cause.NO_REFERENCE


def test_accepte_un_montant_soude_par_l_ocr() -> None:
    """« 19 » et « 1,08 » collés en « 1911,08 » : le montant reste lisible."""
    lines = [line("APTA VINAIGRE 1911,08 EUR"), line("TOTAL 1,08")]
    entries = [{"role": "item", "amount": 1.08}, {"role": "total", "amount": 1.08}]
    assert rejection(entries, lines) is None


def test_accepte_un_prix_dont_l_ocr_a_perdu_le_separateur() -> None:
    lines = [line("DC-VIENNOISERIE LS I 1 57 EUR A"), line("TOTAL 1,57")]
    entries = [{"role": "item", "amount": 1.57}, {"role": "total", "amount": 1.57}]
    assert rejection(entries, lines) is None


def test_la_somme_peut_retomber_sur_le_sous_total_hors_taxe() -> None:
    """Ticket américain : le total inclut la taxe, les articles non."""
    lines = [line("BURGER 20,95"), line("SUBTOTAL 20,95"), line("TOTAL 22,50")]
    entries = [
        {"role": "item", "amount": 20.95},
        {"role": "subtotal", "amount": 20.95},
        {"role": "total", "amount": 22.50},
    ]
    assert rejection(entries, lines) is None


def test_le_verdict_se_lit_en_clair() -> None:
    """Les compteurs de `annotate.run` affichent la cause : elle doit rester
    lisible sans que personne ne s'appuie dessus pour décider."""
    verdict = rejection(entries_with(**{"3": {"role": "item"}}), LINES)
    assert str(verdict).startswith(str(Cause.SUM_MISMATCH))
