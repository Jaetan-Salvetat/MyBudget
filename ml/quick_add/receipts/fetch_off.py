"""Extrait d'Open Food Facts (ODbL) les produits vendus en France : nom, marque,
catégories, contenance, popularité. Le dump Hugging Face (8 Go) est téléchargé
en entier — la lecture distante par plages plafonne à quelques Mo/min — puis
réduit localement à un parquet de quelques dizaines de Mo, et supprimé.
"""

import subprocess
import sys
import time
from pathlib import Path

import duckdb

CACHE_DIR = Path(__file__).resolve().parents[1] / "dataset" / "cache"
BASE_URL = "https://huggingface.co/datasets/openfoodfacts/product-database/resolve/main/"
DUMPS = {
    "food.parquet": CACHE_DIR / "off_products_fr.parquet",
    "beauty.parquet": CACHE_DIR / "obf_products_fr.parquet",
}
MAX_PRODUCTS = 250_000

QUERY = """
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


def download(name: str) -> Path:
    dump = CACHE_DIR / name
    if not dump.exists():
        subprocess.run(
            ["curl", "-L", "--fail", "--retry", "3", "-o", str(dump), BASE_URL + name],
            check=True,
        )
    return dump


def reduce(dump: Path, target: Path, limit: int) -> None:
    connection = duckdb.connect()
    connection.execute(QUERY.format(source=dump, target=target, limit=limit))
    count = connection.execute(f"SELECT count(*) FROM read_parquet('{target}')").fetchone()[0]
    print(f"{target.name}: {count} produits")


def main() -> None:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    for name, target in DUMPS.items():
        if target.exists():
            print(f"{target.name} déjà présent")
            continue
        started = time.time()
        dump = download(name)
        reduce(dump, target, MAX_PRODUCTS)
        dump.unlink()
        print(f"{name} traité en {time.time() - started:.0f} s")


if __name__ == "__main__":
    sys.exit(main())
