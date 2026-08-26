"""Contrat de classes des modèles de lignes.

Partagé par l'inférence, l'entraînement et le diagnostic : un décalage entre
les trois décalerait silencieusement toutes les étiquettes.

Le corpus annoté décrit 14 rôles sur *toutes* les lignes. Les modèles n'en
prédisent pas autant, et les projections autorisées sont ici, une seule fois.

- le classifieur V2 n'étiquette que les lignes porteuses de prix, en 5
  classes (`ROLE_TO_CLASS`) ;
- le tagger de rôles étiquette toutes les lignes, mais en 9 classes
  (`tagger_role`) : **six des quatorze rôles annotés ne sont lus par
  personne**. `structure_roles` lit item, item_label, discount, total,
  subtotal et payment ; `header_ml` lit store et date_line. Distinguer tax,
  change, summary, header, footer et noise n'apporte rien à aucun
  consommateur — et l'annotateur ne peut pas y être cohérent : mesuré sur
  T1-test, **41 % des erreurs du tagger sont des confusions entre ces
  six-là**. Les fondre en une seule classe fait passer l'exactitude par ligne
  de 94,8 % à 96,9 % et les tickets sans aucune erreur de rôle de 51,8 % à
  66,3 %, à données et features identiques.
"""

from annotate.schema import (
    CHANGE,
    DATE_LINE,
    FOOTER,
    HEADER,
    ITEM_LABEL,
    NOISE,
    STORE,
    SUMMARY,
    TAX,
)
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

# Les rôles qu'aucun consommateur ne distingue : ils deviennent tous `NOISE`,
# le fourre-tout que `structure_roles` ignore déjà.
UNREAD_ROLES = (TAX, CHANGE, SUMMARY, HEADER, FOOTER, NOISE)

# L'ordre est le contrat : le modèle rend un indice, cette liste le nomme.
# `pipeline/lib/src/role_tagger.dart` porte la même, et la vérifie au
# chargement.
TAGGER_ROLES = (
    STORE,
    DATE_LINE,
    ROLE_ITEM,
    ITEM_LABEL,
    ROLE_DISCOUNT,
    ROLE_SUBTOTAL,
    ROLE_TOTAL,
    ROLE_PAYMENT,
    NOISE,
)


def tagger_role(role: str) -> str:
    """Le rôle annoté, ramené à ce que le tagger prédit."""
    return NOISE if role in UNREAD_ROLES else role
