"""Le format d'un ticket annoté sur disque.

Un seul module écrit et relit ce format. Ce qui s'y trouve doit être ce qui
ne se déduit d'aucune autre source : le texte d'une ligne, la position d'une
entrée et le verdict du filtre se recalculent, donc ils ne sont pas stockés.
"""

from __future__ import annotations

import json

from annotate import record
from reference.lines import PhysicalLine, Word

PROVENANCE = {"model": "google/gemini-3.7-flash", "prompt": "abc123", "date": "2026-08-26"}
LINES = [
    PhysicalLine(words=[
        Word(text="PAIN", left=0, top=0, right=10, bottom=10, confidence=1.0),
        Word(text="2,50", left=20, top=0, right=30, bottom=10, confidence=0.5),
    ]),
    PhysicalLine(words=[
        Word(text="TOTAL", left=0, top=20, right=10, bottom=30, confidence=1.0),
        Word(text="2,50", left=20, top=20, right=30, bottom=30, confidence=1.0),
    ]),
]
ENTRIES = [{"role": "item", "amount": 2.50}, {"role": "total", "amount": 2.50}]


def written(tmp_path, **overrides):
    path = tmp_path / "t.json"
    record.write(path, image="t.jpg", lines=LINES, entries=ENTRIES,
                 store="CARREFOUR", date="2026-08-26",
                 provenance=overrides.get("provenance", PROVENANCE))
    return path


def test_relit_ce_qu_il_a_ecrit(tmp_path) -> None:
    stored = record.read(written(tmp_path))
    assert stored.image == "t.jpg"
    assert [line.text for line in stored.lines] == ["PAIN 2,50", "TOTAL 2,50"]
    assert stored.entries == ENTRIES
    assert stored.store == "CARREFOUR"
    assert stored.date == "2026-08-26"
    assert stored.provenance == PROVENANCE


def test_ne_stocke_pas_ce_qui_se_deduit(tmp_path) -> None:
    """Le texte d'une ligne est la jointure de ses mots, la position d'une
    entrée est son rang, le verdict du filtre se recalcule au chargement."""
    payload = json.loads(written(tmp_path).read_text())
    assert "text" not in payload["lines"][0]
    assert "index" not in payload["annotation"]["lines"][0]
    assert "reason" not in payload
    assert "rotation" not in payload and "source" not in payload


def test_arrondit_le_bruit_de_serialisation(tmp_path) -> None:
    """La confiance vient d'un OCR qui la rend en float32 : la reporter en
    float64 stocke des décimales qui ne veulent rien dire."""
    noisy = [PhysicalLine(words=[
        Word(text="A", left=0.123456, top=0, right=10, bottom=10,
             confidence=0.30000001192092896),
    ])]
    path = tmp_path / "n.json"
    record.write(path, image="n.jpg", lines=noisy, entries=[{"role": "noise"}],
                 store=None, date=None, provenance=PROVENANCE)
    word = json.loads(path.read_text())["lines"][0]["words"][0]
    assert word["confidence"] == 0.3
    assert word["box"][0] == 0.12


def test_une_provenance_differente_rend_le_ticket_perime(tmp_path) -> None:
    """Changer de modèle ou de prompt doit se voir : c'est ce qui permet de
    ré-annoter le périmé sans repayer le corpus entier."""
    stored = record.read(written(tmp_path))
    assert not record.is_stale(stored, PROVENANCE)
    assert record.is_stale(stored, {**PROVENANCE, "prompt": "def456"})
    assert record.is_stale(stored, {**PROVENANCE, "model": "autre/modele"})


def test_la_date_ne_perime_pas_un_ticket(tmp_path) -> None:
    """Seuls le modèle et le prompt décident de ce qu'une annotation vaut."""
    stored = record.read(written(tmp_path))
    assert not record.is_stale(stored, {**PROVENANCE, "date": "2027-01-01"})


def test_un_ticket_sans_ligne_lue_reste_traçable(tmp_path) -> None:
    """L'OCR n'a rien rendu : le fichier existe quand même, sinon la reprise
    réessaie indéfiniment le même ticket illisible."""
    path = tmp_path / "vide.json"
    record.write(path, image="vide.jpg", lines=[], entries=[], store=None,
                 date=None, provenance=PROVENANCE)
    stored = record.read(path)
    assert stored.lines == [] and stored.entries == []
