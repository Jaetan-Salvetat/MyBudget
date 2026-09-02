"""Enseigne et date : le tagger désigne la ligne, la lecture reste au parsing.

Les règles prenaient `lines[0]` pour enseigne — mesuré, 51 tickets sur 500 y
trouvent un slogan ou une adresse. Le tagger fait mieux. Le répertoire
d'enseignes (`store_gazetteer`) ne choisit rien : il **normalise** le texte de
la ligne désignée quand il y reconnaît un nom connu (`E.Leclerc L` →
`E.Leclerc`), et rend la ligne telle quelle sinon. Quand le tagger ne désigne
rien, il n'y a pas d'enseigne : c'est le modèle qui décide, jamais un lexique.

La date, elle, échoue pour la raison inverse — la bonne ligne, mal lue — et
reste donc au parsing seul.
"""

from __future__ import annotations

import joblib
import numpy as np

from annotate.schema import DATE_LINE, STORE
from paths import ROLE_MODEL_PATH
from reference.line_features_all import featurize
from reference.line_labels import TAGGER_ROLES
from reference.lines import PhysicalLine
from reference.store_gazetteer import Gazetteer
from reference.store_gazetteer import load as load_gazetteer
from reference.structure import _find_date

_model = None


def load_role_model():
    global _model
    if _model is None:
        _model = joblib.load(ROLE_MODEL_PATH)
    return _model


def role_probabilities(lines: list[PhysicalLine]) -> np.ndarray:
    """Probabilité de chaque rôle pour chaque ligne, dans l'ordre du ticket."""
    rows = featurize(lines)
    if not rows:
        return np.zeros((0, len(TAGGER_ROLES)))
    return load_role_model().predict_proba(np.array(rows))


def predicted_roles(lines: list[PhysicalLine]) -> list[str]:
    """Le rôle le plus probable de chaque ligne — l'argmax, sans seuil : la
    décision se juge au checksum, pas à une confiance choisie à la main."""
    return [TAGGER_ROLES[int(row.argmax())] for row in role_probabilities(lines)]


def _best_line(
    lines: list[PhysicalLine], probabilities: np.ndarray, role: str
) -> int | None:
    """La ligne la plus probable pour ce rôle — un ticket n'en a qu'une."""
    if not len(probabilities):
        return None
    column = probabilities[:, TAGGER_ROLES.index(role)]
    best = int(column.argmax())
    return best if column[best] > 0.5 else None


def store_of(
    lines: list[PhysicalLine],
    probabilities: np.ndarray,
    gazetteer: Gazetteer | None = None,
) -> str | None:
    """L'enseigne de la ligne que le tagger désigne, rendue sous sa graphie
    connue quand le répertoire l'y reconnaît, telle quelle sinon."""
    index = _best_line(lines, probabilities, STORE)
    if index is None:
        return None
    text = lines[index].text
    return (gazetteer or load_gazetteer()).match(text) or text


def date_of(lines: list[PhysicalLine], probabilities: np.ndarray) -> str | None:
    """La date lue sur la ligne désignée ; à défaut, sur tout le ticket — le
    tagger peut se tromper de ligne, il ne doit pas faire perdre une date que
    les règles savaient lire."""
    index = _best_line(lines, probabilities, DATE_LINE)
    if index is not None:
        found = _find_date([lines[index]])
        if found is not None:
            return found
    return _find_date(lines)
