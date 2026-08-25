"""Un dump OCR complet (passe 1 + retry prétraité) pour une image du disque.

La page est remise d'aplomb entre les deux : la passe 1 sert aussi de sonde
d'orientation, et le dump retenu est celui d'un ticket droit.
"""

from __future__ import annotations

import tempfile
from pathlib import Path

from PIL import Image, ImageOps

from ocr.apple_vision import recognize
from ocr.orientation import upright_rotation
from ocr.preprocess import enhance

UPRIGHT_NAME = "upright.jpg"
RETRY_NAME = "retry.jpg"
JPEG_QUALITY = 95


def _rotated(source: Path, destination: Path, degrees: int) -> Path:
    image = ImageOps.exif_transpose(Image.open(source).convert("RGB"))
    image.rotate(degrees, expand=True).save(destination, "JPEG", quality=JPEG_QUALITY)
    return destination


def dump_for(image: Path, with_retry: bool = True) -> dict:
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
