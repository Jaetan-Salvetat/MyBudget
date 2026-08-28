"""Enseigne et date : le tagger désigne la ligne, la lecture reste au parsing.

Les règles prenaient `lines[0]` pour enseigne — mesuré, 51 tickets sur 500 y
trouvent un slogan ou une adresse. Le tagger fait mieux, mais recopier sa
ligne laissait passer deux choses : les tickets où il doute (rien rendu) et
ceux où l'OCR a abîmé le logo (`E.Leclerc L`, `ToysMus`).

L'enseigne n'est pourtant pas un champ libre — c'est un ensemble quasi fermé.
Le tagger ordonne les lignes de l'en-tête, et `store_gazetteer` y **reconnaît**
un nom connu au lieu de le recopier. Le modèle choisit où chercher, le
répertoire dit ce qui a été trouvé ; quand il ne reconnaît rien, on retombe
sur la ligne désignée telle quelle.

La date, elle, échoue pour la raison inverse — la bonne ligne, mal lue — et
reste donc au parsing seul.
"""

from __future__ import annotations

import joblib
import numpy as np

from annotate.schema import DATE_LINE, ITEM, STORE
from paths import ROLE_MODEL_PATH
from reference.line_features_all import featurize
from reference.line_labels import TAGGER_ROLES
from reference.lines import PhysicalLine
from reference.store_gazetteer import Gazetteer
from reference.store_gazetteer import load as load_gazetteer
from reference.structure import _find_date

# Au-delà, une ligne qui nomme une enseigne parle d'autre chose : une pub
# fidélité, un site web en pied de ticket.
HEADER_FALLBACK_LINES = 12

# On ne cherche un nom connu que parmi les lignes que le tagger n'a pas
# écartées. Une adresse sort à des probabilités de l'ordre de 0,005.
RECOGNITION_MIN_PROBABILITY = 0.05

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


def _header_zone(lines: list[PhysicalLine], probabilities: np.ndarray) -> int:
    """L'en-tête s'arrête au premier article : après, une enseigne nommée est
    une publicité ou une adresse web, jamais le logo."""
    column = TAGGER_ROLES.index(ITEM)
    for index, row in enumerate(probabilities):
        if int(row.argmax()) == column:
            return index
    return min(len(lines), HEADER_FALLBACK_LINES)


def store_of(
    lines: list[PhysicalLine],
    probabilities: np.ndarray,
    gazetteer: Gazetteer | None = None,
) -> str | None:
    """L'enseigne de la ligne que le tagger désigne, rendue sous sa graphie
    connue quand le répertoire l'y reconnaît.

    Reconnaître prime sur recopier : quand le modèle désigne `-SP` et qu'une
    autre ligne de l'en-tête dit « McDonald's », c'est la seconde qui a
    raison. Mais seulement parmi les lignes que le modèle juge plausibles —
    sur un ticket Hyper U, « Cours Maréchal Leclerc » est une rue, et elle
    sort à 0,005. Sous ce plancher, on fabriquerait des enseignes.

    Quand rien n'est reconnu, la ligne désignée est recopiée telle quelle."""
    if not len(probabilities):
        return None
    found = _recognized_store(lines, probabilities, gazetteer or load_gazetteer())
    if found is not None:
        return found
    index = _best_line(lines, probabilities, STORE)
    return lines[index].text if index is not None else None


def _recognized_store(
    lines, probabilities: np.ndarray, gazetteer: Gazetteer
) -> str | None:
    """Le premier nom connu porté par une ligne plausible de l'en-tête."""
    end = _header_zone(lines, probabilities)
    column = probabilities[:end, TAGGER_ROLES.index(STORE)]
    for index in sorted(range(len(column)), key=lambda i: -column[i]):
        if column[index] < RECOGNITION_MIN_PROBABILITY:
            return None
        found = gazetteer.match(lines[index].text)
        if found is not None:
            return found
    return None


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
