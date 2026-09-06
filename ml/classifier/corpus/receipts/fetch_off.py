"""Extrait des quatre bases Open Food Facts (ODbL) ce que le corpus ticket
consomme : les produits vendus en France, et la table qui relie un code-barres
à ses catégories.

Alimentaire et hygiène-beauté sont publiés en parquet sur Hugging Face. Le dump
pèse 8 Go, mais six colonnes suffisent : DuckDB ne lit à distance que celles
demandées, et il n'y a plus de dump à télécharger, réduire puis effacer.

Produits divers et alimentation animale n'ont pas de parquet : leur seul export
public est le CSV compressé du site, que DuckDB lit aussi bien à distance. Les
deux formes se rejoignent ici sous une même paire de fichiers par base, pour
que rien en aval n'ait à savoir d'où une catégorie est sortie.

La table code-barres → catégories est le maillon qui donne à un libellé de
caisse d'Open Prices une vérité venue du **produit**. C'est ce qui permet à
`corpus/receipts/openprices.py` d'étiqueter un article sans jamais regarder le
magasin où il a été lu.
"""

import sys
import time
from pathlib import Path
from typing import NamedTuple

import duckdb

from paths import CACHE_DIR

HUGGING_FACE = "https://huggingface.co/datasets/openfoodfacts/product-database/resolve/main/"
MAX_PRODUCTS = 250_000

PARQUET_READER = "read_parquet('{source}')"
CSV_READER = (
    "read_csv('{source}', delim='\t', header=true, quote='', "
    "ignore_errors=true, all_varchar=true)"
)

# Le parquet range le nom par langue, le CSV n'en porte qu'un. Le reste des
# colonnes est le même, et les deux requêtes rendent la même table.
PARQUET_PRODUCTS = """
COPY (
  SELECT
    list_filter(product_name, x -> x.lang = 'fr')[1].text AS name,
    brands,
    categories_tags,
    quantity,
    coalesce(unique_scans_n, 0) AS scans
  FROM {reader}
  WHERE list_contains(countries_tags, 'en:france')
    AND len(list_filter(product_name, x -> x.lang = 'fr')) > 0
    AND categories_tags IS NOT NULL
  ORDER BY scans DESC
  LIMIT {limit}
) TO '{target}' (FORMAT PARQUET)
"""

CSV_PRODUCTS = """
COPY (
  SELECT
    product_name AS name,
    brands,
    str_split(categories_tags, ',') AS categories_tags,
    quantity,
    coalesce(try_cast(unique_scans_n AS BIGINT), 0) AS scans
  FROM {reader}
  WHERE contains(countries_tags, 'en:france')
    AND product_name IS NOT NULL AND product_name <> ''
    AND categories_tags IS NOT NULL AND categories_tags <> ''
  ORDER BY scans DESC
  LIMIT {limit}
) TO '{target}' (FORMAT PARQUET)
"""

# Sans filtre pays : un code-barres lu sur un ticket français désigne parfois un
# produit qu'Open Food Facts ne rattache à aucun pays. Le filtrer ici perdrait
# la vérité de l'article pour une raison qui ne le concerne pas.
PARQUET_CODES = """
COPY (
  SELECT code, categories_tags
  FROM {reader}
  WHERE categories_tags IS NOT NULL AND len(categories_tags) > 0
) TO '{target}' (FORMAT PARQUET)
"""

CSV_CODES = """
COPY (
  SELECT code, str_split(categories_tags, ',') AS categories_tags
  FROM {reader}
  WHERE categories_tags IS NOT NULL AND categories_tags <> ''
) TO '{target}' (FORMAT PARQUET)
"""


class Dump(NamedTuple):
    source: str
    reader: str
    products_query: str
    codes_query: str
    products: str
    codes: str


DUMPS = (
    Dump(HUGGING_FACE + "food.parquet", PARQUET_READER, PARQUET_PRODUCTS, PARQUET_CODES,
         "off_products_fr.parquet", "off_codes_food.parquet"),
    Dump(HUGGING_FACE + "beauty.parquet", PARQUET_READER, PARQUET_PRODUCTS, PARQUET_CODES,
         "obf_products_fr.parquet", "off_codes_beauty.parquet"),
    Dump("https://static.openproductsfacts.org/data/en.openproductsfacts.org.products.csv.gz",
         CSV_READER, CSV_PRODUCTS, CSV_CODES,
         "opf_products_fr.parquet", "off_codes_products.parquet"),
    Dump("https://static.openpetfoodfacts.org/data/en.openpetfoodfacts.org.products.csv.gz",
         CSV_READER, CSV_PRODUCTS, CSV_CODES,
         "opff_products_fr.parquet", "off_codes_petfood.parquet"),
)


# Hugging Face limite les requêtes anonymes : une lecture longue se fait
# couper en 429 au milieu. Les reprises sont ce qui rend l'extraction viable
# sans jeton, et l'attente double à chaque essai plutôt que de réinsister.
SESSION = (
    "INSTALL httpfs; LOAD httpfs;",
    "SET http_retries = 10;",
    "SET http_retry_wait_ms = 2000;",
    "SET http_retry_backoff = 2;",
    "SET http_timeout = 300000;",
)


def _extract(query: str, reader: str, source: str, target: Path, **arguments) -> None:
    """Écrit `target`, ou ne l'écrit pas du tout.

    Le fichier n'apparaît qu'une fois complet : une extraction coupée en plein
    vol laisserait sinon un parquet tronqué que la prochaine exécution
    prendrait pour du cache, et le corpus se construirait sur un dixième de la
    base sans que rien ne le signale."""
    if target.exists():
        print(f"{target.name}: déjà en cache")
        return
    connection = duckdb.connect()
    for statement in SESSION:
        connection.execute(statement)
    partial = target.with_suffix(".partial")
    start = time.time()
    try:
        connection.execute(
            query.format(reader=reader.format(source=source), target=partial, **arguments)
        )
        count = connection.execute(f"SELECT count(*) FROM read_parquet('{partial}')").fetchone()[0]
        partial.replace(target)
    finally:
        partial.unlink(missing_ok=True)
    print(f"{target.name}: {count} lignes en {time.time() - start:.0f} s")


def main() -> None:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    for dump in DUMPS:
        _extract(dump.codes_query, dump.reader, dump.source, CACHE_DIR / dump.codes)
        _extract(dump.products_query, dump.reader, dump.source, CACHE_DIR / dump.products,
                 limit=MAX_PRODUCTS)


if __name__ == "__main__":
    sys.exit(main())
