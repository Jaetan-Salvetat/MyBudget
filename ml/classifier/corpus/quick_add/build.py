"""Construit le corpus d'entraînement à partir des exemples curés et des entités.

Deux garde-fous portent la qualité du dataset :

- la coupe train/eval se fait par entité, pas par échantillon. Une même marque
  déclinée en dix phrases ne peut pas se retrouver des deux côtés, sinon
  l'évaluation mesure la mémoire et non la généralisation ;
- chaque classe reçoit un budget d'exemples borné en haut et en bas. Sans cela
  les 4 800 compagnies aériennes écrasent les dix libellés de pension
  alimentaire.
"""

import json
import random
from collections import defaultdict
from pathlib import Path

from corpus.quick_add.examples import EXAMPLES
from corpus.quick_add.utterances import SOURCE as UTTERANCE_SOURCE
from corpus.quick_add.utterances import utterance_entities
from corpus.quick_add.verbs import VERB_PHRASES, VERB_SOURCE
from knowledge.build import SOURCE_PRIORITY
from knowledge.entities import TIER_HEAD, Entity, normalize, read_entities
from paths import DATASET_DIR, ENTITIES_PATH
from serving.contract import write_taxonomy_stamp
from serving.normalize import normalize_query
from taxonomy import ACTIVE_LABELS, LABELS, NUM_EXPENSE, RECURRING, type_of

SEED = 42
UTTERANCE_SPLIT_SEED = 43
EVAL_ENTITY_RATIO = 0.08
UTTERANCE_EVAL_CAP = 120
ENTITY_ROW_SOURCE = "entites"
UTTERANCE_ROW_SOURCE = "formulations"
CLASS_SAMPLE_CAP = 7000
CLASS_SAMPLE_FLOOR = 1200
CURATED_SOURCE = "curated"
AMOUNT_RATIO = 0.15

NUM_INCOME = len(LABELS) - NUM_EXPENSE

# L'app ne sert que des utilisateurs francophones : tout le budget de phrase va
# au francais. Les noms d'entites, eux, restent internationaux — un utilisateur
# francais tape Netflix et Ikea. C'est la langue de la tournure qui est
# monolingue, pas celle du monde.
FR_EXPENSE_PREFIXES = [
    "payé", "acheté", "pris", "réglé", "dépensé pour", "commandé", "j'ai payé",
    "j'ai acheté", "achat", "dépense", "note de", "facture", "j'ai pris",
    "j'ai commandé", "réglé la note de", "passé chez", "arrêt", "petit tour à",
    "on a payé", "j'ai claqué", "sorti pour", "addition", "ticket", "reçu de",
    "paiement", "carte bleue", "cb", "en espèces", "j'ai réglé", "commande",
]
FR_INCOME_PREFIXES = [
    "reçu", "perçu", "touché", "encaissé", "gagné", "viré", "j'ai reçu", "virement",
    "j'ai touché", "rentrée de", "versement", "virement reçu", "crédité",
    "remboursement", "j'ai encaissé", "paiement reçu", "rentrée d'argent",
]
FR_SUFFIXES = [
    "hier", "ce matin", "ce soir", "lundi", "mardi", "mercredi", "jeudi", "vendredi",
    "samedi", "dimanche", "la semaine dernière", "le mois dernier", "aujourd'hui",
    "ce week-end", "en janvier", "en février", "en mars", "en avril", "en mai",
    "en juin", "en juillet", "en août", "en septembre", "en octobre", "en novembre",
    "en décembre", "avant-hier", "ce midi", "cet aprem", "cette semaine",
    "en début de mois", "en fin de mois", "il y a deux jours", "la semaine passée",
    "tout à l'heure", "vendredi dernier", "samedi soir", "dimanche midi", "ce matin tôt",
]
FR_CONTEXTS = [
    "avec les amis", "pour moi", "en famille", "pour le boulot", "du mois",
    "du week-end", "de la semaine", "pour la maison", "en ligne", "en magasin",
    "sur place", "à emporter", "avec les collègues", "pour les enfants",
    "avec ma copine", "avec mon copain", "pour l'appart", "pour le bureau",
    "en livraison", "au drive", "en click and collect", "pour offrir",
    "pour les vacances", "avec les voisins", "en urgence", "de dernière minute",
]

AMOUNTS = [
    "12", "8,50", "8.50", "4€", "€25", "15 euros", "30 balles", "1200", "45,90",
    "3.20", "9,99", "60", "250", "22.40", "7 euros", "18,20", "2,30", "150",
]

FRENCH_WRAPPERS = [
    "petit {text}", "{text} rapide", "{text} pas cher", "{text} en promo",
    "gros {text}", "{text} du coin", "{text} de quartier", "{text} en soldes",
    "{text} d'occasion", "{text} en urgence",
]

# « abonnement X » est un prélèvement quelle que soit la classe de X : la
# récurrence se lit dans la formulation, pas seulement dans la nature du
# marchand. Sans cette règle, « abonnement salle de sport » restait ponctuel
# parce que les salles de sport sont majoritairement des achats uniques.
FRENCH_RECURRING_WRAPPERS = [
    "abonnement {text}", "{text} mensuel", "{text} tous les mois", "cotisation {text}",
    "prélèvement {text}", "échéance {text}", "{text} du mois", "abo {text}",
    "mensualité {text}", "{text} chaque mois", "renouvellement {text}",
    "forfait {text}", "{text} par mois", "reconduction {text}", "{text} annuel",
]
RECURRING_RATIO = 0.18

# Les sept formes ci-dessus ne produisent que du syntagme décoré : le corpus
# tenait dans 4 mots de médiane quand l'utilisateur en tape 8, et l'axe
# `phrase_libre` de `evaluation/hard.py` le payait 60,5 % contre 83 % ailleurs.
# Rien dans 124 000 exemples n'avait de verbe conjugué hors des préfixes figés.
#
# C'est aussi ce qui interdisait d'apprendre l'argot : « zinc » vaut bar, café
# ou avion, « mazout » fioul ou gazole, et un syntagme de quatre mots n'a pas
# la place syntaxique de porter ce qui tranche. La grammaire vient donc avant
# le vocabulaire — ce sont les cadres qui font la place, les mots la remplissent.
#
# L'entité arrive toujours après un verbe ou une préposition : c'est la seule
# position qui reste lisible pour une enseigne comme pour un nom commun, sans
# rien savoir de son genre ni de son nombre.
FRENCH_EXPENSE_SENTENCES = [
    "j'ai fini par payer {text}",
    "il a fallu régler {text}",
    "il a fallu repasser par {text}",
    "on est passés par {text} en rentrant",
    "je suis repassé prendre {text}",
    "je suis allé chercher {text}",
    "j'ai encore dû sortir la carte pour {text}",
    "ça m'a coûté un bras chez {text}",
    "on a partagé l'addition pour {text}",
    "j'ai oublié de noter {text}",
    "j'ai réglé ce qu'il restait sur {text}",
    "on a fini par prendre {text}",
    "je me suis laissé tenter par {text}",
    "il restait à payer {text}",
    "on a dû avancer {text}",
    "j'ai profité d'une promo sur {text}",
    "je suis tombé en rade, direction {text}",
    "on n'avait plus rien, donc {text}",
    "j'ai claqué ce qu'il me restait en {text}",
    "je suis passé devant et j'ai pris {text}",
    "on a craqué pour {text}",
    "j'ai fait un saut à {text}",
    "il a bien fallu remplacer {text}",
    "j'ai reçu la facture de {text}",
    "on m'a facturé {text}",
    "j'ai dû rappeler pour {text}",
    "ça faisait longtemps que je repoussais {text}",
    "je me suis décidé pour {text}",
    "on a réservé {text} il y a deux semaines",
    "j'ai pris un abonnement pour {text}",
]
FRENCH_INCOME_SENTENCES = [
    "j'ai enfin touché {text}",
    "il est tombé ce matin, {text}",
    "on m'a viré {text}",
    "j'ai reçu {text} sans rien demander",
    "ça a fini par arriver, {text}",
    "il me restait à encaisser {text}",
    "on m'a remboursé {text}",
    "j'ai récupéré {text}",
    "le virement est passé pour {text}",
    "j'attendais {text} depuis un moment",
    "ils ont enfin versé {text}",
    "j'ai vendu et récupéré {text}",
]
# Ce qui allonge la phrase sans rien dire de la classe : c'est exactement ce
# que le modèle doit apprendre à ignorer.
FRENCH_TAILS = [
    "et je ne l'avais pas prévu",
    "comme tous les mois",
    "avant de partir en week-end",
    "juste avant la fin du mois",
    "parce qu'il n'y avait plus le choix",
    "en rentrant du boulot",
    "pendant que j'y étais",
    "sans faire attention au prix",
    "alors que j'avais dit que non",
    "et ça pique un peu",
    "après avoir hésité longtemps",
    "en même temps que le reste",
    "au dernier moment",
    "pour ne pas avoir à y revenir",
    "et je crois que c'est la dernière fois",
]
SENTENCE_RATIO = 0.30
TAIL_RATIO = 0.45


# NSI et Wikidata rapportent le monde entier ; leur tier dit déjà si l'entité
# appartient à un marché où nos utilisateurs achètent. 11 360 des 28 709 entités
# n'en sont pas — « Morgunblaðið », « Gibraltar Chronicle », « Kyunghyang
# Shinmun ». Les décliner en trois ou quatre formes n'apprend pas une enseigne,
# ça apprend que tout syntagme nominal en alphabet latin appartient à leur
# classe : `loisirs.livre_presse` avalait à lui seul 12 des 59 échecs du corpus
# dur, dont « le dentiste » et « Le Fournil de Sarah ». Le nom est gardé — un
# utilisateur peut le taper — mais il ne reçoit plus une once d'amplification.
GEOGRAPHIC_SOURCES = frozenset({"nsi", "wikidata"})
FOREIGN_MARKET_BUDGET = 1
VERB_FORMS_BUDGET = 8
UTTERANCE_FORMS_BUDGET = 4
UTTERANCE_SUFFIX_RATIO = 0.5
UTTERANCE_TAIL_RATIO = 0.2


def _forms_budget(entity: Entity) -> int:
    priority = SOURCE_PRIORITY.get(entity.source, 0)
    if entity.source == CURATED_SOURCE:
        return 13
    if entity.source == VERB_SOURCE:
        return VERB_FORMS_BUDGET
    if entity.source == UTTERANCE_SOURCE:
        return UTTERANCE_FORMS_BUDGET
    if entity.source in GEOGRAPHIC_SOURCES and entity.tier != TIER_HEAD:
        return FOREIGN_MARKET_BUDGET
    if priority >= 4:
        return 12
    if priority == 3:
        return 7 if entity.tier == TIER_HEAD else 4
    if priority == 2:
        return 4 if entity.tier == TIER_HEAD else 3
    return 3


def _rank(entity: Entity) -> tuple[int, int]:
    if entity.source == CURATED_SOURCE:
        return 6, entity.tier
    return SOURCE_PRIORITY.get(entity.source, 0), entity.tier


def _decorate_clause(text: str, rng: random.Random) -> tuple[str, bool]:
    """Une clause déjà conjuguée ne prend qu'un repère de temps, une queue, un montant.

    Lui appliquer les préfixes nominaux rendrait « achat j'ai fait le plein », et
    les enveloppes « petit j'ai fait le plein ». Ce qui se colle à une phrase se
    colle après elle, pas devant.
    """
    out = text
    if rng.random() < 0.45:
        out = f"{out} {rng.choice(FR_SUFFIXES)}"
    if rng.random() < TAIL_RATIO:
        out = f"{out} {rng.choice(FRENCH_TAILS)}"
    if rng.random() < AMOUNT_RATIO:
        out = f"{out} {rng.choice(AMOUNTS)}"
    return out, False


def _decorate_utterance(text: str, rng: random.Random) -> tuple[str, bool]:
    out = text
    if rng.random() < UTTERANCE_SUFFIX_RATIO:
        out = f"{out} {rng.choice(FR_SUFFIXES)}"
    if rng.random() < UTTERANCE_TAIL_RATIO:
        out = f"{out} {rng.choice(FRENCH_TAILS)}"
    if rng.random() < AMOUNT_RATIO:
        out = f"{out} {rng.choice(AMOUNTS)}"
    return out, False


def _decorate(text: str, is_income: bool, rng: random.Random) -> tuple[str, bool]:
    prefixes = FR_INCOME_PREFIXES if is_income else FR_EXPENSE_PREFIXES
    suffixes = FR_SUFFIXES
    contexts = FR_CONTEXTS
    wrappers = FRENCH_WRAPPERS

    if rng.random() < RECURRING_RATIO:
        return rng.choice(FRENCH_RECURRING_WRAPPERS).format(text=text.lower()), True

    if rng.random() < SENTENCE_RATIO:
        frames = FRENCH_INCOME_SENTENCES if is_income else FRENCH_EXPENSE_SENTENCES
        out = rng.choice(frames).format(text=text.lower())
        if rng.random() < TAIL_RATIO:
            out = f"{out} {rng.choice(FRENCH_TAILS)}"
        if rng.random() < AMOUNT_RATIO:
            out = f"{out} {rng.choice(AMOUNTS)}"
        return out, False

    shape = rng.randrange(7)
    if shape == 0:
        out = text.lower()
    elif shape == 1:
        out = f"{text} {rng.choice(suffixes)}"
    elif shape == 2:
        out = f"{rng.choice(prefixes)} {text.lower()}"
    elif shape == 3:
        out = f"{rng.choice(prefixes)} {text.lower()} {rng.choice(suffixes)}"
    elif shape == 4:
        out = f"{text} {rng.choice(contexts)}"
    elif shape == 5:
        out = rng.choice(wrappers).format(text=text.lower())
    else:
        out = f"{text.lower()} {rng.choice(contexts)} {rng.choice(suffixes)}"

    if rng.random() < AMOUNT_RATIO:
        out = f"{out} {rng.choice(AMOUNTS)}"
    return out, False


def _surface_forms(
    entity: Entity, budget: int, rng: random.Random
) -> list[tuple[str, int]]:
    """Le nom nu d'abord : c'est la forme que l'utilisateur tape le plus."""
    forms: list[tuple[str, int]] = []
    seen: set[str] = set()

    def push(text: str, recurrence: int) -> None:
        """Le corpus est écrit dans la forme exacte que l'app enverra au modèle."""
        cleaned = normalize_query(text)
        key = normalize(cleaned)
        if cleaned and key not in seen:
            seen.add(key)
            forms.append((cleaned, recurrence))

    surfaces = entity.surfaces
    for surface in surfaces[:3]:
        push(surface, entity.recurrence)

    is_income = type_of(entity.slug) == 1
    attempts = 0
    while len(forms) < budget and attempts < budget * 4:
        attempts += 1
        base = rng.choice(surfaces)
        if entity.source == VERB_SOURCE:
            text, marked = _decorate_clause(base, rng)
        elif entity.source == UTTERANCE_SOURCE:
            text, marked = _decorate_utterance(base, rng)
        else:
            text, marked = _decorate(base, is_income, rng)
        push(text, RECURRING if marked else entity.recurrence)
    return forms[:budget]


def _curated_entities() -> list[Entity]:
    """Les exemples écrits à la main, promus au rang d'entités prioritaires."""
    out: list[Entity] = []
    for slug, rows in EXAMPLES.items():
        for text, recurrence in rows:
            out.append(
                Entity(
                    name=text,
                    slug=slug,
                    source=CURATED_SOURCE,
                    tier=TIER_HEAD,
                    recurrence=recurrence,
                )
            )
    return out


def _verb_entities() -> list[Entity]:
    """Les groupes verbaux, promus au rang d'entités de leur classe."""
    return [
        Entity(name=clause, slug=slug, source=VERB_SOURCE, tier=TIER_HEAD)
        for slug, clauses in VERB_PHRASES.items()
        for clause in clauses
    ]


def load_entities() -> list[Entity]:
    if not ENTITIES_PATH.exists():
        raise FileNotFoundError(
            f"{ENTITIES_PATH} absent : lancer d'abord `python -m knowledge.build`"
        )
    return _curated_entities() + _verb_entities() + list(read_entities(ENTITIES_PATH))


def validate_coverage(entities: list[Entity]) -> None:
    covered = {entity.slug for entity in entities}
    missing = [slug for slug in ACTIVE_LABELS if slug not in covered]
    if missing:
        raise ValueError(f"Classes sans aucune entité : {missing}")


def _group(entities: list[Entity]) -> dict[str, list[Entity]]:
    grouped: dict[str, list[Entity]] = defaultdict(list)
    for entity in entities:
        grouped[entity.slug].append(entity)
    return grouped


def _split_entities(
    entities: list[Entity], rng: random.Random
) -> tuple[list[Entity], list[Entity]]:
    """La coupe se fait sur les entités pour qu'aucun nom ne traverse."""
    train: list[Entity] = []
    held_out: list[Entity] = []
    for slug_entities in _group(entities).values():
        pool = sorted(slug_entities, key=lambda e: e.key)
        rng.shuffle(pool)
        count = int(len(pool) * EVAL_ENTITY_RATIO)
        keep = max(0, min(count, len(pool) - 1))
        held_out.extend(pool[:keep])
        train.extend(pool[keep:])
    return train, held_out


def _samples_for_class(
    slug: str,
    slug_entities: list[Entity],
    rng: random.Random,
    cap: int,
    floor: int,
    source: str = ENTITY_ROW_SOURCE,
) -> list[dict]:
    index = LABELS.index(slug)
    type_label = type_of(slug)
    ordered = sorted(slug_entities, key=_rank, reverse=True)

    rows: list[dict] = []
    seen: set[str] = set()

    def emit(entity: Entity, budget: int) -> None:
        for text, recurrence in _surface_forms(entity, budget, rng):
            key = normalize(text)
            if key in seen:
                continue
            seen.add(key)
            rows.append(
                {
                    "text": text,
                    "type_label": type_label,
                    "category_label": index,
                    "recurrence_label": recurrence,
                    "source": source,
                }
            )

    remaining = cap
    for entity in ordered:
        budget = _forms_budget(entity) if remaining > 0 else 1
        emit(entity, min(budget, max(1, remaining)))
        remaining = cap - len(rows)
        if remaining <= 0:
            break

    rounds = 0
    while len(rows) < floor and rounds < 12:
        rounds += 1
        for entity in ordered:
            if len(rows) >= floor:
                break
            emit(entity, 3)
    return rows[:cap]


def generate(seed: int = SEED) -> tuple[list[dict], list[dict]]:
    rng = random.Random(seed)
    entities = load_entities()
    validate_coverage(entities)

    train_entities, held_out = _split_entities(entities, rng)
    train_groups = _group(train_entities)
    eval_groups = _group(held_out)

    train: list[dict] = []
    for slug, group in train_groups.items():
        train.extend(_samples_for_class(slug, group, rng, CLASS_SAMPLE_CAP, CLASS_SAMPLE_FLOOR))

    evaluation: list[dict] = []
    for slug, group in eval_groups.items():
        evaluation.extend(_samples_for_class(slug, group, rng, 400, 0))

    utterance_rng = random.Random(UTTERANCE_SPLIT_SEED)
    utterance_train, utterance_held = _split_entities(utterance_entities(), utterance_rng)
    for slug, group in _group(utterance_train).items():
        train.extend(
            _samples_for_class(
                slug, group, utterance_rng, CLASS_SAMPLE_CAP, 0, UTTERANCE_ROW_SOURCE
            )
        )
    for slug, group in _group(utterance_held).items():
        evaluation.extend(
            _samples_for_class(
                slug, group, utterance_rng, UTTERANCE_EVAL_CAP, 0, UTTERANCE_ROW_SOURCE
            )
        )

    rng.shuffle(train)
    rng.shuffle(evaluation)
    return train, evaluation


def save_jsonl(rows: list[dict], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, ensure_ascii=False) + "\n")
    write_taxonomy_stamp(path)


def main() -> None:
    train, evaluation = generate()
    save_jsonl(train, DATASET_DIR / "train.jsonl")
    save_jsonl(evaluation, DATASET_DIR / "eval.jsonl")

    per_class = defaultdict(int)
    types = [0, 0]
    recurrences = [0, 0]
    for row in train:
        per_class[row["category_label"]] += 1
        types[row["type_label"]] += 1
        recurrences[row["recurrence_label"]] += 1

    ranked = sorted(per_class.items(), key=lambda item: item[1])
    print(f"Classes : {len(LABELS)} ({NUM_EXPENSE} dépenses + {NUM_INCOME} revenus)")
    print(f"Train : {len(train)}  |  Eval (entités jamais vues) : {len(evaluation)}")
    print(f"Type : dépense={types[0]}, revenu={types[1]}")
    print(f"Récurrence : ponctuel={recurrences[0]}, fixe={recurrences[1]}")
    print("Moins représentées : " + ", ".join(f"{LABELS[i]}={n}" for i, n in ranked[:5]))
    print("Plus représentées  : " + ", ".join(f"{LABELS[i]}={n}" for i, n in ranked[-5:]))


if __name__ == "__main__":
    main()
