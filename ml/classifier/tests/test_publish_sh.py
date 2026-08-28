"""Invariants de `tool/models/publish.sh`, en essai a blanc.

Le quick-add est reste cinq versions sur les memes octets sans que rien ne le
signale : la source pointait un export perime, et le script ne disait pas d'ou
il publiait. Ce que ces tests tiennent, c'est la visibilite — chaque modele
annonce sa source et si son contenu bouge.
"""

from __future__ import annotations

import subprocess
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[3] / "tool" / "models" / "publish.sh"

REGISTRY = """\
MODELS=(
  "quick_add|model_%s.onnx|ml/classifier/output/best/model.onnx"
  "line_roles|line_roles_%s.json|ml/scan/research/models/line_roles.json"
)
TOKENIZER_SOURCE_DEFAULT=ml/classifier/output/best/tokenizer.json
REPOSITORY=owner/repo
ASSETS_DIR=assets/models
"""


def write(path: Path, content: str) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    return path


def checksum(path: Path) -> str:
    out = subprocess.run(
        ["shasum", "-a", "256", str(path)], capture_output=True, text=True, check=True
    )
    return out.stdout.split()[0]


def make_root(tmp_path: Path, *, quick_add: str = "poids v10") -> Path:
    root = tmp_path / "repo"
    write(root / "tool" / "models" / "registry.env", REGISTRY)
    quick_add_source = write(root / "ml" / "classifier" / "output" / "best" / "model.onnx", quick_add)
    roles_source = write(root / "ml" / "scan" / "research" / "models" / "line_roles.json", "roles v10")
    write(root / "assets" / "models" / "model_v9.onnx", "poids v9")
    write(root / "assets" / "models" / "line_roles_v9.json", "roles v9")
    write(
        root / "tool" / "models" / "lock.env",
        "REPOSITORY=owner/repo\n"
        "RELEASE=models-v9\n"
        "QUICK_ADD_ASSET=model_v9.onnx\n"
        f"QUICK_ADD_SHA256={checksum(quick_add_source)}\n"
        "LINE_ROLES_ASSET=line_roles_v9.json\n"
        f"LINE_ROLES_SHA256={checksum(roles_source)}\n",
    )
    return root


def run(root: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [str(SCRIPT), "--dry-run", *args],
        env={"PATH": "/usr/bin:/bin:/usr/sbin:/sbin", "HOME": str(root), "MODELS_ROOT": str(root)},
        capture_output=True,
        text=True,
    )


def line_of(output: str, model_id: str) -> str:
    for line in output.splitlines():
        if line.strip().startswith(model_id):
            return line
    raise AssertionError(f"aucune ligne pour {model_id} dans :\n{output}")


def test_the_next_version_comes_from_the_pinned_assets(tmp_path: Path) -> None:
    result = run(make_root(tmp_path))

    assert result.returncode == 0, result.stderr
    assert "models-v10" in result.stdout
    assert "model_v10.onnx" in result.stdout


def test_a_source_identical_to_the_published_version_is_called_out(tmp_path: Path) -> None:
    root = make_root(tmp_path)
    (root / "ml" / "scan" / "research" / "models" / "line_roles.json").write_text("roles v11")

    result = run(root)

    assert "INCHANGE" in line_of(result.stdout, "quick_add")
    assert "INCHANGE" not in line_of(result.stdout, "line_roles")


def test_the_unchanged_models_are_summarised_after_the_table(tmp_path: Path) -> None:
    result = run(make_root(tmp_path))

    assert "quick_add" in result.stdout.split("INCHANGES")[-1]
    assert "line_roles" in result.stdout.split("INCHANGES")[-1]


def test_each_model_announces_the_file_it_publishes(tmp_path: Path) -> None:
    result = run(make_root(tmp_path))

    assert "ml/classifier/output/best/model.onnx" in line_of(result.stdout, "quick_add")


def test_a_model_without_a_training_output_is_carried_over(tmp_path: Path) -> None:
    root = make_root(tmp_path)
    (root / "ml" / "scan" / "research" / "models" / "line_roles.json").unlink()

    result = run(root)

    assert result.returncode == 0, result.stderr
    assert "line_roles_v9.json" in line_of(result.stdout, "line_roles")


def test_a_model_with_neither_source_nor_asset_stops_the_publication(tmp_path: Path) -> None:
    root = make_root(tmp_path)
    (root / "ml" / "scan" / "research" / "models" / "line_roles.json").unlink()
    (root / "assets" / "models" / "line_roles_v9.json").unlink()

    result = run(root)

    assert result.returncode == 66
    assert "line_roles" in result.stderr


def test_a_dry_run_leaves_the_assets_untouched(tmp_path: Path) -> None:
    root = make_root(tmp_path)

    run(root)

    assert (root / "assets" / "models" / "model_v9.onnx").exists()
    assert not (root / "assets" / "models" / "model_v10.onnx").exists()
