import json
from dataclasses import dataclass
from pathlib import Path

from knowledge.entities import TIER_HEAD, Entity
from taxonomy import ONE_TIME, RECURRING

UTTERANCES_DIR = Path(__file__).resolve().parent / "utterances"
SOURCE = "formulations"
RECURRENCE_VALUES: dict[str, int] = {"ponctuel": ONE_TIME, "fixe": RECURRING}


@dataclass(frozen=True, slots=True)
class Utterance:
    text: str
    slug: str
    recurrence: int


def read_utterances(directory: Path = UTTERANCES_DIR) -> list[Utterance]:
    out: list[Utterance] = []
    for path in sorted(directory.glob("*.json")):
        document = json.loads(path.read_text(encoding="utf-8"))
        slug = document["slug"]
        if slug != path.stem:
            raise ValueError(f"{path.name} porte le slug {slug}")
        for row in document["utterances"]:
            out.append(Utterance(row["text"], slug, RECURRENCE_VALUES[row["recurrence"]]))
    return out


def utterance_entities(directory: Path = UTTERANCES_DIR) -> list[Entity]:
    return [
        Entity(
            name=utterance.text,
            slug=utterance.slug,
            source=SOURCE,
            tier=TIER_HEAD,
            recurrence=utterance.recurrence,
        )
        for utterance in read_utterances(directory)
    ]
