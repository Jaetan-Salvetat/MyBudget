"""La classe d'un article de ticket, déduite de l'article et de lui seul.

La règle précédente lisait la classe de l'enseigne — un article de chez
Carrefour était « supermarché », le même article chez un traiteur devenait
« épicerie ». Mesuré sur le golden FindIt, cela rendait 10,7 % des lignes
d'entraînement contradictoires : `banane` y portait trois classes, `baguette`
trois aussi. Un modèle ne peut en tirer que la classe majoritaire, et
l'app hérite d'un article dont la catégorie dépend du magasin.

Deux sources ici, dans cet ordre, et l'enseigne n'en fait pas partie :
la surcharge écrite à la main, puis le répertoire des libellés réels
d'Open Prices, dont la vérité vient du code-barres. Un article que ni l'une ni
l'autre ne connaît n'est pas étiqueté : mieux vaut une ligne de moins qu'une
ligne fausse.
"""

from collections.abc import Mapping

from corpus.receipts.labels import EXCLUDED_ITEMS, ITEM_OVERRIDES
from serving.normalize import normalize_receipt_line


def item_label(name: str, labels: Mapping[str, str]) -> str | None:
    """La classe de l'article `name`, ou `None` si rien ne la porte."""
    if name in EXCLUDED_ITEMS:
        return None
    override = ITEM_OVERRIDES.get(name)
    if override is not None:
        return override
    return labels.get(normalize_receipt_line(name))
