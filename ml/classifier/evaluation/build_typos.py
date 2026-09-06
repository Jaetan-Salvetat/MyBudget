"""Écrit le corpus des fautes réelles : ce qu'un utilisateur tape vraiment.

`evaluation/robustness.py` mesure des opérateurs synthétiques sur des entités
jamais vues. Il manque l'autre moitié : la faute qu'un francophone fait pour de
bon sur un nom que la base connaît — « farmacie », « carrefourcity »,
« decatlhon ». Chaque cas porte sa forme correcte, et la mesure est la chute
entre les deux, pas la justesse absolue.

La classe vient de `dataset/entities.jsonl`, jamais d'un jugement à la main :
une vérité écrite ici divergerait de celle qui a servi à entraîner.

    uv run python -m evaluation.build_typos
"""

import json
from collections import defaultdict

from knowledge.entities import normalize, read_entities
from paths import ENTITIES_PATH, EVAL_DATA_DIR
from taxonomy import type_of

PAIRS = [
    # frappe : lettre doublée, omise, voisine, transposée
    ("carfour", "carrefour", "frappe"),
    ("carrfour", "carrefour", "frappe"),
    ("carrefour marekt", "carrefour market", "frappe"),
    ("intermarcher", "intermarche", "frappe"),
    ("leclrec", "leclerc", "frappe"),
    ("aamazon", "amazon", "frappe"),
    ("amazone", "amazon", "frappe"),
    ("netflx", "netflix", "frappe"),
    ("netflixx", "netflix", "frappe"),
    ("spotifi", "spotify", "frappe"),
    ("decatlhon", "decathlon", "frappe"),
    ("decatlon", "decathlon", "frappe"),
    ("leroy merln", "leroy merlin", "frappe"),
    ("boulengerie", "boulangerie", "frappe"),
    ("boulangerei", "boulangerie", "frappe"),
    ("pharmacei", "pharmacie", "frappe"),
    ("resturant", "restaurant", "frappe"),
    ("restaurnt", "restaurant", "frappe"),
    ("coifeur", "coiffeur", "frappe"),
    ("essance", "essence", "frappe"),
    ("assurence habitation", "assurance habitation", "frappe"),
    ("mutuele", "mutuelle", "frappe"),
    ("electrcite", "electricite", "frappe"),
    ("abonement salle de sport", "abonnement salle de sport", "frappe"),
    ("uber eatz", "uber eats", "frappe"),
    ("deliverooo", "deliveroo", "frappe"),
    ("zalendo", "zalando", "frappe"),
    ("sephore", "sephora", "frappe"),
    ("monopris", "monoprix", "frappe"),
    ("franprx", "franprix", "frappe"),
    ("lidle", "lidl", "frappe"),
    ("auchen", "auchan", "frappe"),
    ("piscard", "picard", "frappe"),
    ("nesspresso", "nespresso", "frappe"),
    ("ikeaa", "ikea", "frappe"),
    ("fnak", "fnac", "frappe"),
    ("darthy", "darty", "frappe"),
    ("boulenger", "boulanger", "frappe"),
    ("noratuo", "norauto", "frappe"),
    # phonétique : écrit au son
    ("farmacie", "pharmacie", "phonetique"),
    ("bulangerie", "boulangerie", "phonetique"),
    ("restaurent", "restaurant", "phonetique"),
    ("koiffeur", "coiffeur", "phonetique"),
    ("essense", "essence", "phonetique"),
    ("peaje", "peage", "phonetique"),
    ("garaje", "garage", "phonetique"),
    ("telephonne", "telephone", "phonetique"),
    ("aboneman internet", "box internet", "phonetique"),
    ("cantinne", "cantine", "phonetique"),
    ("creshe", "creche", "phonetique"),
    ("loier", "loyer", "phonetique"),
    ("salere", "salaire", "phonetique"),
    # agglutination : l'espace perdu
    ("carrefourcity", "carrefour city", "agglutination"),
    ("burgerking", "burger king", "agglutination"),
    ("ubereats", "uber eats", "agglutination"),
    ("leroymerlin", "leroy merlin", "agglutination"),
    ("salledesport", "salle de sport", "agglutination"),
    ("grandfrais", "grand frais", "agglutination"),
    ("pizzahut", "pizza hut", "agglutination"),
    # ponctuation collée et casse
    ("h&m", "h & m", "ponctuation"),
    ("c&a", "c & a", "ponctuation"),
    ("CARREFOUR", "carrefour", "casse"),
    ("NETFLIX", "netflix", "casse"),
    ("Décathlon", "decathlon", "casse"),
    ("PHARMACIE", "pharmacie", "casse"),
    # mot coupé
    ("carre four", "carrefour", "coupure"),
    ("boulan gerie", "boulangerie", "coupure"),
    ("super marche", "supermarche", "coupure"),
]


def main() -> None:
    by_name = defaultdict(list)
    for entity in read_entities(ENTITIES_PATH):
        for surface in entity.surfaces:
            by_name[normalize(surface)].append(entity)

    cases, missing = [], []
    for typo, clean, axis in PAIRS:
        entities = by_name.get(normalize(clean))
        if not entities:
            missing.append(clean)
            continue
        entity = entities[0]
        cases.append({
            "input": typo,
            "clean": clean,
            "type": ["expense", "income"][type_of(entity.slug)],
            "category": entity.slug,
            "axis": axis,
        })
    note = (
        "Fautes réelles sur des noms que la base connaît : chaque cas porte sa "
        "forme correcte, et la mesure est la chute entre les deux. La classe "
        "vient de dataset/entities.jsonl, jamais d'un jugement à la main."
    )
    path = EVAL_DATA_DIR / "typos.json"
    path.write_text(
        json.dumps({"note": note, "cases": cases}, ensure_ascii=False, indent=1) + "\n",
        encoding="utf-8",
    )
    for case in cases:
        print(f"{case['axis']:14s} {case['input']:26s} {case['clean']:24s} {case['category']}")
    print(f"\n{len(cases)} cas → {path}, absents de la base : {sorted(set(missing))}")


if __name__ == "__main__":
    main()
