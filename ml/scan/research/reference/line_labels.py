"""Contrat de classes du classifieur de lignes.

Partagé par l'inférence, l'entraînement et le diagnostic : un décalage entre
les trois décalerait silencieusement toutes les étiquettes.

Le corpus annoté décrit 12 rôles sur *toutes* les lignes ; le classifieur
n'étiquette que les lignes porteuses de prix, en 5 classes. `ROLE_TO_CLASS`
est la seule projection autorisée entre les deux — tout rôle non contributif
tombe dans `IGNORE`.
"""

from annotate.schema import DISCOUNT as ROLE_DISCOUNT
from annotate.schema import ITEM as ROLE_ITEM
from annotate.schema import PAYMENT as ROLE_PAYMENT
from annotate.schema import SUBTOTAL as ROLE_SUBTOTAL
from annotate.schema import TOTAL as ROLE_TOTAL

ITEM, DISCOUNT, TOTAL, PAYMENT, IGNORE = 0, 1, 2, 3, 4
CLASS_NAMES = ["item", "discount", "total", "payment", "ignore"]
ROLE_TO_CLASS = {
    ROLE_ITEM: ITEM,
    ROLE_DISCOUNT: DISCOUNT,
    ROLE_TOTAL: TOTAL,
    ROLE_SUBTOTAL: TOTAL,
    ROLE_PAYMENT: PAYMENT,
}
