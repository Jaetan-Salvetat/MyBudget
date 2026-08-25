"""Contrat d'annotation d'un ticket : le rôle de chaque ligne physique.

Remplace le schéma du classifieur V3 (5 classes, lignes porteuses de prix
uniquement), qui ne pouvait pas exprimer ce qui casse sur le terrain : un
libellé d'article imprimé sur une ligne et son prix sur la suivante, un
récapitulatif de remises confondu avec le total, un pied de ticket pris pour
des articles.

Seuls `ITEM` et `DISCOUNT` contribuent à la somme ; `TOTAL` et `SUBTOTAL`
sont les références du checksum. Tout le reste est explicitement non
contributif — c'est ce que le modèle doit apprendre à écarter.
"""

from __future__ import annotations

ITEM = "item"
ITEM_LABEL = "item_label"
DISCOUNT = "discount"
SUBTOTAL = "subtotal"
TOTAL = "total"
TAX = "tax"
PAYMENT = "payment"
CHANGE = "change"
SUMMARY = "summary"
HEADER = "header"
FOOTER = "footer"
NOISE = "noise"

ROLES = (
    ITEM,
    ITEM_LABEL,
    DISCOUNT,
    SUBTOTAL,
    TOTAL,
    TAX,
    PAYMENT,
    CHANGE,
    SUMMARY,
    HEADER,
    FOOTER,
    NOISE,
)

CONTRIBUTING_ROLES = (ITEM, DISCOUNT)
REFERENCE_ROLES = (TOTAL, SUBTOTAL)
PRICED_ROLES = (ITEM, DISCOUNT, SUBTOTAL, TOTAL, TAX, PAYMENT, CHANGE)

ROLE_DESCRIPTIONS = {
    ITEM: "un article acheté, avec son prix sur cette ligne",
    ITEM_LABEL: "le libellé d'un article dont le prix est sur une autre ligne",
    DISCOUNT: "une remise, ristourne ou avantage qui se déduit d'un article",
    SUBTOTAL: "un sous-total (par rayon, ou hors taxe sur un ticket américain)",
    TOTAL: "le total à payer du ticket, celui que le client règle",
    TAX: "une ligne de la table de TVA (taux, base HT, montant de taxe)",
    PAYMENT: "un moyen de paiement et le montant réglé",
    CHANGE: "la monnaie rendue",
    SUMMARY: "un récapitulatif : nombre d'articles, cumul des remises, points",
    HEADER: "en-tête : enseigne, adresse, téléphone, date, numéro de caisse",
    FOOTER: "pied : mentions légales, fidélité, horaires, remerciements",
    NOISE: "illisible, vide, ou sans rôle dans la lecture du ticket",
}
