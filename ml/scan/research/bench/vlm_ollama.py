"""Plafond d'un VLM local, sans entraînement : image → JSON, même métrique.

Le bench held-out (`bench/held_out.py`) juge la chaîne locale — OCR puis
tagger de rôles — sur la tranche réservée d'`open_prices`. Celui-ci juge un
VLM servi par Ollama sur les **mêmes tickets**, la **même vérité annotée** et
la **même métrique produit**, pour répondre à une seule question : un modèle
qui connaît déjà le monde lit-il le ticket aussi bien qu'une chaîne entraînée
sur mesure ?

Le checksum reste le juge de la validation : un ticket n'est « vérifié » que
si la somme des articles nets retombe sur le total que le modèle a lu. Un VLM
peut halluciner, cet invariant le détecte — c'est ce qui rend la sortie d'un
modèle générique utilisable sans trahir la règle du zéro silencieux.

    uv run python -m bench.vlm_ollama --model=gemma4:e4b [--limit=N]
"""

from __future__ import annotations

import base64
import io
import json
import re
import sys
import time
import urllib.error
import urllib.request
from datetime import date
from pathlib import Path

from PIL import Image

from annotate.dataset import AnnotatedReceipt, load
from bench.exactness import ExtractedName, receipt_exactness
from bench.held_out import DEFAULT_CORPUS, report
from llm.structure import SCHEMA
from paths import ANNOTATIONS_DIR, CORPUS_DIR, RESULTS_DIR
from truth.references import receipt_from_annotation

API_URL = "http://localhost:11434/api/chat"
AMOUNT_EPSILON = 0.005
MAX_IMAGE_SIDE = 1536
ISO_DATE = re.compile(r"^(\d{4})-(\d{1,2})-(\d{1,2})$")
PRINTED_DATE = re.compile(r"^(\d{1,2})[/.-](\d{1,2})[/.-](\d{2}|\d{4})$")
SHORT_YEAR_CENTURY = 2000
REQUEST_TIMEOUT = 900
CALL_ERRORS = (OSError, ValueError, KeyError, urllib.error.URLError)

PROMPT = """Tu lis la photo d'un ticket de caisse français.
Extrais en JSON :
- "store" : nom du commerce (null si illisible)
- "date" : date au format YYYY-MM-DD (null si absente)
- "total" : le montant total à payer imprimé (null si absent)
- "items" : chaque article acheté avec :
  - "name" : son libellé tel qu'imprimé
  - "amount" : son prix total en euros (si quantité > 1, le prix total, pas l'unitaire)
  - "discount" : la remise appliquée à cet article en euros, 0 si aucune

Règles :
- Les remises se rattachent à l'article qui les précède.
- Ignore : totaux, sous-totaux par rayon, TVA, moyens de paiement, rendu monnaie, fidélité, publicités.
- Ne recopie que des montants imprimés, n'invente jamais un chiffre."""


def encoded_image(path: Path) -> str:
    image = Image.open(path)
    image.thumbnail((MAX_IMAGE_SIDE, MAX_IMAGE_SIDE))
    buffer = io.BytesIO()
    image.convert("RGB").save(buffer, format="JPEG", quality=90)
    return base64.b64encode(buffer.getvalue()).decode()


def call_ollama(model: str, path: Path) -> dict:
    payload = {
        "model": model,
        "messages": [
            {"role": "user", "content": PROMPT, "images": [encoded_image(path)]}
        ],
        "format": SCHEMA,
        "stream": False,
        "options": {"temperature": 0, "num_ctx": 8192},
    }
    request = urllib.request.Request(
        API_URL,
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=REQUEST_TIMEOUT) as response:
        body = json.load(response)
    return json.loads(body["message"]["content"])


def extracted_names(raw: dict) -> list[ExtractedName]:
    names: list[ExtractedName] = []
    for item in raw.get("items") or []:
        amount = item.get("amount")
        if not isinstance(amount, (int, float)):
            continue
        discount = item.get("discount")
        if not isinstance(discount, (int, float)):
            discount = 0.0
        names.append(
            ExtractedName(
                str(item.get("name") or ""),
                round(float(amount), 2),
                round(abs(float(discount)), 2),
            )
        )
    return names


def iso_date(value: object) -> str | None:
    """Le modèle rend la date telle qu'imprimée ; la vérité est en ISO. Sans
    cette normalisation, tout ticket français perdrait sur le poste `date`
    pour une question de format, pas de lecture."""
    if not isinstance(value, str):
        return None
    text = value.strip()
    iso = ISO_DATE.match(text)
    if iso:
        year, month, day = (int(group) for group in iso.groups())
    else:
        printed = PRINTED_DATE.match(text)
        if printed is None:
            return None
        day, month, year = (int(group) for group in printed.groups())
        if year < 100:
            year += SHORT_YEAR_CENTURY
    try:
        return date(year, month, day).isoformat()
    except ValueError:
        return None


def checksum_ok(items: list[ExtractedName], total: float | None) -> bool:
    if total is None or not items:
        return False
    return abs(sum(item.net for item in items) - total) < AMOUNT_EPSILON


def _truth(receipt: AnnotatedReceipt) -> dict | None:
    path = ANNOTATIONS_DIR / receipt.corpus / f"{Path(receipt.name).stem}.json"
    if not path.exists():
        return None
    return receipt_from_annotation(json.loads(path.read_text()))


def _cached(cache: Path, model: str, receipt: AnnotatedReceipt) -> dict | None:
    path = cache / f"{Path(receipt.name).stem}.json"
    if path.exists():
        return json.loads(path.read_text())
    image = CORPUS_DIR / receipt.corpus / receipt.name
    raw = call_ollama(model, image)
    path.write_text(json.dumps(raw, ensure_ascii=False))
    return raw


def _score(raw: dict, truth: dict) -> dict:
    items = extracted_names(raw)
    total = raw.get("total")
    total_value = round(float(total), 2) if isinstance(total, (int, float)) else None
    if not checksum_ok(items, total_value):
        return {"verified": False}
    exactness = receipt_exactness(
        raw.get("store"),
        iso_date(raw.get("date")),
        total_value,
        items,
        {"receipt": truth},
    )
    return {
        "verified": True,
        "wrong": exactness.wrong,
        "silent": exactness.silent,
        "items": len(truth["items"]),
        "exact_labels": exactness.exact_labels,
        "tolerated_labels": exactness.tolerated_labels,
        "labels_all_exact": exactness.labels_all_exact,
        "store_judged": exactness.store_judged,
    }


def run(model: str, corpus: str, limit: int | None) -> list[dict]:
    cache = RESULTS_DIR / f"vlm_{model.replace(':', '_')}"
    cache.mkdir(parents=True, exist_ok=True)
    receipts = [r for r in load(held_out=True) if r.corpus == corpus]
    scored = []
    started = time.time()
    for index, receipt in enumerate(receipts[:limit] if limit else receipts):
        truth = _truth(receipt)
        if truth is None or not truth["items"]:
            continue
        try:
            raw = _cached(cache, model, receipt)
        except CALL_ERRORS as error:
            print(f"FAIL {receipt.name}: {error}", file=sys.stderr)
            continue
        scored.append({"name": receipt.name} | _score(raw, truth))
        elapsed = time.time() - started
        print(
            f"\r{len(scored)} tickets, {elapsed / max(index + 1, 1):.1f}s/ticket",
            end="",
            file=sys.stderr,
        )
    print(file=sys.stderr)
    return scored


def main(argv: list[str]) -> int:
    model = None
    corpus = DEFAULT_CORPUS
    limit = None
    for argument in argv:
        if argument.startswith("--model="):
            model = argument.split("=", 1)[1]
        elif argument.startswith("--corpus="):
            corpus = argument.split("=", 1)[1]
        elif argument.startswith("--limit="):
            limit = int(argument.split("=", 1)[1])
    if model is None:
        print("--model=<tag ollama> requis", file=sys.stderr)
        return 1
    scored = run(model, corpus, limit)
    print(f"\n### {model}")
    report(scored)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
