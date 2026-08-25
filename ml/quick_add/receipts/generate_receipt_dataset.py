"""Construit le corpus « style ticket » : `dataset/receipts_train.jsonl` et
`dataset/receipts_eval.jsonl`, au format de `train.jsonl`.

Quatre sources, toutes passées par le même style de caisse puis la même
normalisation que l'app :

- produits Open Food Facts / Open Beauty Facts vendus en France (nom, marque,
  contenance) — la connaissance produit, classée par famille de tags ;
- lexique manuel des familles non couvertes (vêtements, bricolage, pharmacie,
  plats, carburant…) ;
- libellés réels des tickets FindIt T1-train avec leur vérité manuelle —
  jamais T1-test, réservé à la mesure ;
- en-têtes d'enseigne tels qu'imprimés (majuscules, ville, raison sociale,
  abréviations « CRF CITY »), tirés des entités physiques de la base.

La coupe train/eval se fait par produit, pas par ligne.
"""

import json
import random
import sys
from collections import Counter, defaultdict
from pathlib import Path

import duckdb

from knowledge.build import ENTITIES_PATH
from knowledge.entities import is_latin, read_entities
from receipts.labels import EXCLUDED_ITEMS, EXCLUDED_STORES, ITEM_OVERRIDES, STORE_LABELS
from receipts.lexicon import CITIES, LEGAL_SUFFIXES, RECEIPT_LEXICON, STORE_ABBREVIATIONS
from receipts.normalize import normalize_receipt_line
from receipts.style import receipt_line, strip_accents
from taxonomy import EXPENSE_TYPE, LABEL_INDEX, ONE_TIME

DATASET_DIR = Path(__file__).resolve().parents[1] / "dataset"
CACHE_DIR = DATASET_DIR / "cache"
GOLDEN_DIR = Path(__file__).resolve().parents[3] / "ml" / "scan" / "test" / "golden"
SEED = 42
EVAL_RATIO = 0.05

OFF_MAX_PRODUCTS = 12_000
OFF_VARIANTS = 1
OBF_MAX_PRODUCTS = 6_000
LEXICON_VARIANTS = 8
STORE_HEADER_VARIANTS = 4
STORE_HEADER_MAX = 6_000
GOLDEN_WEIGHT = 2
RECEIPT_CLASS_CAP = 12_000

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

SHOP_FAMILIES = frozenset({
    "alimentation.supermarche", "alimentation.epicerie", "alimentation.boulangerie", "alimentation.marche",
    "restauration.restaurant", "restauration.fast_food", "restauration.cafe", "restauration.bar",
    "transport.essence", "transport.parking", "transport.peage", "transport.entretien_vehicule",
    "logement.travaux", "sante_beaute.pharmacie", "sante_beaute.coiffeur", "sante_beaute.esthetique",
    "loisirs.cinema_sortie", "loisirs.sport", "loisirs.livre_presse", "loisirs.jeux_video",
    "shopping.vetements", "shopping.electronique", "shopping.mobilier_deco",
    "famille_education.fournitures", "famille_education.activites_enfants",
    "voyage.hebergement", "voyage.activite_visite", "divers.cadeau_offert", "divers.animaux",
    "divers.tabac_jeux",
})
STORE_SOURCES = frozenset({"nsi", "services", "lexicon"})


def row(text: str, slug: str) -> dict:
    return {
        "text": text,
        "type_label": EXPENSE_TYPE,
        "category_label": LABEL_INDEX[slug],
        "recurrence_label": ONE_TIME,
    }


def off_slug(tags: list[str]) -> str | None:
    for tag in tags:
        if tag.startswith(PET_TAGS):
            return ANIMAUX
        if tag.startswith(SKIP_TAGS):
            return None
    return SUPERMARCHE


def obf_slug(tags: list[str]) -> str:
    for tag in tags:
        if tag.startswith(COSMETIC_TAGS):
            return ESTHETIQUE
        if tag.startswith(PHARMA_TAGS):
            return PHARMACIE
    return SUPERMARCHE


def _products(path: Path, limit: int) -> list[tuple[str, str | None, str | None, list[str]]]:
    if not path.exists():
        raise FileNotFoundError(f"{path} absent : lancer d'abord `python -m receipts.fetch_off`")
    connection = duckdb.connect()
    rows = connection.execute(
        f"SELECT name, brands, quantity, categories_tags FROM read_parquet('{path}') "
        f"WHERE length(name) BETWEEN 3 AND 60 ORDER BY scans DESC LIMIT {limit}"
    ).fetchall()
    return [
        (name, brand if brand and is_latin(brand) else None, quantity, list(tags or []))
        for name, brand, quantity, tags in rows
        if is_latin(name)
    ]


def product_lines(rng: random.Random) -> list[tuple[str, str, str]]:
    """(clé produit, texte, slug) pour les produits OFF et OBF."""
    out: list[tuple[str, str, str]] = []
    for name, brand, quantity, tags in _products(CACHE_DIR / "off_products_fr.parquet", OFF_MAX_PRODUCTS):
        slug = off_slug(tags)
        if slug is None:
            continue
        for _ in range(OFF_VARIANTS):
            out.append((name, receipt_line(name, rng, brand, quantity), slug))
    for name, brand, quantity, tags in _products(CACHE_DIR / "obf_products_fr.parquet", OBF_MAX_PRODUCTS):
        slug = obf_slug(tags)
        for _ in range(OFF_VARIANTS):
            out.append((name, receipt_line(name, rng, brand, quantity), slug))
    return out


def lexicon_lines(rng: random.Random) -> list[tuple[str, str, str]]:
    out: list[tuple[str, str, str]] = []
    for slug, entries in RECEIPT_LEXICON.items():
        for entry in entries:
            out.append((entry, normalize_receipt_line(entry), slug))
            for _ in range(LEXICON_VARIANTS - 1):
                out.append((entry, receipt_line(entry, rng, abbreviation_rate=0.35), slug))
    return out


def golden_lines() -> list[tuple[str, str, str]]:
    out: list[tuple[str, str, str]] = []
    for path in sorted((GOLDEN_DIR / "T1-train").glob("*.json")):
        receipt = json.loads(path.read_text(encoding="utf-8"))["receipt"]
        store = receipt.get("store") or ""
        if store in EXCLUDED_STORES:
            continue
        for item in receipt["items"]:
            name = item["name"]
            if name in EXCLUDED_ITEMS:
                continue
            slug = ITEM_OVERRIDES.get(name) or STORE_LABELS.get(store)
            if slug is None:
                continue
            text = normalize_receipt_line(name)
            for _ in range(GOLDEN_WEIGHT):
                out.append((f"golden:{name}", text, slug))
    return out


def _header(name: str, rng: random.Random) -> str:
    text = strip_accents(name).upper()
    shape = rng.randrange(6)
    if shape == 0:
        text = f"{text} {rng.choice(CITIES)}"
    elif shape == 1:
        text = f"{text} - {rng.choice(CITIES)}"
    elif shape == 2:
        text = f"{text} {rng.choice(LEGAL_SUFFIXES)}"
    elif shape == 3:
        text = f"{rng.choice(['SARL', 'SAS', 'EURL'])} {text}"
    elif shape == 4:
        text = f"{text} {rng.choice(CITIES)} {rng.choice(LEGAL_SUFFIXES)}"
    return normalize_receipt_line(text)


def store_lines(rng: random.Random) -> list[tuple[str, str, str]]:
    out: list[tuple[str, str, str]] = []
    for canonical, (slug, forms) in STORE_ABBREVIATIONS.items():
        for form in forms:
            out.append((canonical, normalize_receipt_line(form), slug))
            for _ in range(STORE_HEADER_VARIANTS):
                out.append((canonical, _header(form, rng), slug))
    candidates = [
        entity for entity in read_entities(ENTITIES_PATH)
        if entity.source in STORE_SOURCES and entity.slug in SHOP_FAMILIES
    ]
    rng.shuffle(candidates)
    for entity in candidates[:STORE_HEADER_MAX]:
        for _ in range(STORE_HEADER_VARIANTS):
            out.append((entity.key, _header(entity.name, rng), entity.slug))
    return out


def split(lines: list[tuple[str, str, str]], rng: random.Random) -> tuple[list[dict], list[dict]]:
    by_key: dict[str, list[tuple[str, str]]] = defaultdict(list)
    for key, text, slug in lines:
        by_key[key].append((text, slug))
    keys = sorted(by_key)
    rng.shuffle(keys)
    held = set(keys[: int(len(keys) * EVAL_RATIO)])
    train: list[dict] = []
    evaluation: list[dict] = []
    seen: set[tuple[str, str]] = set()
    for key in keys:
        for text, slug in by_key[key]:
            if not text or (text, slug) in seen:
                continue
            seen.add((text, slug))
            (evaluation if key in held else train).append(row(text, slug))
    rng.shuffle(train)
    rng.shuffle(evaluation)
    return train, evaluation


def generate(seed: int = SEED) -> tuple[list[dict], list[dict]]:
    rng = random.Random(seed)
    lines = product_lines(rng) + lexicon_lines(rng) + store_lines(rng)
    train, evaluation = split(lines, rng)
    golden = [row(text, slug) for _key, text, slug in golden_lines()]
    train = cap_per_class(train + golden, RECEIPT_CLASS_CAP, rng)
    rng.shuffle(train)
    return train, evaluation


def cap_per_class(rows: list[dict], cap: int, rng: random.Random) -> list[dict]:
    """Aucune classe au-delà de `cap` lignes : les produits alimentaires sont
    dix fois plus nombreux que tout le reste et tireraient le modèle vers
    « supermarché » sur n'importe quel libellé inconnu."""
    by_class: dict[int, list[dict]] = defaultdict(list)
    for entry in rows:
        by_class[entry["category_label"]].append(entry)
    kept: list[dict] = []
    for entries in by_class.values():
        rng.shuffle(entries)
        kept.extend(entries[:cap])
    return kept


def save_jsonl(rows: list[dict], path: Path) -> None:
    with path.open("w", encoding="utf-8") as handle:
        for entry in rows:
            handle.write(json.dumps(entry, ensure_ascii=False) + "\n")


def main() -> None:
    train, evaluation = generate()
    save_jsonl(train, DATASET_DIR / "receipts_train.jsonl")
    save_jsonl(evaluation, DATASET_DIR / "receipts_eval.jsonl")
    from taxonomy import LABELS

    per_class = Counter(LABELS[entry["category_label"]] for entry in train)
    print(f"Train : {len(train)}  |  Eval : {len(evaluation)}")
    for slug, count in per_class.most_common():
        print(f"  {slug:45} {count}")


if __name__ == "__main__":
    sys.exit(main())
