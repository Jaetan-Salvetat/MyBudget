"""Échantillon aléatoire de la base d'entités, à relire à la main.

Un dataset à 10 % d'erreurs de correspondance plafonne le modèle à 90 % : rien
ne sert d'entraîner avant d'avoir regardé ce que la moisson a produit. Le tirage
est déterministe, deux relectures portent donc sur le même échantillon.

    python -m knowledge.audit [taille]
"""

import random
import sys
from collections import Counter

from knowledge.entities import read_entities
from paths import ENTITIES_PATH

DEFAULT_SIZE = 60
SEED = 7


def main() -> None:
    size = int(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_SIZE
    entities = list(read_entities(ENTITIES_PATH))
    sample = random.Random(SEED).sample(entities, min(size, len(entities)))

    for entity in sorted(sample, key=lambda item: (item.slug, item.name)):
        print(f"{entity.source[:6]:6s} {entity.name[:38]:38s} → {entity.slug}")

    sources = Counter(entity.source for entity in sample)
    print(f"\n{len(sample)} entités sur {len(entities)} — " + ", ".join(
        f"{source}={count}" for source, count in sources.most_common()
    ))


if __name__ == "__main__":
    main()
