"""Contrat de classes du classifieur de lignes.

Partagé par l'inférence, l'entraînement et le diagnostic : un décalage entre
les trois décalerait silencieusement toutes les étiquettes.
"""

ITEM, DISCOUNT, TOTAL, PAYMENT, IGNORE = 0, 1, 2, 3, 4
CLASS_NAMES = ["item", "discount", "total", "payment", "ignore"]
ROLE_TO_CLASS = {
    "item": ITEM,
    "discount": DISCOUNT,
    "total": TOTAL,
    "subtotal": TOTAL,
    "payment": PAYMENT,
}
