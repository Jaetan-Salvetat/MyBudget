"""Rend un ticket en image, puis simule une photo de téléphone.

Trois niveaux de dégradation : `clean` (scan parfait), `photo` (photo tenue en
main : rotation, perspective, ombre, léger flou), `hard` (thermique pâli,
photo sombre, flou plus marqué). Les niveaux encadrent ce que produiront les
utilisateurs réels.
"""

from __future__ import annotations

import random
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

FONT_PATHS = [
    "/System/Library/Fonts/Supplemental/Courier New Bold.ttf",
    "/System/Library/Fonts/Supplemental/Courier New.ttf",
    "/System/Library/Fonts/Supplemental/Andale Mono.ttf",
    "/System/Library/Fonts/Supplemental/PTMono.ttc",
]
FONT_SIZE = 28
LINE_SPACING = 8
MARGIN = 36
PAPER_COLOR = (252, 250, 246)
INK_COLOR = (40, 38, 36)


def render_paper(lines: list[str], rng: random.Random | None = None) -> Image.Image:
    font_path = FONT_PATHS[0] if rng is None else rng.choice(FONT_PATHS)
    font = ImageFont.truetype(font_path, FONT_SIZE)
    char_width = font.getbbox("0")[2]
    line_height = FONT_SIZE + LINE_SPACING
    width = char_width * max(len(line) for line in lines) + 2 * MARGIN
    height = line_height * len(lines) + 2 * MARGIN
    image = Image.new("RGB", (width, height), PAPER_COLOR)
    draw = ImageDraw.Draw(image)
    for index, line in enumerate(lines):
        draw.text((MARGIN, MARGIN + index * line_height), line, font=font, fill=INK_COLOR)
    return image


def simulate_photo(paper: Image.Image, level: str, rng: random.Random) -> Image.Image:
    if level == "clean":
        return paper
    if level == "photo":
        return _photo(paper, rng, fade=False)
    if level == "hard":
        return _photo(paper, rng, fade=True)
    raise ValueError(f"Unknown degradation level: {level}")


def _photo(paper: Image.Image, rng: random.Random, fade: bool) -> Image.Image:
    image = paper
    if fade:
        image = ImageEnhance.Contrast(image).enhance(rng.uniform(0.45, 0.65))
        image = ImageEnhance.Brightness(image).enhance(rng.uniform(1.0, 1.1))
        image = _crumple(image, rng)
    image = _on_background(image, rng)
    image = _perspective(image, rng)
    image = image.rotate(
        rng.uniform(-4.0, 4.0),
        resample=Image.Resampling.BICUBIC,
        expand=False,
        fillcolor=_background_color(rng),
    )
    image = _shadow_gradient(image, rng)
    blur_radius = rng.uniform(0.6, 1.4) if fade else rng.uniform(0.3, 0.9)
    image = image.filter(ImageFilter.GaussianBlur(blur_radius))
    image = _sensor_noise(image, rng)
    return image


def _on_background(paper: Image.Image, rng: random.Random) -> Image.Image:
    pad_x = int(paper.width * rng.uniform(0.08, 0.2))
    pad_y = int(paper.height * rng.uniform(0.04, 0.1))
    canvas = Image.new(
        "RGB",
        (paper.width + 2 * pad_x, paper.height + 2 * pad_y),
        _background_color(rng),
    )
    canvas.paste(paper, (pad_x, pad_y))
    return canvas


def _background_color(rng: random.Random) -> tuple[int, int, int]:
    base = rng.choice([(120, 96, 76), (86, 88, 92), (150, 140, 128), (60, 58, 60)])
    jitter = rng.randint(-10, 10)
    return tuple(max(0, min(255, channel + jitter)) for channel in base)


def _perspective(image: Image.Image, rng: random.Random) -> Image.Image:
    width, height = image.size
    shift = width * rng.uniform(0.01, 0.05)
    source = [(0, 0), (width, 0), (width, height), (0, height)]
    target = [
        (rng.uniform(0, shift), rng.uniform(0, shift)),
        (width - rng.uniform(0, shift), rng.uniform(0, shift)),
        (width - rng.uniform(0, shift), height - rng.uniform(0, shift)),
        (rng.uniform(0, shift), height - rng.uniform(0, shift)),
    ]
    coefficients = _perspective_coefficients(target, source)
    return image.transform(
        (width, height),
        Image.Transform.PERSPECTIVE,
        coefficients,
        resample=Image.Resampling.BICUBIC,
        fillcolor=_background_color(rng),
    )


def _perspective_coefficients(
    source: list[tuple[float, float]],
    target: list[tuple[float, float]],
) -> list[float]:
    matrix = []
    vector = []
    for (sx, sy), (tx, ty) in zip(source, target):
        matrix.append([tx, ty, 1, 0, 0, 0, -sx * tx, -sx * ty])
        matrix.append([0, 0, 0, tx, ty, 1, -sy * tx, -sy * ty])
        vector.extend([sx, sy])
    solution = np.linalg.solve(np.array(matrix, dtype=float), np.array(vector, dtype=float))
    return solution.tolist()


def _shadow_gradient(image: Image.Image, rng: random.Random) -> Image.Image:
    array = np.asarray(image).astype(np.float32)
    height, width = array.shape[:2]
    horizontal = np.linspace(
        rng.uniform(0.82, 1.0), rng.uniform(0.82, 1.0), width, dtype=np.float32
    )
    vertical = np.linspace(
        rng.uniform(0.85, 1.0), rng.uniform(0.85, 1.0), height, dtype=np.float32
    )
    array *= vertical[:, None, None] * horizontal[None, :, None]
    return Image.fromarray(np.clip(array, 0, 255).astype(np.uint8))


def _crumple(image: Image.Image, rng: random.Random) -> Image.Image:
    """Ondulation verticale locale : approxime un ticket froissé dont les
    lignes ne sont plus droites, le cas qui décale libellés et prix."""
    array = np.asarray(image)
    width = array.shape[1]
    xs = np.arange(width, dtype=np.float32)
    amplitude = rng.uniform(2.0, 6.0)
    period = rng.uniform(0.5, 1.5) * width
    phase = rng.uniform(0, 2 * np.pi)
    offsets = (amplitude * np.sin(2 * np.pi * xs / period + phase)).astype(int)
    warped = np.empty_like(array)
    for x in range(width):
        warped[:, x] = np.roll(array[:, x], offsets[x], axis=0)
    return Image.fromarray(warped)


def _sensor_noise(image: Image.Image, rng: random.Random) -> Image.Image:
    array = np.asarray(image).astype(np.float32)
    noise = np.random.default_rng(rng.randint(0, 2**31)).normal(
        0, rng.uniform(1.5, 4.0), array.shape
    )
    return Image.fromarray(np.clip(array + noise, 0, 255).astype(np.uint8))


def save_jpeg(image: Image.Image, path: Path, quality: int = 85) -> None:
    image.save(path, format="JPEG", quality=quality)
