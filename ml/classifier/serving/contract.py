"""Le contrat de sortie du modèle : une tête de catégorie, un ordre de slugs.

Un slug inséré dans `assets/categories.json` décale toutes les classes qui le
suivent. Les poids gardent l'ordre de leur entraînement : l'argmax reste
valide, seule sa traduction en nom ment, et rien ne remonte. Deux classes
ajoutées le 31 août — `finance.assurance_autre` et `famille_education.enfant` —
ont ainsi fait tomber les cas durs de 87,9 % à 59,7 % sans que le modèle bouge
d'un poids, et l'app décodait chaque prédiction au-delà de l'index 46 sous un
autre nom.

Une dérive muette ne s'attrape que par une vérification de forme. Elle est ici,
appelée partout où des logits deviennent des slugs.
"""

import json
from pathlib import Path

from taxonomy import LABELS


class HeadMismatch(RuntimeError):
    """La tête de catégorie et la taxonomie ne décrivent pas les mêmes classes."""


def assert_category_head(size: int, origin: str) -> None:
    if size == len(LABELS):
        return
    raise HeadMismatch(
        f"{origin} : {size} classes en sortie, {len(LABELS)} dans la taxonomie. "
        "Les prédictions au-delà du premier slug ajouté seraient décodées sous "
        "un autre nom. Reconstruire le corpus et réentraîner."
    )


def stamp_path(corpus_path: Path) -> Path:
    return corpus_path.with_suffix(corpus_path.suffix + ".labels.json")


def write_taxonomy_stamp(corpus_path: Path) -> None:
    """Le corpus range une classe par index ; l'index seul ne dit pas laquelle."""
    stamp_path(corpus_path).write_text(
        json.dumps(LABELS, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )


def assert_taxonomy_stamp(corpus_path: Path) -> None:
    """Un corpus plus vieux que la taxonomie apprend les mauvaises classes.

    `category_label` est un entier. Une classe insérée décale tout ce qui la
    suit, et le fichier reste lisible, valide, et faux : `receipts_train.jsonl`
    enseignait `voyage.activite_visite` là où il voulait dire `divers.animaux`.
    """
    path = stamp_path(corpus_path)
    if not path.exists():
        raise HeadMismatch(
            f"{corpus_path.name} : aucune taxonomie de référence à côté du corpus. "
            "Le reconstruire écrit ce repère."
        )
    written = json.loads(path.read_text(encoding="utf-8"))
    if written == LABELS:
        return
    drift = [slug for slug in LABELS if slug not in written]
    raise HeadMismatch(
        f"{corpus_path.name} : construit sur {len(written)} classes, la taxonomie en "
        f"compte {len(LABELS)}"
        + (f" ; ajoutées depuis : {', '.join(drift)}" if drift else "")
        + ". Les index du corpus désignent d'autres classes : le reconstruire."
    )
