"""Sort le conditionnement du nom, sur le corpus déjà annoté.

Le nom d'un article porte parfois son conditionnement, parfois non, et
l'annotation ne tranche pas : mesuré sur les calibres en tête précédés d'une
astérisque, **386 gardés contre 26 jetés** — 6 % que rien ne distingue.

```
*230G WASA FIBRES   → nom annoté 'WASA FIBRES'
*230G PAT BRISE SS  → nom annoté '230G PAT BRISE SS'
```

Même enseigne, même token, décision inverse. C'est exactement la frontière que
le modèle de découpage doit apprendre, et la vérité l'y place au hasard une
fois sur seize. Aucun modèle ne franchit ça.

**La réparation ne demande pas de relire les photos.** Couper une chaîne de
caractères est une tâche de texte : ni géométrie, ni rôles, ni montants. Seul
le nom change, donc le reste du corpus reste identique et la mesure avant/après
est propre — ré-annoter depuis l'image rejouerait tout et rendrait l'écart
ininterprétable.

Et la cohérence y gagne par construction. Le pile-ou-face vient de 4 350
appels **indépendants** : rien ne dit au 812ᵉ ce que le 37ᵉ a décidé. Mille
noms tranchés dans un même contexte le sont de la même façon.

**Le calibre intérieur reste dans le nom.** La vérité de span est un
intervalle contigu de mots (`truth/spans.py`) : retirer un mot du milieu
rendrait le nom introuvable sur sa ligne. Or l'ambiguïté n'existe qu'aux
**frontières** — c'est là, et seulement là, que le découpage décide. Une
convention que la vérité ne peut pas exprimer n'est pas une convention.

Rien n'est réparé, tout est vérifié : un nom et un conditionnement ne sont
retenus que s'ils sont des suites **contiguës** de mots de l'original. Une
orthographe corrigée, un mot ajouté, un ordre changé sont refusés et
l'original est gardé — le filtre élimine, comme celui des montants.

    uv run python -m annotate.split_size <lot.json>... [--golden] [--dry-run]

`--golden` réécrit `data/golden/` au lieu de `data/annotations/` : les deux
sources du découpage doivent partager une seule définition du nom.
"""

from __future__ import annotations

import json
import sys
from collections import Counter
from dataclasses import dataclass
from pathlib import Path

from annotate import record
from annotate.schema import ITEM
from paths import ANNOTATIONS_DIR, GOLDEN_DIR


@dataclass(frozen=True)
class Split:
    """Ce qu'un nom devient : le nom seul, et son conditionnement."""

    name: str
    size: str | None


def _bare(word: str) -> str:
    """Le mot sans sa décoration d'enseigne : l'astérisque, le dièse ou la
    puce qu'un ticket colle à un calibre (« *230G »)."""
    return "".join(char for char in word if char.isalnum())


def _run(words: list[str], part: str, bare: bool = False) -> bool:
    """`part` est-il une suite contiguë de mots de `words` ?"""
    taken = [_bare(word) for word in part.split()] if bare else part.split()
    reference = [_bare(word) for word in words] if bare else words
    if not taken:
        return False
    return any(
        reference[start : start + len(taken)] == taken
        for start in range(len(reference) - len(taken) + 1)
    )


def accepted(original: str, split: Split) -> bool:
    """Le découpage proposé ne dit-il que ce que le nom original dit déjà ?

    Le **nom** se compare au caractère près : il sera aligné sur les mots de
    sa ligne (`truth/spans.py`), et une casse ou une ponctuation retouchée le
    rendrait introuvable. Le **conditionnement** est un champ dérivé, aligné
    sur rien : on lui demande seulement de n'avoir rien inventé, décoration
    d'enseigne mise à part."""
    words = original.split()
    if not split.name or not any(char.isalpha() for char in split.name):
        return False
    if not _run(words, split.name):
        return False
    return split.size is None or _run(words, split.size, bare=True)


def applied(entry: dict, table: dict[str, Split]) -> dict:
    """L'entrée d'annotation, nom coupé et conditionnement posé."""
    if entry.get("role") != ITEM:
        return entry
    split = table.get((entry.get("name") or "").strip())
    if split is None:
        return entry
    updated = {**entry, "name": split.name}
    if split.size:
        updated["size"] = split.size
    return updated


def golden_item(item: dict, table: dict[str, Split]) -> dict:
    """L'article d'un golden, nom coupé et conditionnement posé.

    Le golden est la **seconde** source du découpage (`train_span.labelled`).
    Ne corriger que l'annotation avait rendu les deux contradictoires sur
    exactement la frontière en jeu : mesuré, l'intervalle exact sur T1-test
    tombait de 94,2 % à 88,7 % — le modèle n'apprenait plus une convention,
    il en arbitrait deux."""
    split = table.get((item.get("name") or "").strip())
    if split is None:
        return item
    updated = {**item, "name": split.name}
    if split.size:
        updated["size"] = split.size
    return updated


def rewrite_golden(table: dict[str, Split], dry_run: bool) -> Counter[str]:
    tally: Counter[str] = Counter()
    for split_dir in sorted(GOLDEN_DIR.iterdir()):
        if not split_dir.is_dir():
            continue
        for path in sorted(split_dir.glob("*.json")):
            payload = json.loads(path.read_text())
            receipt = payload.get("receipt") or {}
            items = receipt.get("items")
            if not items:
                continue
            renamed = [golden_item(item, table) for item in items]
            if renamed == items:
                continue
            tally["tickets golden modifiés"] += 1
            tally["articles golden modifiés"] += sum(
                1 for before, after in zip(items, renamed) if before != after
            )
            if dry_run:
                continue
            payload["receipt"] = {**receipt, "items": renamed}
            path.write_text(json.dumps(payload, ensure_ascii=False, indent=2))
    return tally


def table_from(paths: list[Path]) -> tuple[dict[str, Split], Counter[str]]:
    """La table des découpages, un lot après l'autre, refusés compris."""
    table: dict[str, Split] = {}
    tally: Counter[str] = Counter()
    for path in paths:
        for original, proposal in json.loads(path.read_text()).items():
            split = Split(
                name=(proposal.get("name") or "").strip(),
                size=(proposal.get("size") or None),
            )
            tally["proposés"] += 1
            if not accepted(original, split):
                tally["refusés"] += 1
                continue
            tally["retenus"] += 1
            if split.size:
                tally["avec conditionnement"] += 1
            if split.name != original:
                tally["nom raccourci"] += 1
            table[original] = split
    return table, tally


def _boundary(original: str, split: Split) -> bool:
    """Le conditionnement était-il en tête ou en queue du nom original ?"""
    words = original.split()
    if not split.size or not words:
        return False
    taken = [_bare(word) for word in split.size.split()]
    bare = [_bare(word) for word in words]
    return bare[: len(taken)] == taken or bare[-len(taken) :] == taken


def inconsistencies(table: dict[str, Split]) -> dict[str, tuple[int, int]]:
    """Les conditionnements traités de deux façons différentes.

    C'est le défaut qu'on répare, retourné contre le correctif lui-même : si
    un même token est coupé ici et gardé là, la découpe a reproduit le
    pile-ou-face de l'annotation, à une autre échelle. Un lot est cohérent
    avec lui-même par construction — c'est entre lots que ça se vérifie."""
    verdicts: dict[str, list[int]] = {}
    for original, split in table.items():
        if not _boundary(original, split):
            continue
        verdicts.setdefault(_bare(split.size or "").upper(), []).append(
            int(split.name != original)
        )
    return {
        token: (sum(votes), len(votes))
        for token, votes in verdicts.items()
        if 0 < sum(votes) < len(votes)
    }


def rewrite(table: dict[str, Split], dry_run: bool) -> Counter[str]:
    tally: Counter[str] = Counter()
    for corpus in sorted(ANNOTATIONS_DIR.iterdir()):
        if not corpus.is_dir():
            continue
        for path in sorted(corpus.glob("*.json")):
            payload = json.loads(path.read_text())
            annotation = payload.get("annotation")
            if not annotation or not annotation.get("lines"):
                continue
            entries = [applied(entry, table) for entry in annotation["lines"]]
            if entries == annotation["lines"]:
                continue
            tally["tickets modifiés"] += 1
            tally["articles modifiés"] += sum(
                1
                for before, after in zip(annotation["lines"], entries)
                if before != after
            )
            if dry_run:
                continue
            record.write(
                path,
                image=payload["image"],
                lines=record.lines_of(payload),
                entries=entries,
                store=annotation.get("store"),
                date=annotation.get("date"),
                provenance=payload.get("provenance") or {},
            )
    return tally


def main(argv: list[str]) -> int:
    dry_run = "--dry-run" in argv
    paths = [Path(a) for a in argv if not a.startswith("--")]
    if not paths:
        print(__doc__)
        return 1
    table, tally = table_from(paths)
    for reason, count in tally.most_common():
        print(f"  {reason:<24}{count:>6}")

    mixed = inconsistencies(table)
    coupes = sum(count for count, _ in mixed.values())
    total = sum(occurrences for _, occurrences in mixed.values())
    print(f"\n  conditionnements en frontière traités des deux façons : {len(mixed)}")
    if mixed:
        print(f"  soit {coupes} coupés sur {total} occurrences concernées")
        for token, (cut, seen) in sorted(mixed.items(), key=lambda item: -item[1][1])[
            :10
        ]:
            print(f"    {token:<12}coupé {cut:>4} / gardé {seen - cut:>4}")

    written = rewrite(table, dry_run) if "--golden" not in argv else Counter()
    written += rewrite_golden(table, dry_run) if "--golden" in argv else Counter()
    print(f"\n{'(à blanc) ' if dry_run else ''}corpus réécrit")
    for reason, count in written.most_common():
        print(f"  {reason:<26}{count:>6}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
