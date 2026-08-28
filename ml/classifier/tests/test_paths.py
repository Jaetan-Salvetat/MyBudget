"""L'artefact publie doit etre l'export des poids livres.

`registry.env` designait `output/model.onnx` pendant que l'export d'un run
nomme atterrissait dans `output/<run>/model.onnx` : cinq versions ont ete
publiees depuis un export perime sans qu'aucun chemin ne soit faux. Le lien
entre les poids et leur ONNX est desormais structurel, et c'est ce que ce test
tient.
"""

from __future__ import annotations

from pathlib import Path

from paths import MODEL_DIR, ONNX_PATH, PROJECT_ROOT

REGISTRY = PROJECT_ROOT / "tool" / "models" / "registry.env"


def quick_add_source() -> str:
    for line in REGISTRY.read_text(encoding="utf-8").splitlines():
        entry = line.strip().strip('"')
        if entry.startswith("quick_add|"):
            return entry.rsplit("|", 1)[1]
    raise AssertionError("aucune entree quick_add dans registry.env")


def test_the_export_sits_with_the_weights_it_comes_from() -> None:
    assert ONNX_PATH.parent == MODEL_DIR


def test_the_published_source_is_the_export_of_the_shipped_weights() -> None:
    assert quick_add_source() == str(ONNX_PATH.relative_to(PROJECT_ROOT))
