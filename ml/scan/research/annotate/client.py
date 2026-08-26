"""Appel du modèle d'annotation via OpenRouter.

La clé vient de l'environnement (`OPENROUTER_API_KEY`) : elle ne doit jamais
atterrir dans le dépôt.

Appels unitaires, parallélisés côté appelant. Le Batch API d'OpenRouter, à
moitié prix, est hors de portée pour ce modèle : Vertex Gemini refuse toute
image en lot (« its serializer has no image URL map »), et le lot n'accepte
de toute façon que des URL publiques, jamais de base64. Mesuré le 2026-08-26,
avec le reste du raisonnement dans `README.md`.
"""

from __future__ import annotations

import base64
import json
import os
import urllib.error
import urllib.request
from io import BytesIO
from pathlib import Path

from PIL import Image, ImageOps

ENDPOINT = "https://openrouter.ai/api/v1/chat/completions"
MODEL = "google/gemini-3.7-flash"
MAX_TOKENS = 32000
TIMEOUT_SECONDS = 300
PREVIEW_LONG_SIDE = 2000
PREVIEW_QUALITY = 85
RETRYABLE_STATUS = (429, 500, 502, 503, 504)


class AnnotationError(RuntimeError):
    pass


def api_key() -> str:
    key = os.environ.get("OPENROUTER_API_KEY")
    if not key:
        raise AnnotationError("OPENROUTER_API_KEY absent de l'environnement")
    return key


def preview_data_url(image: Path, rotation: int = 0) -> str:
    """La photo réduite : le modèle lit la mise en page, pas les petits
    caractères — le texte lui arrive par l'OCR."""
    picture = ImageOps.exif_transpose(Image.open(image).convert("RGB"))
    if rotation:
        picture = picture.rotate(rotation, expand=True)
    picture.thumbnail((PREVIEW_LONG_SIDE, PREVIEW_LONG_SIDE), Image.Resampling.LANCZOS)
    buffer = BytesIO()
    picture.save(buffer, "JPEG", quality=PREVIEW_QUALITY)
    encoded = base64.b64encode(buffer.getvalue()).decode()
    return f"data:image/jpeg;base64,{encoded}"


def _payload(instructions: str, lines_text: str, image_url: str) -> dict:
    return {
        "model": MODEL,
        "max_tokens": MAX_TOKENS,
        "temperature": 0,
        "reasoning": {"effort": "low"},
        "response_format": {"type": "json_object"},
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": instructions},
                    {"type": "image_url", "image_url": {"url": image_url}},
                    {"type": "text", "text": f"Lignes OCR :\n{lines_text}"},
                ],
            }
        ],
    }


def annotate(instructions: str, lines_text: str, image_url: str) -> dict:
    request = urllib.request.Request(
        ENDPOINT,
        data=json.dumps(_payload(instructions, lines_text, image_url)).encode(),
        headers={
            "Authorization": f"Bearer {api_key()}",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=TIMEOUT_SECONDS) as response:
            body = json.loads(response.read())
    except urllib.error.HTTPError as error:
        detail = error.read().decode()[:400]
        raise AnnotationError(f"HTTP {error.code} : {detail}") from error
    except (urllib.error.URLError, TimeoutError) as error:
        raise AnnotationError(f"réseau : {error}") from error

    if "error" in body:
        raise AnnotationError(f"modèle : {body['error']}")
    content = body["choices"][0]["message"]["content"]
    if not content:
        raise AnnotationError("réponse vide")
    try:
        return json.loads(content)
    except json.JSONDecodeError as error:
        raise AnnotationError(f"JSON illisible : {content[:300]}") from error
