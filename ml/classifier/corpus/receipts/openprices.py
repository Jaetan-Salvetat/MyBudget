"""Open Prices (ODbL) : des libellés de caisse réels, et la vérité du produit.

`product_name` n'y est pas le nom canonique du produit mais **le libellé tel
qu'il est imprimé** : le contributeur qui photographie son ticket, son
étiquette de rayon ou son historique de carte le recopie ligne à ligne. Un même
code-barres y porte jusqu'à trente-neuf écritures — `446ML LENTILLES BIO CRF`,
`LENTILLES BIO CRF`, `LENTILLES` — c'est-à-dire la morphologie que
`style.py` fabriquait à la main, avec ses abréviations, ses troncatures, ses
marques distributeur et ses fautes de saisie.

La vérité, elle, vient du **produit** : le code-barres donne les catégories
Open Food Facts, la même table qui étiquette déjà le corpus produit. Un libellé
lu sur un ticket de restaurant ne devient donc pas « restaurant » parce qu'il a
été lu là — c'est toute la différence avec la vérité recopiée de l'enseigne.

Le répertoire des codes-barres est celui des quatre bases réunies : un paquet de
croquettes, un liquide vaisselle ou un magazine n'est dans aucune des deux
premières, et son libellé sortait du corpus faute de vérité.
"""

from collections import defaultdict
from collections.abc import Mapping
from pathlib import Path

import duckdb

from corpus.receipts.categories import beauty_slug, food_slug, petfood_slug, products_slug
from paths import CACHE_DIR, OPEN_PRICES_PATH
from serving.normalize import normalize_receipt_line

COUNTRY = "FR"
CODES_PATHS = {
    "food": CACHE_DIR / "off_codes_food.parquet",
    "beauty": CACHE_DIR / "off_codes_beauty.parquet",
    "products": CACHE_DIR / "off_codes_products.parquet",
    "petfood": CACHE_DIR / "off_codes_petfood.parquet",
}

QUERY = """
SELECT
  prices.product_name AS label,
  coalesce(prices.product_code, prices.category_tag) AS key,
  prices.category_tag AS category_tag,
  food.categories_tags AS food_tags,
  beauty.categories_tags AS beauty_tags,
  products.categories_tags AS products_tags,
  petfood.categories_tags AS petfood_tags
FROM read_parquet('{prices}') AS prices
LEFT JOIN read_parquet('{food}') AS food ON food.code = prices.product_code
LEFT JOIN read_parquet('{beauty}') AS beauty ON beauty.code = prices.product_code
LEFT JOIN read_parquet('{products}') AS products ON products.code = prices.product_code
LEFT JOIN read_parquet('{petfood}') AS petfood ON petfood.code = prices.product_code
WHERE prices.location_osm_address_country_code = '{country}'
  AND prices.product_name IS NOT NULL
  AND prices.product_name <> ''
"""


def product_slug(
    food_tags: list[str] | None,
    beauty_tags: list[str] | None,
    category_tag: str | None,
    products_tags: list[str] | None = None,
    petfood_tags: list[str] | None = None,
) -> str | None:
    """La classe d'un article, lue de son produit et de lui seul.

    Les bases spécialisées passent avant l'alimentaire : un produit présent
    dans deux d'entre elles est d'abord un cosmétique, une croquette ou un
    produit d'entretien, l'inverse le rangerait au rayon courses. Faute de
    code-barres, le `category_tag` d'Open Prices — posé par le contributeur sur
    les produits en vrac — porte la même taxonomie qu'Open Food Facts.
    """
    if beauty_tags:
        return beauty_slug(beauty_tags)
    if petfood_tags:
        return petfood_slug(petfood_tags)
    if products_tags:
        return products_slug(products_tags)
    if food_tags:
        return food_slug(food_tags)
    if category_tag:
        return food_slug([category_tag])
    return None


def read_lines(prices: Path, codes: Mapping[str, Path]) -> list[tuple[str, str, str]]:
    """(clé produit, libellé normalisé, classe) pour chaque libellé français.

    La clé est le code-barres : elle tient ensemble toutes les écritures d'un
    même produit, pour que la coupe train/eval ne mette pas `LENTILLES` d'un
    côté et `446ML LENTILLES BIO CRF` de l'autre.
    """
    for path in (prices, *codes.values()):
        if not path.exists():
            raise FileNotFoundError(f"{path} absent : lancer d'abord `python -m corpus.receipts.fetch_off`")
    connection = duckdb.connect()
    rows = connection.execute(
        QUERY.format(prices=prices, country=COUNTRY, **codes)
    ).fetchall()
    lines: list[tuple[str, str, str]] = []
    for label, key, category_tag, food_tags, beauty_tags, products_tags, petfood_tags in rows:
        slug = product_slug(
            list(food_tags) if food_tags else None,
            list(beauty_tags) if beauty_tags else None,
            category_tag,
            list(products_tags) if products_tags else None,
            list(petfood_tags) if petfood_tags else None,
        )
        text = normalize_receipt_line(label)
        if slug is not None and text:
            lines.append((key, text, slug))
    return lines


def label_table(lines: list[tuple[str, str, str]]) -> dict[str, str]:
    """Libellé normalisé → classe, pour les seuls libellés qui n'en portent qu'une.

    Un libellé que deux produits classent différemment (`CROQUETTES`, animalerie
    ici et rayon courses là) n'est pas une vérité : le garder rendrait au corpus
    la contradiction qu'on vient d'en retirer.
    """
    classes: dict[str, set[str]] = defaultdict(set)
    for _key, text, slug in lines:
        classes[text].add(slug)
    return {text: next(iter(slugs)) for text, slugs in classes.items() if len(slugs) == 1}


def labels() -> dict[str, str]:
    """Le répertoire des libellés réels, aux emplacements du projet."""
    return label_table(read_lines(OPEN_PRICES_PATH, CODES_PATHS))
