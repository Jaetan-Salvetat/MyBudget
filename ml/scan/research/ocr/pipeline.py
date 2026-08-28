"""Un dump OCR complet (passe 1 + retry prétraité) pour une image du disque.

La page est remise d'aplomb entre les deux : la passe 1 sert aussi de sonde
d'orientation, et le dump retenu est celui d'un ticket droit.
"""

from __future__ import annotations

import hashlib
import json
import tempfile
from pathlib import Path

from PIL import Image, ImageOps

from ocr.apple_vision import recognize
from ocr.orientation import upright_rotation
from ocr.preprocess import enhance
from paths import DATA_DIR

# L'OCR est tout le coût d'un bench : deux passes Vision sur une photo de
# 30+ Mpx. Le cache le rend gratuit à partir du second passage, ce qui permet
# de calibrer un seuil en minutes au lieu d'heures. La clé porte le contenu de
# l'image, pas son nom : une photo remplacée invalide son entrée.
CACHE_DIR = DATA_DIR / "results" / "ocr_cache"

UPRIGHT_NAME = "upright.jpg"
RETRY_NAME = "retry.jpg"
JPEG_QUALITY = 95


def _rotated(source: Path, destination: Path, degrees: int) -> Path:
    image = ImageOps.exif_transpose(Image.open(source).convert("RGB"))
    image.rotate(degrees, expand=True).save(destination, "JPEG", quality=JPEG_QUALITY)
    return destination


def _cache_path(image: Path, with_retry: bool) -> Path:
    digest = hashlib.sha256(image.read_bytes()).hexdigest()[:32]
    return CACHE_DIR / f"{digest}{'_retry' if with_retry else ''}.json"


def dump_for(image: Path, with_retry: bool = True, cache: bool = True) -> dict:
    """Dump OCR de l'image, servi depuis le cache quand il existe."""
    if cache:
        cached = _cache_path(image, with_retry)
        if cached.exists():
            return json.loads(cached.read_text())
        dump = _recognize_both(image, with_retry)
        cached.parent.mkdir(parents=True, exist_ok=True)
        cached.write_text(json.dumps(dump))
        return dump
    return _recognize_both(image, with_retry)


def _recognize_both(image: Path, with_retry: bool) -> dict:
    """Dump OCR de l'image remise droite. Le retry prétraité est le second
    OCR du flow : inutile quand on ne veut que lire la page une fois."""
    with tempfile.TemporaryDirectory() as directory:
        upright = image
        dump = recognize(str(image))
        rotation = upright_rotation(dump)
        if rotation:
            upright = _rotated(image, Path(directory) / UPRIGHT_NAME, rotation)
            dump = recognize(str(upright))
        if with_retry:
            dump["ocrRetry"] = recognize(
                str(enhance(upright, Path(directory) / RETRY_NAME))
            )
            dump["ocrRetry"]["image"] = image.name
    dump["image"] = image.name
    dump["rotationApplied"] = rotation
    return dump
