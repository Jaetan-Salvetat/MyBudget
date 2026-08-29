"""Extrait d'Open Food Facts et Open Beauty Facts (ODbL) ce que le corpus
ticket consomme : les produits vendus en France, et la table qui relie un
code-barres à ses catégories.

Le dump Hugging Face pèse 8 Go, mais six colonnes suffisent. DuckDB ne lit à
distance que celles demandées : le transfert tombe à une fraction du fichier,
et il n'y a plus de dump à télécharger, réduire puis effacer.

La table code-barres → catégories est le maillon qui donne à un libellé de
caisse d'Open Prices une vérité venue du **produit**. C'est ce qui permet à
`corpus/receipts/openprices.py` d'étiqueter un article sans jamais regarder le
magasin où il a été lu.
"""

import sys
import time
from pathlib import Path

import duckdb

from paths import CACHE_DIR

BASE_URL = "https://huggingface.co/datasets/openfoodfacts/product-database/resolve/main/"
MAX_PRODUCTS = 250_000

PRODUCTS_QUERY = """
COPY (
  SELECT
    list_filter(product_name, x -> x.lang = 'fr')[1].text AS name,
    brands,
    categories_tags,
    quantity,
    coalesce(unique_scans_n, 0) AS scans
  FROM read_parquet('{source}')
  WHERE list_contains(countries_tags, 'en:france')
    AND len(list_filter(product_name, x -> x.lang = 'fr')) > 0
    AND categories_tags IS NOT NULL
  ORDER BY scans DESC
  LIMIT {limit}
) TO '{target}' (FORMAT PARQUET)
"""

# Sans filtre pays : un code-barres lu sur un ticket français désigne parfois un
# produit qu'Open Food Facts ne rattache à aucun pays. Le filtrer ici perdrait
# la vérité de l'article pour une raison qui ne le concerne pas.
CODES_QUERY = """
COPY (
  SELECT code, categories_tags
  FROM read_parquet('{source}')
  WHERE categories_tags IS NOT NULL AND len(categories_tags) > 0
) TO '{target}' (FORMAT PARQUET)
"""

DUMPS = {
    "food.parquet": ("off_products_fr.parquet", "off_codes_food.parquet"),
    "beauty.parquet": ("obf_products_fr.parquet", "off_codes_beauty.parquet"),
}


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


def _extract(query: str, source: str, target: Path, **arguments) -> None:
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
        connection.execute(query.format(source=source, target=partial, **arguments))
        count = connection.execute(f"SELECT count(*) FROM read_parquet('{partial}')").fetchone()[0]
        partial.replace(target)
    finally:
        partial.unlink(missing_ok=True)
    print(f"{target.name}: {count} lignes en {time.time() - start:.0f} s")


def main() -> None:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    for name, (products, codes) in DUMPS.items():
        source = BASE_URL + name
        _extract(CODES_QUERY, source, CACHE_DIR / codes)
        _extract(PRODUCTS_QUERY, source, CACHE_DIR / products, limit=MAX_PRODUCTS)


if __name__ == "__main__":
    sys.exit(main())
