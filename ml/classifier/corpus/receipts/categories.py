"""Ce qu'une catégorie Open Food Facts vaut dans notre taxonomie.

Une seule table de correspondance sert les deux entrées du corpus ticket : les
noms de produits moissonnés, et les libellés de caisse d'Open Prices que leur
code-barres relie aux mêmes catégories. Deux copies finiraient par diverger, et
un même produit porterait deux classes selon la porte par laquelle il entre.

La taxonomie est une taxonomie de marchands : la classe d'un produit est celle
du commerce où on l'achète normalement. Le pain va chez le boulanger, les
boissons à l'épicerie, l'alimentation animale à l'animalerie, la cosmétique et
la parapharmacie à leur rayon ; tout le reste est du supermarché.

`knowledge/sources/openfoodfacts.py` moissonne la même taxonomie pour le corpus
quick-add et lit ici la même règle. Deux règles feraient dire au modèle que
`baguette` est boulangerie quand elle vient du quick-add et supermarché quand
elle vient d'un ticket : mesuré sur les corpus livrés, 4,9 % des textes présents
des deux côtés portaient déjà deux classes.
"""

SUPERMARCHE = "alimentation.supermarche"
ANIMAUX = "divers.animaux"
ESTHETIQUE = "sante_beaute.esthetique"
PHARMACIE = "sante_beaute.pharmacie"

PET_TAGS = ("en:pet-food", "en:cat-food", "en:dog-food", "en:pet-", "fr:aliments-pour-animaux")
COSMETIC_TAGS = ("en:makeup", "en:make-up", "en:perfumes", "en:fragrances", "en:nail-polish",
                 "en:nail-makeup", "en:lip-cosmetics", "en:lipsticks", "en:mascaras", "en:eyeshadow",
                 "en:foundations", "en:eau-de-toilette", "en:eau-de-parfum", "en:colognes")
PHARMA_TAGS = ("en:medicines", "en:dietary-supplements", "en:food-supplements", "en:baby-milks",
               "en:infant-formulas", "en:first-aid")
SKIP_TAGS = ("en:non-food-products", "en:open-beauty-facts", "en:open-products-facts")

BOULANGERIE = "alimentation.boulangerie"
EPICERIE = "alimentation.epicerie"

BAKERY_WORDS = frozenset({"bread", "breads", "loaf", "loaves", "bun", "buns", "pastry",
                          "pastries", "cake", "cakes", "cookie", "cookies", "muffin", "muffins",
                          "donut", "donuts", "croissant", "croissants", "baguette", "baguettes",
                          "brioche", "brioches", "viennoiserie", "viennoiseries", "biscuit",
                          "biscuits", "pain", "pains", "gateau", "gateaux", "tarte", "tartes"})
GROCERY_WORDS = frozenset({"beverage", "beverages", "drink", "drinks", "juice", "juices",
                           "water", "waters", "soda", "sodas", "beer", "beers", "wine",
                           "wines", "spirit", "spirits", "coffee", "tea", "teas"})


def food_family(*names: str) -> str:
    """Le commerce d'un produit alimentaire, d'après les mots de sa catégorie."""
    words = {word.lower().strip(",") for name in names for word in name.split()}
    if words & BAKERY_WORDS:
        return BOULANGERIE
    if words & GROCERY_WORDS:
        return EPICERIE
    return SUPERMARCHE


def _words_of(tag: str) -> str:
    """« en:wholemeal-sliced-breads » → « wholemeal sliced breads »."""
    return tag.split(":", 1)[-1].replace("-", " ")


def food_slug(tags: list[str]) -> str | None:
    """La classe d'un produit alimentaire. `None` quand le produit n'en est pas un.

    Seule la catégorie la plus fine est lue : les tags portent toute
    l'ascendance, et `en:plant-based-foods-and-beverages` ferait passer une
    tablette de chocolat pour une boisson."""
    for tag in tags:
        if tag.startswith(PET_TAGS):
            return ANIMAUX
        if tag.startswith(SKIP_TAGS):
            return None
    return food_family(_words_of(tags[-1])) if tags else SUPERMARCHE


def beauty_slug(tags: list[str]) -> str:
    """La classe d'un produit d'hygiène-beauté : cosmétique, parapharmacie, ou rayon."""
    for tag in tags:
        if tag.startswith(COSMETIC_TAGS):
            return ESTHETIQUE
        if tag.startswith(PHARMA_TAGS):
            return PHARMACIE
    return SUPERMARCHE
