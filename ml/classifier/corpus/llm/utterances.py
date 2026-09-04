import argparse
import json
import random
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from pathlib import Path

from corpus.conventions import CLASS_GUIDE
from corpus.llm.openrouter import DEFAULT_MODEL, complete_json
from corpus.quick_add.utterances import (
    RECURRENCE_VALUES,
    UTTERANCES_DIR,
    read_utterances,
)
from paths import EVAL_DATA_DIR
from serving.normalize import normalize_query
from taxonomy import ACTIVE_LABELS, ONE_TIME
from training.hierarchy import family_of

EVALUATION_CORPORA = ("hard_quick_add.json", "world.json", "quick_add.json", "fresh_quick_add.json")
AMOUNT_MARKERS = ("€", "euro", "balles")
VERIFICATION_BATCH = 40
GENERATION_BATCH = 60
PARALLELISM = 6
SHUFFLE_SEED = 7
GROUP_SIZE = 12
AMBIGUOUS = "ambigu"
RECURRENCE_NAMES: dict[int, str] = {value: name for name, value in RECURRENCE_VALUES.items()}

STYLE_AXES = """\
Répartis les formulations sur toutes ces formes, aucune ne doit dominer :
- un mot ou deux, télégraphique, comme dans un champ de saisie rapide (« coiff », « retrait 50 », « permis code ») ;
- une enseigne ou une marque nue, avec parfois un surnom (« macdo », « carrouf ») ;
- un libellé de relevé bancaire recopié tel quel, en majuscules sans accent (« CB CARREFOUR MARKET », « PRLV SEPA ENGIE », « VIR SEPA CAF APL ») ;
- un syntagme sans aucune enseigne, qui ne dit que l'intention (« courses de la semaine ») ;
- une phrase complète à verbe conjugué, parlée, comme on raconte sa journée (« on a mangé sur le pouce entre deux rendez-vous ») ;
- une énumération d'articles sans verbe ni enseigne (« cahiers stylos et colle ») ;
- de l'argot ou du familier (« kawa », « toubib », « muscu ») ;
- une formulation avec récurrence explicite quand la classe s'y prête (« abonnement », « mensualité », « prélèvement ») ;
- une référence produit ou un chiffre qui fait partie du nom (« forfait 100 Go », « SP98 », « carte 10 voyages ») ;
- un commerce local inventé avec un nom propre (« Le Fournil de Sarah », « Garage Martin ») ;
- un contexte qui lève l'ambiguïté d'une enseigne polyvalente (« Leclerc cartouches d'encre »).
"""

SYSTEM = """\
Tu écris ce qu'un utilisateur francophone tape dans le champ de saisie rapide d'une application de budget personnel pour enregistrer une dépense ou une entrée d'argent. Tu produis exclusivement du français, avec le vocabulaire, les tournures, les enseignes et les administrations que connaît quelqu'un qui vit en France. Tu réponds uniquement par du JSON valide, sans commentaire."""


@dataclass(frozen=True, slots=True)
class Candidate:
    text: str
    recurrence: int


def measured_inputs() -> set[str]:
    out: set[str] = set()
    for name in EVALUATION_CORPORA:
        path = EVAL_DATA_DIR / name
        if path.exists():
            cases = json.loads(path.read_text(encoding="utf-8"))["cases"]
            out.update(normalize_query(case["input"]) for case in cases)
    return out


def neighbours(slug: str) -> list[str]:
    family = family_of(slug)
    return [other for other in ACTIVE_LABELS if other != slug and family_of(other) == family]


def generation_prompt(slug: str, count: int) -> str:
    guide = CLASS_GUIDE[slug]
    others = "\n".join(f"- {other} : {CLASS_GUIDE[other]}" for other in neighbours(slug))
    return f"""\
Écris {count} formulations distinctes pour la catégorie `{slug}` : {guide}

Ces catégories voisines existent séparément, aucune formulation ne doit pouvoir leur appartenir :
{others}

{STYLE_AXES}
Règles :
- jamais de montant, ni chiffre suivi de € ou euros ;
- pas de faute d'orthographe volontaire ;
- longueurs variées, d'un mot à une quinzaine de mots ;
- chaque formulation doit être classable dans `{slug}` sans hésitation par un lecteur qui ne connaît pas la catégorie visée ;
- `recurrence` vaut "fixe" pour un paiement ou un revenu qui revient chaque mois ou chaque année, "ponctuel" sinon.

Réponds par un tableau JSON d'objets {{"text": ..., "recurrence": "ponctuel" | "fixe"}}."""


def verification_prompt(texts: list[str]) -> str:
    catalogue = "\n".join(f"- {slug} : {guide}" for slug, guide in CLASS_GUIDE.items())
    listing = "\n".join(f"{index}. {text}" for index, text in enumerate(texts))
    return f"""\
Voici les catégories d'une application de budget :
{catalogue}

Pour chaque saisie ci-dessous, donne la catégorie qui lui correspond. Une saisie peut être une dépense ou une entrée d'argent ; lis la direction dans la formulation. Si aucune catégorie ne convient sans hésitation, réponds "ambigu".

{listing}

Réponds par un tableau JSON de {len(texts)} objets {{"i": numéro de la saisie, "slug": slug de catégorie ou "ambigu"}}."""


def parse_candidates(payload) -> list[Candidate]:
    out: list[Candidate] = []
    for row in payload:
        recurrence = RECURRENCE_VALUES.get(str(row.get("recurrence", "")).lower(), ONE_TIME)
        text = str(row.get("text", "")).strip()
        if text:
            out.append(Candidate(text, recurrence))
    return out


def carries_amount(text: str) -> bool:
    lowered = text.lower()
    return any(marker in lowered for marker in AMOUNT_MARKERS)


def accept(
    slug: str, candidates: list[Candidate], verdicts: list[str], measured: set[str]
) -> list[Candidate]:
    seen: set[str] = set()
    kept: list[Candidate] = []
    for candidate, verdict in zip(candidates, verdicts):
        key = normalize_query(candidate.text)
        if verdict != slug or not key or key in seen or key in measured:
            continue
        if carries_amount(candidate.text):
            continue
        seen.add(key)
        kept.append(candidate)
    return kept


def generate(slug: str, count: int, model: str, rng: random.Random) -> list[Candidate]:
    candidates: list[Candidate] = []
    for _ in range(0, count, GENERATION_BATCH):
        try:
            payload = complete_json(SYSTEM, generation_prompt(slug, GENERATION_BATCH), model)
        except RuntimeError as error:
            print(f"lot perdu pour {slug} : {error}")
            continue
        candidates.extend(parse_candidates(payload))
    rng.shuffle(candidates)
    return candidates


def verify(texts: list[str], model: str) -> list[str]:
    verdicts: list[str] = []
    for start in range(0, len(texts), VERIFICATION_BATCH):
        batch = texts[start : start + VERIFICATION_BATCH]
        try:
            payload = complete_json(SYSTEM, verification_prompt(batch), model, temperature=0.0)
        except RuntimeError as error:
            print(f"vérification perdue pour {len(batch)} candidats : {error}")
            payload = []
        verdicts.extend(align_verdicts(payload, len(batch)))
    return verdicts


def align_verdicts(payload, size: int) -> list[str]:
    answers = [AMBIGUOUS] * size
    for item in payload:
        if not isinstance(item, dict):
            continue
        index = item.get("i")
        if isinstance(index, int) and 0 <= index < size:
            answers[index] = str(item.get("slug", AMBIGUOUS))
    return answers


def existing(slug: str, directory: Path = UTTERANCES_DIR) -> list[Candidate]:
    return [
        Candidate(utterance.text, utterance.recurrence)
        for utterance in read_utterances(directory)
        if utterance.slug == slug
    ]


def write(slug: str, candidates: list[Candidate], directory: Path = UTTERANCES_DIR) -> None:
    rows = ",\n".join(
        json.dumps(
            {"text": candidate.text, "recurrence": RECURRENCE_NAMES[candidate.recurrence]},
            ensure_ascii=False,
        )
        for candidate in candidates
    )
    (directory / f"{slug}.json").write_text(
        f'{{"slug": {json.dumps(slug)}, "utterances": [\n{rows}\n]}}\n', encoding="utf-8"
    )


def merge(current: list[Candidate], fresh: list[Candidate]) -> list[Candidate]:
    seen = {normalize_query(candidate.text) for candidate in current}
    merged = list(current)
    for candidate in fresh:
        key = normalize_query(candidate.text)
        if key not in seen:
            seen.add(key)
            merged.append(candidate)
    return merged


def prune_shared(directory: Path = UTTERANCES_DIR) -> list[str]:
    owners: dict[str, set[str]] = defaultdict(set)
    for utterance in read_utterances(directory):
        owners[normalize_query(utterance.text)].add(utterance.slug)
    shared = {text for text, slugs in owners.items() if len(slugs) > 1}
    for path in sorted(directory.glob("*.json")):
        slug = path.stem
        kept = [
            Candidate(utterance.text, utterance.recurrence)
            for utterance in read_utterances(directory)
            if utterance.slug == slug and normalize_query(utterance.text) not in shared
        ]
        write(slug, kept, directory)
    return sorted(shared)


def verdicts_by_slug(
    pooled: list[tuple[str, Candidate]], model: str, rng: random.Random
) -> dict[str, tuple[list[Candidate], list[str]]]:
    rng.shuffle(pooled)
    texts = [candidate.text for _, candidate in pooled]
    width = VERIFICATION_BATCH * 4
    chunks = [texts[i : i + width] for i in range(0, len(texts), width)]
    with ThreadPoolExecutor(PARALLELISM) as pool:
        verdicts = [v for chunk in pool.map(lambda c: verify(c, model), chunks) for v in chunk]
    by_slug: dict[str, tuple[list[Candidate], list[str]]] = defaultdict(lambda: ([], []))
    for (slug, candidate), verdict in zip(pooled, verdicts):
        by_slug[slug][0].append(candidate)
        by_slug[slug][1].append(verdict)
    return by_slug


def run_group(slugs: list[str], count: int, model: str) -> None:
    rng = random.Random(SHUFFLE_SEED)
    measured = measured_inputs()
    with ThreadPoolExecutor(PARALLELISM) as pool:
        generated = dict(
            zip(slugs, pool.map(lambda slug: generate(slug, count, model, rng), slugs))
        )
    pooled = [(slug, candidate) for slug, candidates in generated.items() for candidate in candidates]
    by_slug = verdicts_by_slug(pooled, model, rng)
    for slug in slugs:
        candidates, slug_verdicts = by_slug[slug]
        kept = accept(slug, candidates, slug_verdicts, measured)
        merged = merge(existing(slug), kept)
        write(slug, merged)
        print(f"{slug:45s} générées {len(candidates):4d}  retenues {len(kept):4d}  total {len(merged):4d}")


def reverify_group(slugs: list[str], model: str, directory: Path = UTTERANCES_DIR) -> None:
    rng = random.Random(SHUFFLE_SEED)
    measured = measured_inputs()
    pooled = [(slug, candidate) for slug in slugs for candidate in existing(slug, directory)]
    by_slug = verdicts_by_slug(pooled, model, rng)
    for slug in slugs:
        candidates, slug_verdicts = by_slug[slug]
        kept = accept(slug, candidates, slug_verdicts, measured)
        write(slug, kept, directory)
        print(f"{slug:45s} relues {len(candidates):4d}  gardées {len(kept):4d}")


def run(slugs: list[str], count: int, model: str) -> None:
    for start in range(0, len(slugs), GROUP_SIZE):
        run_group(slugs[start : start + GROUP_SIZE], count, model)
    shared = prune_shared()
    print(f"retirées car partagées entre classes : {len(shared)}")


def reverify(slugs: list[str], model: str) -> None:
    for start in range(0, len(slugs), GROUP_SIZE):
        reverify_group(slugs[start : start + GROUP_SIZE], model)
    shared = prune_shared()
    print(f"retirées car partagées entre classes : {len(shared)}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("slugs", nargs="*")
    parser.add_argument("--count", type=int, default=GENERATION_BATCH * 2)
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument("--missing", action="store_true")
    parser.add_argument("--verify", action="store_true")
    args = parser.parse_args()
    slugs = list(args.slugs)
    covered = {utterance.slug for utterance in read_utterances()}
    if args.verify:
        reverify(slugs or sorted(covered), args.model)
        return
    if args.missing:
        slugs += [slug for slug in ACTIVE_LABELS if slug not in covered]
    run(slugs, args.count, args.model)


if __name__ == "__main__":
    main()
