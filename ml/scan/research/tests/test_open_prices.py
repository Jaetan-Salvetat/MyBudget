"""Sélection des tickets français du dump Open Prices.

Le dump liste des *prix*, pas des tickets : chaque ligne porte le prix d'un
produit et les métadonnées de la preuve dont il vient. Regrouper ces lignes
donne le ticket, et une vérité **partielle** — le contributeur saisit ce
qu'il veut, pas forcément tout le ticket. Confondre les prix saisis avec la
liste des articles fabriquerait une fausse vérité terrain.
"""

from __future__ import annotations

import json

from corpus.open_prices import Proof, image_url, proofs_from

CARREFOUR = {
    "proof_id": 1,
    "proof_type": "RECEIPT",
    "proof_file_path": "0297/abc.webp",
    "proof_mimetype": "image/webp",
    "proof_date": "2026-08-19",
    "proof_receipt_price_count": 3,
    "proof_receipt_price_total": 10.0,
    "location_osm_address_country_code": "FR",
    "location_osm_display_name": "Carrefour, 12 Rue X, Paris, France",
    "price": 4.0,
}


def row(**overrides) -> dict:
    return {**CARREFOUR, **overrides}


def test_regroupe_les_prix_par_ticket() -> None:
    [proof] = proofs_from([row(price=4.0), row(price=6.0)])
    assert proof.amounts == [4.0, 6.0]
    assert proof.total == 10.0
    assert proof.store == "Carrefour"


def test_ecarte_ce_qui_n_est_pas_un_ticket_francais() -> None:
    rows = [
        row(proof_id=2, proof_type="PRICE_TAG"),
        row(proof_id=3, location_osm_address_country_code="DE"),
        row(proof_id=4),
    ]
    assert [p.id for p in proofs_from(rows)] == [4]


def test_distingue_les_prix_saisis_du_nombre_declare() -> None:
    """Le contributeur a déclaré 3 articles mais n'en a saisi que 2 : la
    liste des montants est incomplète et doit se dire telle."""
    [proof] = proofs_from([row(price=4.0), row(price=6.0)])
    assert proof.declared_count == 3
    assert len(proof.amounts) == 2
    assert not proof.complete


def test_une_vérité_complete_se_reconnait() -> None:
    rows = [row(price=4.0), row(price=3.0), row(price=3.0)]
    [proof] = proofs_from(rows)
    assert proof.complete


def test_un_ticket_sans_total_declare_reste_utilisable() -> None:
    """L'image sert quand même à l'annotation : c'est le checksum du filtre
    qui tranchera, pas cette vérité-là."""
    [proof] = proofs_from([row(proof_receipt_price_total=None)])
    assert proof.total is None and not proof.complete


def test_convertit_les_decimales_du_dump() -> None:
    """Le Parquet rend des `Decimal`, que `json` refuse de sérialiser."""
    from decimal import Decimal

    [proof] = proofs_from([
        row(price=Decimal("4.00"), proof_receipt_price_total=Decimal("10.00"))
    ])
    assert proof.amounts == [4.0] and proof.total == 10.0
    json.dumps(proof.truth())


def test_l_url_publique_se_deduit_du_chemin() -> None:
    assert image_url("0297/abc.webp").endswith("/img/0297/abc.webp")


def test_la_verite_dit_d_ou_elle_vient() -> None:
    """Les images sont sous licence CC BY-SA : la provenance voyage avec."""
    [proof] = proofs_from([row()])
    truth = proof.truth()
    assert truth["source"] == "open_prices"
    assert truth["licence"] == "CC-BY-SA-4.0"
    assert truth["image_url"] == image_url("0297/abc.webp")
    assert truth["item_count_declared"] == 3


def test_le_nom_de_fichier_porte_l_identifiant(tmp_path) -> None:
    proof = Proof(
        id=42, file_path="0001/x.webp", store=None, date=None, total=None,
        declared_count=None, amounts=[],
    )
    assert proof.name == "op_0000042"
