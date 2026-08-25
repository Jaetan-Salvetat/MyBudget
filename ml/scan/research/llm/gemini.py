"""Client Gemini Flash via OpenRouter : image de ticket → JSON structuré.

La clé API est lue dans OPENROUTER_API_KEY, jamais écrite sur disque. Sert
à annoter le golden (truth/annotate.py) et à mesurer le plafond VLM cloud
(bench/gemini.py).
"""

from __future__ import annotations

import base64
import json
import urllib.request
from pathlib import Path

from llm.structure import SCHEMA

MODEL = "google/gemini-3.7-flash"
API_URL = "https://openrouter.ai/api/v1/chat/completions"

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


def call_gemini(image_path: Path, api_key: str) -> dict:
    encoded = base64.b64encode(image_path.read_bytes()).decode()
    payload = {
        "model": MODEL,
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": PROMPT},
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:image/jpeg;base64,{encoded}"
                        },
                    },
                ],
            }
        ],
        "response_format": {
            "type": "json_schema",
            "json_schema": {
                "name": "receipt",
                "strict": True,
                "schema": SCHEMA,
            },
        },
        "temperature": 0,
    }
    request = urllib.request.Request(
        API_URL,
        data=json.dumps(payload).encode(),
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
    )
    with urllib.request.urlopen(request, timeout=600) as response:
        body = json.load(response)
    return json.loads(body["choices"][0]["message"]["content"])
