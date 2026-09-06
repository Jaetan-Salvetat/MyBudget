import argparse
import json
import random
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from corpus.conventions import CLASS_GUIDE
from corpus.llm.openrouter import DEFAULT_MODEL, complete_json
from corpus.llm.utterances import (
    GENERATION_BATCH,
    PARALLELISM,
    SHUFFLE_SEED,
    VERIFICATION_BATCH,
    align_verdicts,
    neighbours,
)
from corpus.receipts.lines import LINES_DIR, read_lines
from corpus.receipts.style import strip_accents
from paths import EVAL_DATA_DIR, RECEIPTS_CORPUS
from serving.normalize import normalize_receipt_line
from taxonomy import ACTIVE_LABELS, LABEL_INDEX, NUM_EXPENSE

GROUP_SIZE = 12
EXPENSE_LABELS = [slug for slug in ACTIVE_LABELS if LABEL_INDEX[slug] < NUM_EXPENSE]

SYSTEM = """\
Tu reproduis des lignes d'articles telles qu'une caisse enregistreuse française les imprime sur un ticket : majuscules sans accent, abréviations de caisse, troncatures, contenances collées, marques distributeur. Tu réponds uniquement par du JSON valide, sans commentaire."""


def measured_lines() -> set[str]:
    out: set[str] = set()
    hard = EVAL_DATA_DIR / "hard_receipts.json"
    if hard.exists():
        out.update(
            normalize_receipt_line(case["name"])
            for case in json.loads(hard.read_text(encoding="utf-8"))["cases"]
        )
    if RECEIPTS_CORPUS.exists():
        out.update(
            normalize_receipt_line(row["name"])
            for row in json.loads(RECEIPTS_CORPUS.read_text(encoding="utf-8"))
            if row["split"] == "test"
        )
    return out


def generation_prompt(slug: str, count: int) -> str:
    others = "\n".join(f"- {other} : {CLASS_GUIDE[other]}" for other in neighbours(slug))
    return f"""\
Écris {count} lignes d'articles distinctes, telles qu'imprimées sur un ticket de caisse, pour des achats de la catégorie `{slug}` : {CLASS_GUIDE[slug]}

Ces catégories voisines existent séparément, aucune ligne ne doit pouvoir leur appartenir :
{others}

Règles :
- une ligne = un article, comme sur le ticket : « *160G BLC PLT 4TR.F », « AUC BIOD LAIT SOL ENT BT 1L », « MENU MIDI 3 PLATS » ;
- majuscules sans accent, abréviations réelles de caisse (SCE, PDT, BTE, PQT, FRTS, 4TR, BLC), troncatures à 20-28 caractères ;
- contenances et quantités collées quand ça se justifie (50CL, 1KG, X6, 250G) ;
- jamais de prix, jamais de montant, jamais de symbole monétaire ;
- varie : marque connue, marque distributeur, produit générique, ligne de prestation ;
- n'ajoute jamais un mot qui nomme le lieu, le rayon ou la catégorie (TABLE, SERVICE, SALLE, RESTAURANT, BAR, CAFE, PHARMACIE, GARAGE…) : la caisse n'imprime que l'article, c'est l'article seul qui doit dire sa catégorie ;
- chaque ligne doit être classable dans `{slug}` sans hésitation par quelqu'un qui lit le ticket.

Réponds par un tableau JSON de chaînes."""


def verification_prompt(texts: list[str]) -> str:
    catalogue = "\n".join(f"- {slug} : {CLASS_GUIDE[slug]}" for slug in EXPENSE_LABELS)
    listing = "\n".join(f"{index}. {text}" for index, text in enumerate(texts))
    return f"""\
Voici les catégories de dépense d'une application de budget :
{catalogue}

Chaque ligne ci-dessous est un article imprimé sur un ticket de caisse. Donne la catégorie de l'article lui-même, sans supposer le magasin. Si aucune catégorie ne convient sans hésitation, réponds "ambigu".

{listing}

Réponds par un tableau JSON de {len(texts)} objets {{"i": numéro de la ligne, "slug": slug de catégorie ou "ambigu"}}."""


def accept(slug: str, lines: list[str], verdicts: list[str], measured: set[str]) -> list[str]:
    seen: set[str] = set()
    kept: list[str] = []
    for line, verdict in zip(lines, verdicts):
        form = normalize_receipt_line(line)
        if verdict != slug or not form or form in seen or form in measured:
            continue
        seen.add(form)
        kept.append(strip_accents(line).strip().upper())
    return kept


def generate(slug: str, count: int, model: str) -> list[str]:
    lines: list[str] = []
    for _ in range(0, count, GENERATION_BATCH):
        try:
            payload = complete_json(SYSTEM, generation_prompt(slug, GENERATION_BATCH), model)
        except RuntimeError as error:
            print(f"lot perdu pour {slug} : {error}")
            continue
        lines.extend(str(item).strip() for item in payload if str(item).strip())
    return lines


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


def write(slug: str, lines: list[str], directory: Path = LINES_DIR) -> None:
    (directory / f"{slug}.json").write_text(
        json.dumps({"slug": slug, "lines": lines}, ensure_ascii=False, indent=1) + "\n",
        encoding="utf-8",
    )


def merge(current: list[str], fresh: list[str]) -> list[str]:
    seen = {normalize_receipt_line(line) for line in current}
    merged = list(current)
    for line in fresh:
        form = normalize_receipt_line(line)
        if form not in seen:
            seen.add(form)
            merged.append(line)
    return merged


def prune_shared(directory: Path = LINES_DIR) -> list[str]:
    owners: dict[str, set[str]] = defaultdict(set)
    current = read_lines(directory)
    for slug, lines in current.items():
        for line in lines:
            owners[normalize_receipt_line(line)].add(slug)
    shared = {form for form, slugs in owners.items() if len(slugs) > 1}
    for slug, lines in current.items():
        write(slug, [line for line in lines if normalize_receipt_line(line) not in shared], directory)
    return sorted(shared)


def verdicts_by_slug(
    pooled: list[tuple[str, str]], model: str, rng: random.Random
) -> dict[str, tuple[list[str], list[str]]]:
    rng.shuffle(pooled)
    texts = [line for _, line in pooled]
    width = VERIFICATION_BATCH * 4
    chunks = [texts[i : i + width] for i in range(0, len(texts), width)]
    with ThreadPoolExecutor(PARALLELISM) as pool:
        verdicts = [v for chunk in pool.map(lambda c: verify(c, model), chunks) for v in chunk]
    by_slug: dict[str, tuple[list[str], list[str]]] = defaultdict(lambda: ([], []))
    for (slug, line), verdict in zip(pooled, verdicts):
        by_slug[slug][0].append(line)
        by_slug[slug][1].append(verdict)
    return by_slug


def run_group(slugs: list[str], count: int, model: str) -> None:
    rng = random.Random(SHUFFLE_SEED)
    measured = measured_lines()
    with ThreadPoolExecutor(PARALLELISM) as pool:
        generated = dict(zip(slugs, pool.map(lambda slug: generate(slug, count, model), slugs)))
    pooled = [(slug, line) for slug, lines in generated.items() for line in lines]
    by_slug = verdicts_by_slug(pooled, model, rng)
    current = read_lines()
    for slug in slugs:
        lines, slug_verdicts = by_slug[slug]
        kept = accept(slug, lines, slug_verdicts, measured)
        merged = merge(current.get(slug, []), kept)
        write(slug, merged)
        print(f"{slug:45s} générées {len(lines):4d}  retenues {len(kept):4d}  total {len(merged):4d}")


def reverify_group(slugs: list[str], model: str, directory: Path = LINES_DIR) -> None:
    rng = random.Random(SHUFFLE_SEED)
    measured = measured_lines()
    current = read_lines(directory)
    pooled = [(slug, line) for slug in slugs for line in current.get(slug, [])]
    by_slug = verdicts_by_slug(pooled, model, rng)
    for slug in slugs:
        lines, slug_verdicts = by_slug[slug]
        kept = accept(slug, lines, slug_verdicts, measured)
        write(slug, kept, directory)
        print(f"{slug:45s} relues {len(lines):4d}  gardées {len(kept):4d}")


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
    parser.add_argument("--verify", action="store_true")
    args = parser.parse_args()
    if args.verify:
        reverify(args.slugs or sorted(read_lines()), args.model)
        return
    run(args.slugs, args.count, args.model)


if __name__ == "__main__":
    main()
