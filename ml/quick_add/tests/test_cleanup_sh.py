from __future__ import annotations

import subprocess
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[3] / "tool" / "cleanup.sh"


def write(path: Path, size_kb: int) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(b"0" * (size_kb * 1024))
    return path


def make_tree(tmp_path: Path) -> dict[str, Path]:
    ml = tmp_path / "ml"
    root = ml / "quick_add"
    output = root / "output"
    dataset = root / "dataset"
    hub = tmp_path / "hub"
    write(output / "best" / "model.safetensors", 600)
    write(output / "best_iter1" / "model.safetensors", 400)
    write(output / "checkpoint-100" / "optimizer.pt", 200)
    write(output / "checkpoint-2000" / "optimizer.pt", 300)
    write(root / "__pycache__" / "train.pyc", 8)
    write(root / ".venv" / "__pycache__" / "dep.pyc", 8)
    write(dataset / "entities.jsonl", 64)
    write(dataset / "train.jsonl", 128)
    write(dataset / "eval.jsonl", 32)
    write(dataset / "cache" / "nsi.json", 96)
    write(hub / "models--jhu-clsp--mmBERT-small" / "blob", 1024)
    return {"ml": ml, "root": root, "output": output, "dataset": dataset, "hub": hub}


def run(tree: dict[str, Path], *args: str) -> subprocess.CompletedProcess[str]:
    env = {
        "PATH": "/usr/bin:/bin:/usr/sbin:/sbin",
        "HOME": str(tree["ml"].parent),
        "ML_ROOT": str(tree["ml"]),
        "ML_HF_CACHE_DIR": str(tree["hub"]),
    }
    return subprocess.run(
        [str(SCRIPT), *args], env=env, capture_output=True, text=True, check=True
    )


def test_dry_run_lists_caches_and_checkpoints_without_deleting(tmp_path: Path) -> None:
    tree = make_tree(tmp_path)

    result = run(tree)

    assert "__pycache__" in result.stdout
    assert "checkpoint-100" in result.stdout
    assert "checkpoint-2000" in result.stdout
    assert (tree["output"] / "checkpoint-100").exists()
    assert (tree["root"] / "__pycache__").exists()


def test_dry_run_never_targets_the_published_artefacts(tmp_path: Path) -> None:
    tree = make_tree(tmp_path)

    result = run(tree, "--datasets", "--backups", "--hf-cache")

    assert "output/best\n" not in result.stdout
    assert "entities.jsonl" not in result.stdout
    assert "dataset/cache" not in result.stdout


def test_venv_caches_are_left_alone(tmp_path: Path) -> None:
    tree = make_tree(tmp_path)

    result = run(tree)

    assert ".venv" not in result.stdout


def test_apply_deletes_checkpoints_and_keeps_best(tmp_path: Path) -> None:
    tree = make_tree(tmp_path)

    run(tree, "--apply")

    assert not (tree["output"] / "checkpoint-100").exists()
    assert not (tree["output"] / "checkpoint-2000").exists()
    assert not (tree["root"] / "__pycache__").exists()
    assert (tree["output"] / "best" / "model.safetensors").exists()
    assert (tree["output"] / "best_iter1").exists()


def test_keep_checkpoints_preserves_the_most_recent_steps(tmp_path: Path) -> None:
    tree = make_tree(tmp_path)

    run(tree, "--keep-checkpoints", "1", "--apply")

    assert not (tree["output"] / "checkpoint-100").exists()
    assert (tree["output"] / "checkpoint-2000").exists()


def test_stale_onnx_export_is_removed_but_a_fresh_one_is_kept(tmp_path: Path) -> None:
    tree = make_tree(tmp_path)
    export = write(tree["output"] / "model.onnx", 135)
    weights = tree["output"] / "best" / "model.safetensors"

    subprocess.run(["touch", "-t", "202601010000", str(export)], check=True)
    subprocess.run(["touch", "-t", "202602010000", str(weights)], check=True)
    run(tree, "--apply")
    assert not export.exists()

    export = write(tree["output"] / "model.onnx", 135)
    subprocess.run(["touch", "-t", "202603010000", str(export)], check=True)
    run(tree, "--apply")
    assert export.exists()


def test_backups_flag_is_required_to_drop_previous_runs(tmp_path: Path) -> None:
    tree = make_tree(tmp_path)

    run(tree, "--backups", "--apply")

    assert not (tree["output"] / "best_iter1").exists()
    assert (tree["output"] / "best").exists()


def test_datasets_flag_drops_only_the_regenerable_splits(tmp_path: Path) -> None:
    tree = make_tree(tmp_path)

    run(tree, "--datasets", "--apply")

    assert not (tree["dataset"] / "train.jsonl").exists()
    assert not (tree["dataset"] / "eval.jsonl").exists()
    assert (tree["dataset"] / "entities.jsonl").exists()
    assert (tree["dataset"] / "cache" / "nsi.json").exists()


def test_hf_cache_flag_drops_the_downloaded_backbone(tmp_path: Path) -> None:
    tree = make_tree(tmp_path)

    run(tree, "--hf-cache", "--apply")

    assert not (tree["hub"] / "models--jhu-clsp--mmBERT-small").exists()


def test_min_free_already_satisfied_deletes_nothing(tmp_path: Path) -> None:
    tree = make_tree(tmp_path)

    result = run(tree, "--min-free", "0.000001", "--apply")

    assert (tree["output"] / "checkpoint-100").exists()
    assert "rien" in result.stdout


def test_running_training_protects_checkpoints(tmp_path: Path) -> None:
    tree = make_tree(tmp_path)
    training = subprocess.Popen(["/bin/sh", "-c", "exec -a 'python train.py' sleep 5"])
    try:
        result = run(tree, "--apply")
    finally:
        training.terminate()
        training.wait()

    assert (tree["output"] / "checkpoint-100").exists()
    assert "entrainement en cours" in result.stdout
    assert not (tree["root"] / "__pycache__").exists()


def test_every_ml_project_is_swept(tmp_path: Path) -> None:
    tree = make_tree(tmp_path)
    other = tree["ml"] / "price_parser"
    write(other / "output" / "checkpoint-10" / "optimizer.pt", 50)

    run(tree, "--apply")

    assert not (other / "output" / "checkpoint-10").exists()


def test_a_project_argument_restricts_the_sweep(tmp_path: Path) -> None:
    tree = make_tree(tmp_path)
    other = tree["ml"] / "price_parser"
    write(other / "output" / "checkpoint-10" / "optimizer.pt", 50)

    run(tree, "price_parser", "--apply")

    assert not (other / "output" / "checkpoint-10").exists()
    assert (tree["output"] / "checkpoint-100").exists()


def test_an_unknown_project_is_rejected(tmp_path: Path) -> None:
    tree = make_tree(tmp_path)

    result = subprocess.run(
        [str(SCRIPT), "absent"],
        env={
            "PATH": "/usr/bin:/bin:/usr/sbin:/sbin",
            "HOME": str(tree["ml"].parent),
            "ML_ROOT": str(tree["ml"]),
            "ML_HF_CACHE_DIR": str(tree["hub"]),
        },
        capture_output=True,
        text=True,
    )

    assert result.returncode == 2
    assert "projet inconnu" in result.stderr


def test_a_project_without_training_artefacts_does_not_break_the_sweep(tmp_path: Path) -> None:
    tree = make_tree(tmp_path)
    write(tree["ml"] / "price_parser" / "lib" / "parser.dart", 4)

    run(tree, "--datasets", "--backups", "--hf-cache", "--apply")

    assert not (tree["output"] / "checkpoint-100").exists()
    assert (tree["ml"] / "price_parser" / "lib" / "parser.dart").exists()
