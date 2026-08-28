"""Le corpus Open Prices : tickets de caisse français, photographiés récemment.

Open Prices (Open Food Facts) collecte des prix ; les contributeurs joignent
la photo de leur ticket comme preuve. Le dump quotidien liste des *prix*, pas
des tickets : ce module les regroupe par preuve, ne garde que les tickets
français, et en tire une **vérité partielle**.

Partielle, et c'est le point : le contributeur déclare un total et un nombre
d'articles, mais ne saisit que les prix qui l'intéressent. `amounts` n'est
donc pas la liste des articles — seul `complete` dit quand les deux
coïncident. Prendre l'un pour l'autre fabriquerait une fausse vérité.

Ce que cette vérité apporte et que le corpus n'avait pas : un **total saisi
par un humain**, indépendant de tout OCR. Le golden FindIt est la seule autre
source du genre, et il date de 2017.

    uv run python -m corpus.open_prices [--limit N]

Images sous CC BY-SA 4.0, base de données sous ODbL.
"""

from __future__ import annotations

import json
import sys
import urllib.error
import urllib.request
from dataclasses import dataclass, field
from io import BytesIO
from pathlib import Path

import pyarrow.parquet as pq
from PIL import Image, ImageOps

from paths import CORPUS_DIR, DATA_DIR

DUMP_URL = "https://www.data.gouv.fr/api/1/datasets/r/49716ed5-aacf-4692-8b2d-3cc6d15bf1d1"
IMAGE_BASE = "https://prices.openfoodfacts.org/img/"
LICENCE = "CC-BY-SA-4.0"
SOURCE = "open_prices"

RECEIPT = "RECEIPT"
FRANCE = "FR"

DUMP_PATH = DATA_DIR / "raw" / "open_prices.parquet"
OUTPUT_DIR = CORPUS_DIR / "open_prices"
TRUTH_DIR = OUTPUT_DIR / "truth"

# Le dump ne porte que les colonnes utiles : le lire en entier coûterait
# 300 000 lignes × 48 colonnes pour n'en exploiter que dix.
COLUMNS = (
    "proof_id",
    "proof_type",
    "proof_file_path",
    "proof_mimetype",
    "proof_date",
    "proof_receipt_price_count",
    "proof_receipt_price_total",
    "location_osm_address_country_code",
    "location_osm_display_name",
    "price",
)
JPEG_QUALITY = 92
TIMEOUT_SECONDS = 60


@dataclass
class Proof:
    id: int
    file_path: str
    store: str | None
    date: str | None
    total: float | None
    declared_count: int | None
    amounts: list[float] = field(default_factory=list)

    @property
    def name(self) -> str:
        return f"op_{self.id:07d}"

    @property
    def complete(self) -> bool:
        """Tous les articles du ticket ont-ils été saisis ? Sans total ni
        nombre déclaré, on ne peut rien affirmer."""
        if self.total is None or self.declared_count is None:
            return False
        return len(self.amounts) == self.declared_count

    def truth(self) -> dict:
        return {
            "proof_id": self.id,
            "store": self.store,
            "date": self.date,
            "total": self.total,
            "item_count_declared": self.declared_count,
            "amounts": self.amounts,
            "complete": self.complete,
            "source": SOURCE,
            "image_url": image_url(self.file_path),
            "licence": LICENCE,
        }


def image_url(file_path: str) -> str:
    return IMAGE_BASE + file_path


def _store_of(display_name: str | None) -> str | None:
    """L'enseigne est le premier champ du nom OpenStreetMap du lieu."""
    if not display_name:
        return None
    return display_name.split(",")[0].strip() or None


def _amount(value) -> float | None:
    """Le dump rend les montants en `Decimal` : tout le reste du scan parle
    float, la conversion se fait ici et nulle part ailleurs."""
    return None if value is None else float(value)


def proofs_from(rows) -> list[Proof]:
    """Les tickets français du dump, un par preuve, prix regroupés."""
    proofs: dict[int, Proof] = {}
    for row in rows:
        if row["proof_type"] != RECEIPT:
            continue
        if row["location_osm_address_country_code"] != FRANCE:
            continue
        proof = proofs.get(row["proof_id"])
        if proof is None:
            proof = Proof(
                id=row["proof_id"],
                file_path=row["proof_file_path"],
                store=_store_of(row["location_osm_display_name"]),
                date=str(row["proof_date"])[:10] if row["proof_date"] else None,
                total=_amount(row["proof_receipt_price_total"]),
                declared_count=row["proof_receipt_price_count"],
            )
            proofs[proof.id] = proof
        if row["price"] is not None:
            proof.amounts.append(_amount(row["price"]))
    return list(proofs.values())


def _rows_of(path: Path):
    table = pq.read_table(path, columns=list(COLUMNS))
    columns = {name: table.column(name).to_pylist() for name in COLUMNS}
    for index in range(table.num_rows):
        yield {name: columns[name][index] for name in COLUMNS}


def download_dump(path: Path = DUMP_PATH) -> Path:
    if path.exists():
        return path
    path.parent.mkdir(parents=True, exist_ok=True)
    print(f"téléchargement du dump → {path}")
    urllib.request.urlretrieve(DUMP_URL, path)
    return path


def fetch_image(proof: Proof, directory: Path) -> bool:
    """L'image du ticket, convertie en JPEG — le reste du pipeline ne lit
    ni webp ni octet-stream. Rend False si elle est illisible."""
    destination = directory / f"{proof.name}.jpg"
    if destination.exists():
        return True
    try:
        with urllib.request.urlopen(
            image_url(proof.file_path), timeout=TIMEOUT_SECONDS
        ) as response:
            payload = response.read()
    except (urllib.error.URLError, TimeoutError) as error:
        print(f"  ÉCHEC {proof.name} : {error}", file=sys.stderr)
        return False
    try:
        image = ImageOps.exif_transpose(Image.open(BytesIO(payload)).convert("RGB"))
    except OSError as error:
        print(f"  ILLISIBLE {proof.name} : {error}", file=sys.stderr)
        return False
    image.save(destination, "JPEG", quality=JPEG_QUALITY)
    return True


def main(argv: list[str]) -> int:
    limit = int(argv[argv.index("--limit") + 1]) if "--limit" in argv else None
    proofs = proofs_from(_rows_of(download_dump()))
    proofs.sort(key=lambda proof: (not proof.complete, -len(proof.amounts)))
    if limit:
        proofs = proofs[:limit]

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    TRUTH_DIR.mkdir(exist_ok=True)
    fetched = 0
    for index, proof in enumerate(proofs, start=1):
        if fetch_image(proof, OUTPUT_DIR):
            (TRUTH_DIR / f"{proof.name}.json").write_text(
                json.dumps(proof.truth(), ensure_ascii=False, indent=1)
            )
            fetched += 1
        if index % 50 == 0:
            print(f"  {index}/{len(proofs)}", flush=True)

    complete = sum(1 for proof in proofs if proof.complete)
    with_total = sum(1 for proof in proofs if proof.total is not None)
    print(f"\n=== {fetched} tickets FR récupérés sur {len(proofs)}")
    print(f"  avec total déclaré : {with_total}")
    print(f"  articles tous saisis : {complete}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
