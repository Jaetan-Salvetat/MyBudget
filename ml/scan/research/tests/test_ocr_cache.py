"""Rangement du cache OCR.

Le cache grossit de deux dumps par image et ne se vide jamais : à plat, il
finissait par heurter la limite dure de 10 000 entrées par dossier du dépôt
qui l'héberge. Le préfixe de l'empreinte le répartit, et les deux passes
d'une même image restent voisines.
"""

from __future__ import annotations

import json
from collections import Counter
from pathlib import Path

import pytest

from bench import photos_raw
from ocr import pipeline

SHARD_LIMIT = 10_000


@pytest.fixture
def cache(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> Path:
    monkeypatch.setattr(pipeline, "CACHE_DIR", tmp_path / "ocr_cache")
    return tmp_path


def image_of(cache: Path, content: bytes) -> Path:
    path = cache / f"{content.hex()}.jpg"
    path.write_bytes(content)
    return path


def test_aucun_dump_ne_se_pose_a_plat(cache: Path) -> None:
    path = pipeline.cache_path(image_of(cache, b"ticket"), with_retry=False)

    assert path.parent != pipeline.CACHE_DIR
    assert path.parent.parent == pipeline.CACHE_DIR


def test_les_deux_passes_d_une_image_partagent_leur_dossier(cache: Path) -> None:
    image = image_of(cache, b"ticket")

    first = pipeline.cache_path(image, with_retry=False)
    retry = pipeline.cache_path(image, with_retry=True)

    assert first.parent == retry.parent
    assert first != retry


def test_deux_images_differentes_ne_partagent_pas_leur_nom(cache: Path) -> None:
    """La clé porte le contenu : une photo remplacée invalide son entrée."""
    first = pipeline.cache_path(image_of(cache, b"ticket"), with_retry=False)
    second = pipeline.cache_path(image_of(cache, b"autre"), with_retry=False)

    assert first.name != second.name


def test_le_cache_se_repartit_assez_pour_tenir_sous_la_limite(cache: Path) -> None:
    """Le cache actuel pèse ~6 000 dumps et n'est jamais purgé."""
    paths = [
        pipeline.cache_path(image_of(cache, f"ticket {index}".encode()), retry)
        for index in range(1_000)
        for retry in (False, True)
    ]

    shards = Counter(path.parent for path in paths)

    assert len(shards) > 100
    assert max(shards.values()) < SHARD_LIMIT // 100


def test_un_dump_range_en_sous_dossier_reste_trouvable(
    cache: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setattr(photos_raw, "RESULTS_DIR", cache)
    path = pipeline.cache_path(image_of(cache, b"ticket"), with_retry=False)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps({"image": "op_0000445.jpg", "blocks": []}))

    assert photos_raw.raw_dumps() == {"op_0000445": path}
