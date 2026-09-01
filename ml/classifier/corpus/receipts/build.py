"""Construit le corpus « style ticket » : `dataset/receipts_train.jsonl` et
`dataset/receipts_eval.jsonl`, au format de `train.jsonl`.

Quatre sources, toutes passées par le même style de caisse puis la même
normalisation que l'app :

- produits Open Food Facts, Open Beauty Facts, Open Products Facts et Open Pet
  Food Facts vendus en France (nom, marque, contenance) — la connaissance
  produit, classée par famille de tags ;
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

from corpus.receipts import openprices
from corpus.receipts.categories import beauty_slug, food_slug, petfood_slug, products_slug
from corpus.receipts.labels import EXCLUDED_STORES
from corpus.receipts.lexicon import (
    CITIES,
    LEGAL_SUFFIXES,
    RECEIPT_LEXICON,
    STORE_ABBREVIATIONS,
)
from corpus.receipts.style import receipt_line, strip_accents
from corpus.receipts.truth import item_label
from knowledge.entities import is_latin, read_entities
from paths import (
    CACHE_DIR,
    DATASET_DIR,
    ENTITIES_PATH,
    OPEN_PRICES_PATH,
    SCAN_GOLDEN_DIR,
)
from serving.contract import write_taxonomy_stamp
from serving.normalize import normalize_receipt_line
from taxonomy import EXPENSE_TYPE, LABEL_INDEX, ONE_TIME

GOLDEN_DIR = SCAN_GOLDEN_DIR
SEED = 42
EVAL_RATIO = 0.05

OFF_VARIANTS = 1
LEXICON_VARIANTS = 8
STORE_HEADER_VARIANTS = 4
STORE_HEADER_MAX = 6_000
GOLDEN_WEIGHT = 2
RECEIPT_CLASS_CAP = 12_000

# Open Prices apporte cent mille libellés dont la quasi-totalité est
# alimentaire. Sans plafond à la source, cette seule classe remplirait le
# corpus avant que le lexique écrit à la main y ait sa place.
OPEN_PRICES_CLASS_CAP = 8_000

# Les quatre bases produit, chacune avec la règle qui traduit ses catégories.
# Seule l'alimentaire est plafonnée : elle pèse à elle seule vingt fois les
# trois autres, qui portent justement les classes où le corpus était mince.
PRODUCT_SOURCES = (
    ("off_products_fr.parquet", food_slug, 12_000),
    ("obf_products_fr.parquet", beauty_slug, None),
    ("opf_products_fr.parquet", products_slug, None),
    ("opff_products_fr.parquet", petfood_slug, None),
)

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


def _products(path: Path, limit: int | None) -> list[tuple[str, str | None, str | None, list[str]]]:
    if not path.exists():
        raise FileNotFoundError(f"{path} absent : lancer d'abord `python -m corpus.receipts.fetch_off`")
    connection = duckdb.connect()
    rows = connection.execute(
        f"SELECT name, brands, quantity, categories_tags FROM read_parquet('{path}') "
        f"WHERE length(name) BETWEEN 3 AND 60 ORDER BY scans DESC "
        f"{f'LIMIT {limit}' if limit else ''}"
    ).fetchall()
    return [
        (name, brand if brand and is_latin(brand) else None, quantity, list(tags or []))
        for name, brand, quantity, tags in rows
        if is_latin(name)
    ]


def product_lines(rng: random.Random) -> list[tuple[str, str, str]]:
    """(clé produit, texte, slug) pour les produits des quatre bases."""
    out: list[tuple[str, str, str]] = []
    for filename, slug_for, limit in PRODUCT_SOURCES:
        for name, brand, quantity, tags in _products(CACHE_DIR / filename, limit):
            slug = slug_for(tags)
            if slug is None:
                continue
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


def golden_lines(labels: dict[str, str]) -> list[tuple[str, str, str]]:
    """Les libellés réels de T1-train, avec la classe de l'article.

    La classe venait de l'enseigne : le même `banane` était épicerie chez
    l'un, supermarché chez l'autre, restaurant chez un troisième. Un article
    que rien ne sait classer sort du corpus plutôt que d'y entrer sous
    l'étiquette de son magasin."""
    out: list[tuple[str, str, str]] = []
    for path in sorted((GOLDEN_DIR / "T1-train").glob("*.json")):
        receipt = json.loads(path.read_text(encoding="utf-8"))["receipt"]
        store = receipt.get("store") or ""
        if store in EXCLUDED_STORES:
            continue
        for item in receipt["items"]:
            name = item["name"]
            slug = item_label(name, labels)
            if slug is None:
                continue
            for _ in range(GOLDEN_WEIGHT):
                out.append((f"golden:{name}", normalize_receipt_line(name), slug))
    return out


def held_out_texts() -> set[str]:
    """Les écritures des articles de T1-test.

    T1-test mesure ce que le modèle fait d'un libellé qu'il n'a pas vu. Sa
    vérité vient maintenant d'Open Prices, source qui alimente aussi
    l'entraînement : sans cette retenue, on mesurerait la mémoire du corpus."""
    out: set[str] = set()
    for path in sorted((GOLDEN_DIR / "T1-test").glob("*.json")):
        receipt = json.loads(path.read_text(encoding="utf-8"))["receipt"]
        for item in receipt["items"]:
            out.add(normalize_receipt_line(item["name"]))
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


def drop_contradictions(lines: list[tuple[str, str, str]]) -> list[tuple[str, str, str]]:
    """Retire les libellés que deux sources ne classent pas pareil.

    Le lexique écrit à la main range `asperges` au marché, Open Food Facts au
    supermarché ; `shampooing` est de l'entretien de voiture d'un côté, un
    produit de rayon de l'autre. Trancher au cas par cas reviendrait à écrire
    une règle par libellé ; garder les deux apprend une contradiction. Sur le
    corpus livré, cela concerne 177 libellés sur 50 204."""
    classes: dict[str, set[str]] = defaultdict(set)
    for _key, text, slug in lines:
        classes[text].add(slug)
    return [line for line in lines if len(classes[line[1]]) == 1]


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
    real = openprices.read_lines(OPEN_PRICES_PATH, openprices.CODES_PATHS)
    labels = openprices.label_table(real)
    lines = (
        cap_per_class(real, OPEN_PRICES_CLASS_CAP, rng, key=lambda line: line[2])
        + product_lines(rng)
        + lexicon_lines(rng)
        + store_lines(rng)
    )
    # La retenue s'applique aussi au golden : un article de T1-train peut porter
    # l'écriture d'un article de T1-test (`banane`, `baguette`), et l'apprendre
    # ferait mesurer la mémoire là où on veut mesurer la généralisation.
    held_out = held_out_texts()
    kept = drop_contradictions(
        [line for line in lines + golden_lines(labels) if line[1] not in held_out]
    )
    golden = [row(text, slug) for key, text, slug in kept if key.startswith("golden:")]
    train, evaluation = split([line for line in kept if not line[0].startswith("golden:")], rng)
    train = cap_per_class(train + golden, RECEIPT_CLASS_CAP, rng)
    rng.shuffle(train)
    return train, evaluation


def cap_per_class(rows: list, cap: int, rng: random.Random, key=None) -> list:
    """Aucune classe au-delà de `cap` lignes : les produits alimentaires sont
    dix fois plus nombreux que tout le reste et tireraient le modèle vers
    « supermarché » sur n'importe quel libellé inconnu.

    `key` dit où lire la classe, pour que le plafond s'applique aussi bien aux
    lignes déjà mises au format d'entraînement qu'aux triplets bruts d'une
    source — une seule implémentation, pas deux qui divergeront."""
    read = key or (lambda entry: entry["category_label"])
    by_class: dict = defaultdict(list)
    for entry in rows:
        by_class[read(entry)].append(entry)
    kept: list = []
    for entries in by_class.values():
        rng.shuffle(entries)
        kept.extend(entries[:cap])
    return kept


def save_jsonl(rows: list[dict], path: Path) -> None:
    with path.open("w", encoding="utf-8") as handle:
        for entry in rows:
            handle.write(json.dumps(entry, ensure_ascii=False) + "\n")
    write_taxonomy_stamp(path)


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
