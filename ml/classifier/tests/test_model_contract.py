"""Le seul défaut de ce projet qui ne se voit sur aucune métrique.

Ajouter une classe à `assets/categories.json` ne casse rien, ne lève rien, et
n'apparaît nulle part : les poids déjà entraînés répondent toujours, sur un
ordre de slugs qui n'existe plus. Chaque prédiction au-delà de la classe
insérée est décodée sous le nom de sa voisine. Le 31 août, `hard.py` est passé
de 87,9 % à 59,7 % pour cette seule raison, et l'ONNX publié portait le même
décalage dans l'app.

Trois artefacts doivent décrire les mêmes classes dans le même ordre : la
taxonomie, les poids entraînés, et la liste Dart qui traduit l'argmax.
"""

import json
import re

import pytest

from paths import MODEL_DIR, PROJECT_ROOT, TAXONOMY_PATH
from serving.contract import HeadMismatch, assert_category_head
from taxonomy import LABELS

DART_LABELS_PATH = PROJECT_ROOT / "lib/core/constants/quick_add_labels.dart"
ASSETS_MODELS_DIR = PROJECT_ROOT / "assets" / "models"
CATEGORY_OUTPUT = "category_logits"

_DART_LIST = re.compile(r"categories\s*=\s*\[(.*?)\]", re.DOTALL)
_DART_ENTRY = re.compile(r"'([^']+)'")


def dart_categories() -> list[str]:
    body = _DART_LIST.search(DART_LABELS_PATH.read_text(encoding="utf-8"))
    assert body, DART_LABELS_PATH
    return _DART_ENTRY.findall(body.group(1))


def shipped_onnx_paths() -> list:
    return sorted(ASSETS_MODELS_DIR.glob("model_v*.onnx"))


def test_assert_category_head_accepts_the_taxonomy_size():
    assert_category_head(len(LABELS), "test")


def test_assert_category_head_names_the_drift():
    with pytest.raises(HeadMismatch) as raised:
        assert_category_head(len(LABELS) - 2, "test")
    assert str(len(LABELS)) in str(raised.value)


def test_dart_decodes_the_argmax_with_the_taxonomy_order():
    """L'app traduit un index en slug : un ordre différent renomme tout."""
    assert dart_categories() == LABELS


def test_dart_labels_are_not_a_stale_copy_of_the_taxonomy_file():
    """La liste Dart est écrite à la main ; ce test est ce qui la tient à jour."""
    taxonomy = json.loads(TAXONOMY_PATH.read_text(encoding="utf-8"))
    groups = [group for section in ("expenses", "income") for group in taxonomy[section]]
    assert [slug.split(".", 1)[0] for slug in dart_categories()] == [
        slug.split(".", 1)[0] for slug in LABELS
    ]
    assert set(groups) == {slug.split(".", 1)[0] for slug in dart_categories()}


@pytest.mark.skipif(
    not (MODEL_DIR / "config.json").exists(), reason="aucun modèle entraîné localement"
)
def test_the_trained_weights_carry_one_output_per_class():
    config = json.loads((MODEL_DIR / "config.json").read_text(encoding="utf-8"))
    assert_category_head(config["num_categories"], str(MODEL_DIR / "config.json"))


@pytest.mark.skipif(not shipped_onnx_paths(), reason="aucun ONNX publié dans assets/")
@pytest.mark.parametrize("path", shipped_onnx_paths(), ids=lambda p: p.name)
def test_the_published_onnx_carries_one_output_per_class(path):
    import onnx

    graph = onnx.load(str(path), load_external_data=False).graph
    heads = {output.name: output for output in graph.output}
    assert CATEGORY_OUTPUT in heads, sorted(heads)
    dimensions = heads[CATEGORY_OUTPUT].type.tensor_type.shape.dim
    assert_category_head(dimensions[-1].dim_value, path.name)
