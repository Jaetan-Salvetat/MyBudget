"""Entraîne le tagger de spans : quels mots de cette ligne forment le libellé ?

La ligne est désignée par le modèle de lien ; ce qui restait réglé à la main,
c'est le découpage à l'intérieur — une coupe verticale unique plus quatre
expressions régulières. Mesuré sur T1-test, 78 % des libellés faux venaient
de là : un code article devant, une quantité ou un prix unitaire derrière,
sur la bonne ligne.

La vérité est l'alignement du nom de l'article sur les mots de sa ligne
(`truth/spans.py`), et seuls les alignements sûrs entrent : ce que l'OCR a
abîmé n'enseignerait qu'une frontière inventée.

Le nom vient de l'**annotation**. Tant qu'il n'y était pas, seul le golden
FindIt en portait, et ce modèle n'avait donc vu qu'une chaîne de magasins.
Mesuré sur T1-test avant ce changement : 10,7 % de libellés faux sur
l'enseigne d'entraînement, **19,6 % sur toute autre**. Le découpage dépend
des colonnes qu'imprime l'enseigne, et il en connaissait une.

Les lignes viennent du corpus lui-même — aucun OCR à relancer : elles sont
exactement ce que le modèle verra en production.

    uv run python -m line_classifier.train_span
"""

from __future__ import annotations

import json
from concurrent.futures import ProcessPoolExecutor
from dataclasses import dataclass
from pathlib import Path

import joblib
import numpy as np
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.metrics import classification_report

from annotate.dataset import AnnotatedReceipt, load
from ocr.pipeline import dump_for
from paths import FINDIT_DIR, GOLDEN_DIR, MODELS_DIR, SPAN_MODEL_PATH
from reference.local_flow import clustered_lines
from reference.spans_ml import best_span
from reference.word_features import featurize
from truth.golden import balances
from truth.spans import spans_from_annotation, spans_from_golden

TRAIN_SPLIT = "T1-train"
TEST_SPLIT = "T1-test"


@dataclass(frozen=True)
class LabelledLine:
    """Une ligne dont on sait quels mots nomment l'article."""

    features: list[list[float]]
    words: list[str]
    span: tuple[int, int]


def _lines_of(receipt: AnnotatedReceipt) -> list[LabelledLine]:
    spans = spans_from_annotation(receipt)
    if not spans:
        return []
    rows = featurize(receipt.lines)
    return [
        LabelledLine(
            features=rows[index],
            words=[word.text for word in receipt.lines[index].words],
            span=(start, end),
        )
        for index, start, end in spans
        if index < len(rows)
    ]


def labelled() -> list[LabelledLine]:
    """Les deux sources réunies, et il faut les deux.

    L'annotation apporte 337 enseignes mais ne couvre pas FindIt ; le golden
    couvre FindIt et rien d'autre. Entraîné sur la seule annotation, le modèle
    tombe à 90,3 % d'intervalles exacts sur T1-test là où le modèle FindIt
    faisait 96,0 % — le même écart de domaine, vu de l'autre côté.

    Sont pris aussi les tickets écartés pour un montant illisible : le
    checksum protège les montants, pas les libellés, et ces tickets-là portent
    justement les découpages rares."""
    return [
        *(line for receipt in load(roles_only=True) for line in _lines_of(receipt)),
        *_golden_split(TRAIN_SPLIT),
    ]


def _golden_split(split: str) -> list[LabelledLine]:
    images = sorted((FINDIT_DIR / split / "img").glob("*.jpg"))
    with ProcessPoolExecutor() as pool:
        return [line for batch in pool.map(_golden_lines_of, images) for line in batch]


def _golden_lines_of(image: Path) -> list[LabelledLine]:
    golden_path = GOLDEN_DIR / image.parent.parent.name / f"{image.stem}.json"
    if not golden_path.exists():
        return []
    golden = json.loads(golden_path.read_text())["receipt"]
    if not balances(golden):
        return []
    lines = clustered_lines(dump_for(image))
    spans = spans_from_golden(lines, golden["items"])
    if not spans:
        return []
    rows = featurize(lines)
    return [
        LabelledLine(
            features=rows[index],
            words=[word.text for word in lines[index].words],
            span=(start, end),
        )
        for index, start, end in spans
        if index < len(rows)
    ]


def held_out() -> list[LabelledLine]:
    """L'évaluation vient du golden de T1-test, jamais de l'annotation."""
    return _golden_split(TEST_SPLIT)


def dataset(lines: list[LabelledLine]) -> tuple[np.ndarray, np.ndarray]:
    features: list[list[float]] = []
    targets: list[int] = []
    for line in lines:
        start, end = line.span
        for position, vector in enumerate(line.features):
            features.append(vector)
            targets.append(int(start <= position < end))
    return np.array(features), np.array(targets)


def span_accuracy(lines: list[LabelledLine], model) -> tuple[int, int]:
    """La métrique qui compte : l'intervalle décodé est-il le bon ?"""
    right = 0
    for line in lines:
        probabilities = model.predict_proba(np.array(line.features))[:, 1]
        right += best_span(line.words, list(probabilities)) == line.span
    return right, len(lines)


def _model() -> HistGradientBoostingClassifier:
    return HistGradientBoostingClassifier(
        # Un mot sur deux et demi seulement est hors du libellé, et le
        # décodeur paie chaque inclusion au log-odds : laissé au déséquilibre
        # brut, le modèle penche vers l'inclusion et le nom ramasse la
        # colonne voisine. Rééquilibrer les classes n'est pas un seuil réglé
        # à la main, c'est refuser que la fréquence décide à la place des
        # features.
        class_weight="balanced",
        max_iter=600,
        learning_rate=0.05,
        min_samples_leaf=20,
        l2_regularization=1.0,
        early_stopping=True,
        validation_fraction=0.15,
        n_iter_no_change=30,
        random_state=42,
    )


def main() -> None:
    train, test = labelled(), held_out()
    x_train, y_train = dataset(train)
    x_test, y_test = dataset(test)
    print(f"entraînement : {len(train)} lignes, {len(y_train)} mots")
    print(f"évaluation   : {len(test)} lignes, {len(y_test)} mots")

    model = _model()
    model.fit(x_train, y_train)
    print(f"\npar mot : {(model.predict(x_test) == y_test).mean():.1%}")
    print(classification_report(y_test, model.predict(x_test), digits=3, zero_division=0))

    right, total = span_accuracy(test, model)
    print(f"intervalle exact : {right}/{total} ({right / total:.1%})")

    MODELS_DIR.mkdir(parents=True, exist_ok=True)
    joblib.dump(model, SPAN_MODEL_PATH)
    print(f"modèle écrit : {SPAN_MODEL_PATH}")


if __name__ == "__main__":
    main()
