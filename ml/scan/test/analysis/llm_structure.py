"""Structuration par LLM : lignes OCR reconstruites → JSON articles/prix.

Benchmarke le « cerveau » LLM contre les règles, à armes égales : même
entrée (lignes physiques issues de ML Kit), même vérité terrain, même
métrique (corrections par ticket). Le modèle est de la classe embarquable
sur téléphone (Gemma 3n E2B via ollama).
"""

from __future__ import annotations

import json
import re
import urllib.request

OLLAMA_URL = "http://localhost:11434/api/chat"
MODEL = "gemma3n:e2b"

SCHEMA = {
    "type": "object",
    "properties": {
        "store": {"type": ["string", "null"]},
        "date": {"type": ["string", "null"]},
        "total": {"type": ["number", "null"]},
        "items": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "name": {"type": "string"},
                    "amount": {"type": "number"},
                    "discount": {"type": "number"},
                },
                "required": ["name", "amount", "discount"],
            },
        },
    },
    "required": ["store", "date", "total", "items"],
}

PROMPT = """Tu lis le texte OCR d'un ticket de caisse, ligne par ligne.
Extrais en JSON :
- "store" : nom du commerce (null si illisible)
- "date" : date au format YYYY-MM-DD (null si absente)
- "total" : le montant total à payer imprimé sur le ticket (null si absent)
- "items" : chaque article acheté avec :
  - "name" : son libellé tel qu'imprimé
  - "amount" : son prix total en euros (si quantité > 1, le prix total, pas l'unitaire)
  - "discount" : la remise appliquée à cet article en euros, 0 si aucune

Règles :
- Les remises (REMISE, AVANTAGE, montants négatifs) se rattachent à l'article qui les précède.
- Ignore : totaux, sous-totaux par rayon, TVA, moyens de paiement, rendu monnaie, points fidélité, publicités.
- Ne recopie que des montants présents dans le texte, n'invente jamais un chiffre.

Ticket :
{receipt}
"""


def structure_with_llm(lines_text: str, timeout: int = 300) -> dict:
    payload = {
        "model": MODEL,
        "messages": [
            {"role": "user", "content": PROMPT.format(receipt=lines_text)}
        ],
        "format": SCHEMA,
        "stream": False,
        "options": {"temperature": 0, "num_ctx": 4096},
    }
    request = urllib.request.Request(
        OLLAMA_URL,
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:
        body = json.load(response)
    content = body["message"]["content"]
    return json.loads(content)


def ocr_lines_text(result_path) -> str:
    from pathlib import Path

    from lines import cluster_lines, deskew_words, load_words, median_angle
    from structure import merge_price_fragments

    words, data = load_words(Path(result_path))
    words = deskew_words(words, median_angle(data))
    return "\n".join(
        merge_price_fragments(line).text for line in cluster_lines(words)
    )


def parse_llm_receipt(raw: dict) -> tuple[list[tuple[float, float]], float | None]:
    items: list[tuple[float, float]] = []
    for item in raw.get("items") or []:
        amount = item.get("amount")
        if not isinstance(amount, (int, float)):
            continue
        discount = item.get("discount")
        if not isinstance(discount, (int, float)):
            discount = 0.0
        items.append((round(float(amount), 2), round(abs(float(discount)), 2)))
    total = raw.get("total")
    total_value = round(float(total), 2) if isinstance(total, (int, float)) else None
    return items, total_value


AMOUNT_PATTERN = re.compile(r"\d{1,4}[.,]\d{2}")


def amounts_in_text(text: str) -> set[float]:
    return {
        float(match.replace(",", "."))
        for match in AMOUNT_PATTERN.findall(text)
    }
