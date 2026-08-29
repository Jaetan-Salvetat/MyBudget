"""Invariants de `tool/ml_data/{publish,fetch}.sh`, sans reseau.

Les corpus d'entrainement vivent dans un depot Hugging Face prive. Une
publication les synchronise, donc elle SUPPRIME cote distant ce qui a disparu
en local : un corpus absent de la machine qui publie ne doit jamais valoir un
corpus vide. C'est la l'invariant central, le reste tient l'epinglage.
"""

from __future__ import annotations

import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[3]
PUBLISH = ROOT / "tool" / "ml_data" / "publish.sh"
FETCH = ROOT / "tool" / "ml_data" / "fetch.sh"

REGISTRY = """\
REPOSITORY=owner/corpus
FOLDER_LIMIT=10
EXCLUDED="*.log"
SUBSETS=(
  "annotations|scan/data/annotations|corpus annote"
  "images|scan/data/corpus/photos_pixel scan/data/corpus/mixed|photos triees"
  "open_prices|scan/data/raw/open_prices.parquet|dump fige"
)
"""

PINNED = "abc123"
PUBLISHED = "def456"


def write(path: Path, content: str) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    return path


def make_root(tmp_path: Path) -> Path:
    """Un depot ou les trois corpus sont presents et le lock epingle."""
    root = tmp_path / "repo"
    write(root / "tool" / "ml_data" / "registry.env", REGISTRY)
    write(
        root / "tool" / "ml_data" / "lock.env",
        f"DATA_REPOSITORY=owner/corpus\nDATA_REVISION={PINNED}\n",
    )
    write(root / "ml" / "scan" / "data" / "annotations" / "op" / "0.json", "{}")
    write(root / "ml" / "scan" / "data" / "corpus" / "photos_pixel" / "0.jpg", "x")
    write(root / "ml" / "scan" / "data" / "corpus" / "mixed" / "0.jpg", "x")
    write(root / "ml" / "scan" / "data" / "raw" / "open_prices.parquet", "x")

    stub = write(
        root / "bin" / "hf",
        "#!/bin/sh\n"
        'echo "$@" >> "$HF_LOG"\n'
        "echo '{\"url\": \"https://huggingface.co/datasets/owner/corpus"
        f"/commit/{PUBLISHED}\"}}'\n",
    )
    stub.chmod(0o755)
    return root


def run(script: Path, root: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [str(script), *args],
        env={
            "PATH": f"{root / 'bin'}:/usr/bin:/bin:/usr/sbin:/sbin",
            "HOME": str(root),
            "HF_LOG": str(root / "hf.log"),
            "ML_DATA_ROOT": str(root),
        },
        capture_output=True,
        text=True,
    )


def calls(root: Path) -> list[str]:
    log = root / "hf.log"
    return log.read_text().splitlines() if log.exists() else []


def lock(root: Path) -> str:
    return (root / "tool" / "ml_data" / "lock.env").read_text()


# Publier synchronise : `--delete` efface cote distant ce qui manque en local.
# Un corpus qu'on n'a pas fetche est donc une bombe — sans ce garde-fou, un
# `publish.sh` lance apres un clone frais viderait le depot.
def test_a_missing_corpus_stops_the_publication(tmp_path: Path) -> None:
    root = make_root(tmp_path)
    for path in (root / "ml" / "scan" / "data" / "annotations").rglob("*.json"):
        path.unlink()
    (root / "ml" / "scan" / "data" / "annotations" / "op").rmdir()
    (root / "ml" / "scan" / "data" / "annotations").rmdir()

    result = run(PUBLISH, root)

    assert result.returncode == 66
    assert "scan/data/annotations" in result.stderr
    assert calls(root) == []


# Hugging Face refuse plus de 10 000 entrees dans un dossier. Le refus distant
# arrive apres des minutes d'envoi : mieux vaut le meme refus, ici, en une
# seconde.
def test_a_folder_over_the_entry_limit_is_refused_before_sending(
    tmp_path: Path,
) -> None:
    root = make_root(tmp_path)
    crowded = root / "ml" / "scan" / "data" / "corpus" / "photos_pixel"
    for index in range(12):
        write(crowded / f"{index}.jpg", "x")

    result = run(PUBLISH, root, "images")

    assert result.returncode == 65
    assert "photos_pixel" in result.stderr
    assert calls(root) == []


def test_a_dry_run_sends_nothing_and_leaves_the_lock_alone(tmp_path: Path) -> None:
    root = make_root(tmp_path)

    result = run(PUBLISH, root, "--dry-run")

    assert result.returncode == 0, result.stderr
    assert calls(root) == []
    assert PINNED in lock(root)
    for name in ("annotations", "images", "open_prices"):
        assert name in result.stdout


def test_publishing_one_corpus_leaves_the_others_untouched(tmp_path: Path) -> None:
    root = make_root(tmp_path)

    result = run(PUBLISH, root, "annotations")

    assert result.returncode == 0, result.stderr
    assert len(calls(root)) == 1
    assert "scan/data/annotations" in calls(root)[0]
    assert "photos_pixel" not in calls(root)[0]


def test_a_corpus_of_several_paths_sends_them_all(tmp_path: Path) -> None:
    root = make_root(tmp_path)

    run(PUBLISH, root, "images")

    sent = " ".join(calls(root))
    assert "scan/data/corpus/photos_pixel" in sent
    assert "scan/data/corpus/mixed" in sent


def test_an_unknown_corpus_is_refused(tmp_path: Path) -> None:
    result = run(PUBLISH, make_root(tmp_path), "checkpoints")

    assert result.returncode == 64
    assert "checkpoints" in result.stderr


# Sans `--delete`, un fichier retire du corpus survivrait indefiniment cote
# distant, et un clone frais recupererait un corpus que plus personne n'a.
def test_the_upload_mirrors_deletions(tmp_path: Path) -> None:
    root = make_root(tmp_path)

    run(PUBLISH, root, "annotations")

    assert "--delete" in calls(root)[0]


# `hf upload` recree un depot absent, et le cree PUBLIC par defaut. Les
# licences des sources s'arretent a la recherche : un depot recree en public
# les redistribuerait, sans que rien ne le dise.
def test_the_upload_never_lets_the_repository_become_public(tmp_path: Path) -> None:
    root = make_root(tmp_path)

    run(PUBLISH, root, "annotations")

    assert "--private" in calls(root)[0]


# `hf upload` ignore --delete et --exclude pour un fichier seul, et le dit a
# chaque publication. Un avertissement qu'on apprend a ignorer est un
# avertissement de moins qui sera lu le jour ou il compte.
def test_a_single_file_corpus_is_sent_without_folder_options(tmp_path: Path) -> None:
    root = make_root(tmp_path)

    run(PUBLISH, root, "open_prices")

    assert "--delete" not in calls(root)[0]
    assert "--exclude" not in calls(root)[0]


def test_the_lock_pins_the_revision_the_upload_returned(tmp_path: Path) -> None:
    root = make_root(tmp_path)

    run(PUBLISH, root, "annotations")

    assert f"DATA_REVISION={PUBLISHED}" in lock(root)
    assert PINNED not in lock(root)


def test_the_fetch_asks_for_the_pinned_revision(tmp_path: Path) -> None:
    root = make_root(tmp_path)

    result = run(FETCH, root, "annotations")

    assert result.returncode == 0, result.stderr
    assert f"--revision {PINNED}" in calls(root)[0]


def test_the_fetch_of_one_corpus_asks_for_its_paths_only(tmp_path: Path) -> None:
    root = make_root(tmp_path)

    run(FETCH, root, "annotations")

    assert "scan/data/annotations" in calls(root)[0]
    assert "photos_pixel" not in calls(root)[0]


# Un corpus est un dossier, `open_prices` est un fichier : demander
# `open_prices.parquet/*` ne ramenerait rien, en silence.
def test_a_single_file_corpus_is_asked_for_by_name(tmp_path: Path) -> None:
    root = make_root(tmp_path)

    run(FETCH, root, "open_prices")

    assert "scan/data/raw/open_prices.parquet" in calls(root)[0]
    assert "open_prices.parquet/*" not in calls(root)[0]


def test_a_lock_without_a_revision_stops_the_fetch(tmp_path: Path) -> None:
    root = make_root(tmp_path)
    write(root / "tool" / "ml_data" / "lock.env", "DATA_REPOSITORY=owner/corpus\n")

    result = run(FETCH, root)

    assert result.returncode == 65
    assert "lock.env" in result.stderr
    assert calls(root) == []


@pytest.mark.parametrize("script", [PUBLISH, FETCH])
def test_the_scripts_are_executable(script: Path) -> None:
    assert script.exists(), script
    assert script.stat().st_mode & 0o111
