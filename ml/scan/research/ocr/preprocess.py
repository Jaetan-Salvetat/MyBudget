"""Prétraitement de la seconde passe OCR, miroir de `receipt_image_enhancer.dart`.

Mêmes constantes que l'app (autocontrast + unsharp + upscale 2400 px) pour
que le retry mesuré ici soit celui du device.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageFilter, ImageOps

RETRY_LONG_SIDE = 2400
UNSHARP_RADIUS = 2
UNSHARP_PERCENT = 150
UNSHARP_THRESHOLD = 0
JPEG_QUALITY = 90


def enhance(source: Path, destination: Path) -> Path:
    image = Image.open(source).convert("RGB")
    image = ImageOps.exif_transpose(image)
    long_side = max(image.width, image.height)
    if long_side < RETRY_LONG_SIDE:
        scale = RETRY_LONG_SIDE / long_side
        image = image.resize(
            (round(image.width * scale), round(image.height * scale)),
            Image.Resampling.BICUBIC,
        )
    image = ImageOps.autocontrast(image, cutoff=0)
    image = image.filter(
        ImageFilter.UnsharpMask(
            radius=UNSHARP_RADIUS, percent=UNSHARP_PERCENT, threshold=UNSHARP_THRESHOLD
        )
    )
    image.save(destination, "JPEG", quality=JPEG_QUALITY)
    return destination
