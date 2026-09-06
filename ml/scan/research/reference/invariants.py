"""Invariants structurels d'un ticket, calculés sans modèle.

Trois familles de preuves arithmétiques, indépendantes du classifieur :

- décomposition TVA : un montant HT et un montant de taxe à un taux légal
  (2,1 / 5,5 / 10 / 20 %) prouvent le TTC — leurs lignes ne sont jamais des
  articles, leur somme est une référence. Une ligne qui porte les trois
  montants à la fois (HT + taxe = TTC) est une table de TVA quel que soit le
  mot qui la précède, « TVA » comme « Vat » comme rien du tout ;
- espèces − rendu : deux lignes imprimées prouvent le montant réglé ;
- récapitulatif de remises : un montant égal, au signe près, à la somme des
  remises qui le précèdent totalise des ristournes — qu'il soit imprimé
  négatif (« REMISE TOTALE -5,10 ») ou positif (« Total remise: 58,98 ») —
  et n'est donc jamais la somme due ;

plus l'éligibilité des références : les totaux de rayon (« TOTAL
ALIMENTAIRE ») précèdent toujours le total final, un sous-total ou un
montant HT ne sert jamais de référence. Tout est gated par le checksum.
"""

from __future__ import annotations

from dataclasses import dataclass

from reference.line_features import PricedLine
from reference.structure import (
    DISCOUNT_WORDS,
    EXCLUDED_TOTAL_WORDS,
    PAYMENT_WORDS,
    SUBTOTAL_WORDS,
    TAX_INCLUSIVE_WORDS,
    TVA_WORDS,
    _contains,
    contains_total,
    parse_price,
)

TAX = "tax"
PAYMENT_CHANGE = "payment_change"
TOTAL_LINE = "total_line"
SECTIONS = "sections"
MIN_BARE_SECTION_LINES = 2
MIN_SECTIONS_FOR_EVIDENCE = 2
MIN_RECAP_DISCOUNTS = 2

TAX_RATES = (0.021, 0.055, 0.10, 0.20)
TAX_TOLERANCE_CENTS = 1.0
RATE_LITERALS = frozenset(
    {"20.00", "20,00", "10.00", "10,00", "5.50", "5,50", "2.10", "2,10"}
)
RATE_PERCENTAGES = frozenset(
    {"20", "10", "5.5", "5,5", "2.1", "2,1", "20.00", "20,00", "10.00", "10,00"}
)
HT_WORDS = ("HT", "H.T", "NET", "TTL", "BASE")
CHANGE_WORDS = ("RENDU", "RENDRE", "MONNAIE", "CHANGE")


@dataclass(frozen=True)
class Evidence:
    cents: int
    cutoff_rank: int
    source: str
    line_rank: int | None


@dataclass(frozen=True)
class Constraints:
    forced_ignore: frozenset[int]
    reference_ranks: frozenset[int]
    evidences: tuple[Evidence, ...]
    soft_ignore: frozenset[int] = frozenset()


def _cents(price: float) -> int:
    return round(price * 100)


def _is_rate_token(token: str) -> bool:
    if token in RATE_LITERALS:
        return True
    return token.endswith("%") and token[:-1] in RATE_PERCENTAGES


MIN_TABLE_ROW_AMOUNTS = 2


def _carries_its_own_tax_split(amounts: list[int]) -> bool:
    """La ligne porte elle-même sa décomposition : deux de ses montants font
    le troisième, et leur rapport est un taux de TVA légal. Aucune enseigne
    n'imprime ça sur un article — et aucun mot n'est nécessaire pour le
    voir, ce qui rend la lecture indépendante de « TVA », « VAT » ou « MWST »."""
    for index, ttc in enumerate(amounts):
        rest = amounts[:index] + amounts[index + 1 :]
        for position, ht in enumerate(rest):
            for tax in rest[position + 1 :]:
                if ht + tax != ttc:
                    continue
                if _tax_matches(ht, tax) or _tax_matches(tax, ht):
                    return True
    return False


def _is_tax_row(priced: PricedLine) -> bool:
    """Lexique taxe, ligne de table TVA « taux HT taxe [TTC] » — un taux
    seul ne suffit pas, 5,50 ou 20,00 sont aussi des prix d'article — ou
    ligne portant sa propre décomposition HT + taxe = TTC."""
    if _contains(priced.line.text, TVA_WORDS):
        return True
    amounts = _row_amounts(priced)
    if _carries_its_own_tax_split(amounts):
        return True
    has_rate = any(_is_rate_token(word.text) for word in priced.line.words)
    return has_rate and len(amounts) >= MIN_TABLE_ROW_AMOUNTS


def _row_amounts(priced: PricedLine) -> list[int]:
    amounts = []
    for word in priced.line.words:
        if _is_rate_token(word.text):
            continue
        price = parse_price(word.text)
        if price is not None and price != 0:
            amounts.append(abs(_cents(price)))
    return amounts


def _tax_matches(ht_cents: int, tax_cents: int) -> bool:
    return any(
        abs(tax_cents - ht_cents * rate) <= TAX_TOLERANCE_CENTS for rate in TAX_RATES
    )


def _is_excluded_total(text: str) -> bool:
    return _contains(text, EXCLUDED_TOTAL_WORDS) and not _contains(
        text, TAX_INCLUSIVE_WORDS
    )


def _is_ht_line(priced: PricedLine) -> bool:
    text = priced.line.text
    if not _contains(text, HT_WORDS):
        return False
    return not contains_total(text) or _is_excluded_total(text)


@dataclass(frozen=True)
class TaxPair:
    ht: int
    tax: int
    partner_rank: int | None
    printed: bool


def _row_pairs(
    rank: int, amounts: list[int], partners: dict[int, list[int]], used: set[int]
) -> list[TaxPair]:
    """Couples (HT, taxe) plausibles pour une ligne de taxe : sur la ligne
    elle-même, ou avec une ligne HT voisine. Un TTC et son HT tombent tous
    deux à un cent de la taxe sur les petits montants : le couple dont la
    somme est imprimée l'emporte, puis la même ligne, puis la plus proche."""
    pairs = [
        TaxPair(ht, tax, None, ht + tax in amounts)
        for tax in sorted(amounts)
        for ht in amounts
        if ht > tax and _tax_matches(ht, tax)
    ]
    for tax in sorted(amounts):
        for partner_rank in sorted(partners, key=lambda r: abs(r - rank)):
            if partner_rank == rank or partner_rank in used:
                continue
            for ht in partners[partner_rank]:
                if ht > tax and _tax_matches(ht, tax):
                    pairs.append(TaxPair(ht, tax, partner_rank, ht + tax in amounts))
    return pairs


def _best_pair(pairs: list[TaxPair], rank: int) -> TaxPair | None:
    if not pairs:
        return None
    return min(
        pairs,
        key=lambda pair: (
            not pair.printed,
            pair.partner_rank is not None,
            abs((pair.partner_rank if pair.partner_rank is not None else rank) - rank),
        ),
    )


def tax_evidence(lines: list[PricedLine]) -> tuple[Evidence | None, set[int]]:
    """TTC prouvé par HT + taxe à taux légal, ligne par ligne de taxe ; les
    lignes consommées (taxe et HT) ne sont jamais des articles."""
    tax_rows = {rank for rank, priced in enumerate(lines) if _is_tax_row(priced)}
    partners = {
        rank: _row_amounts(priced) if rank in tax_rows else [_cents(priced.price)]
        for rank, priced in enumerate(lines)
        if rank in tax_rows or (_is_ht_line(priced) and priced.price > 0)
    }
    used: set[int] = set()
    ttc_total = 0
    for rank in sorted(tax_rows):
        if rank in used:
            continue
        pair = _best_pair(
            _row_pairs(rank, _row_amounts(lines[rank]), partners, used), rank
        )
        if pair is None:
            continue
        ttc_total += pair.ht + pair.tax
        used.add(rank)
        if pair.partner_rank is not None:
            used.add(pair.partner_rank)
    if not used:
        return None, set()
    return Evidence(ttc_total, min(used), TAX, None), used


def _is_change_line(priced: PricedLine) -> bool:
    return _contains(priced.line.text, CHANGE_WORDS)


def payment_change_evidence(lines: list[PricedLine]) -> Evidence | None:
    """Espèces données − monnaie rendue = montant réglé. Le paiement retenu
    est le plus grand avant la ligne de rendu : c'est l'argent donné."""
    change_rank = next(
        (
            rank
            for rank, priced in enumerate(lines)
            if _is_change_line(priced) and _cents(priced.price) != 0
        ),
        None,
    )
    if change_rank is None:
        return None
    payments = [
        (_cents(priced.price), rank)
        for rank, priced in enumerate(lines[:change_rank])
        if _contains(priced.line.text, PAYMENT_WORDS)
        and not _is_change_line(priced)
        and priced.price > 0
    ]
    if not payments:
        return None
    given, payment_rank = max(payments)
    settled = given - abs(_cents(lines[change_rank].price))
    if settled <= 0:
        return None
    return Evidence(settled, payment_rank, PAYMENT_CHANGE, None)


def _is_subtotal(priced: PricedLine) -> bool:
    return _contains(priced.line.text, SUBTOTAL_WORDS)


def _is_final_total_candidate(priced: PricedLine) -> bool:
    text = priced.line.text
    return (
        contains_total(text)
        and not _is_subtotal(priced)
        and not _is_excluded_total(text)
    )


def _first_payment_rank(lines: list[PricedLine]) -> int | None:
    return next(
        (
            rank
            for rank, priced in enumerate(lines)
            if _contains(priced.line.text, PAYMENT_WORDS)
            and not _is_change_line(priced)
        ),
        None,
    )


def discount_recap_ranks(lines: list[PricedLine]) -> set[int]:
    """Rangs dont le montant, au signe près, égale la somme des remises qui
    les précèdent : un récapitulatif de ristournes, jamais une somme due.

    Purement arithmétique — l'enseigne peut l'imprimer positif (« Total
    remise: 58,98 ») comme négatif, avec ou sans le mot « total ». Deux
    remises réelles au minimum : une seule remise recopiée plus bas serait
    indiscernable d'un article au même prix."""
    recaps: set[int] = set()
    discounts: list[int] = []
    for rank, priced in enumerate(lines):
        cents = _cents(priced.price)
        if cents == 0:
            continue
        if len(discounts) >= MIN_RECAP_DISCOUNTS and abs(cents) == sum(
            abs(c) for c in discounts
        ):
            recaps.add(rank)
            continue
        if cents < 0:
            discounts.append(cents)
    return recaps


def _last_total_rank(lines: list[PricedLine]) -> int | None:
    """Le total à payer est le dernier total lexical AVANT le premier
    paiement : un « Total bon immédiat » imprimé après la carte n'est pas
    le total du ticket. Un récapitulatif de remises ne compte jamais, quel
    que soit le mot qui le précède."""
    recaps = discount_recap_ranks(lines)
    ranks = [
        rank
        for rank, priced in enumerate(lines)
        if _is_final_total_candidate(priced)
        and rank not in recaps
        and not _carries_its_own_tax_split(_row_amounts(priced))
    ]
    if not ranks:
        return None
    payment = _first_payment_rank(lines)
    before_payment = [rank for rank in ranks if payment is None or rank < payment]
    return before_payment[-1] if before_payment else ranks[-1]


def summary_discount_ranks(lines: list[PricedLine]) -> set[int]:
    """Une remise égale à la somme des remises réelles qui la précèdent est
    un récapitulatif — si elle porte le mot total, ou si au moins deux
    remises la précèdent (deux remises identiques ne sont pas un récap)."""
    last_total = _last_total_rank(lines)
    scope = lines if last_total is None else lines[:last_total]
    real: list[int] = []
    summaries: set[int] = set()
    for rank, priced in enumerate(scope):
        cents = _cents(priced.price)
        text = priced.line.text
        if cents >= 0 and not _contains(text, DISCOUNT_WORDS):
            continue
        is_total_line = contains_total(text)
        recap = real and abs(cents) == sum(abs(c) for c in real)
        if recap and (len(real) >= 2 or is_total_line):
            summaries.add(rank)
            continue
        if not is_total_line:
            real.append(cents)
    return summaries


def _discount_follows(lines: list[PricedLine], rank: int) -> bool:
    scope = _section_scope(lines)
    return any(
        _cents(priced.price) < 0 or _contains(priced.line.text, DISCOUNT_WORDS)
        for priced in lines[rank + 1 : scope]
    )


def _items_follow(lines: list[PricedLine], rank: int) -> bool:
    return any(
        _is_item_candidate(priced, set(), other)
        for other, priced in enumerate(
            lines[rank + 1 : _section_scope(lines)], start=rank + 1
        )
    )


def _closes_the_items(lines: list[PricedLine], rank: int) -> bool:
    """Un total intermédiaire que ne suivent ni article ni remise (seulement
    des taxes ou le total final) vérifie les articles : c'est le « net
    total » avant taxes, pas un total de rayon."""
    return not _items_follow(lines, rank) and not _discount_follows(lines, rank)


def _is_intermediate_reference(
    lines: list[PricedLine], rank: int, sections: list[int]
) -> bool:
    """Un total ou sous-total intermédiaire vérifie les articles s'il les
    clôt tous (ni article ni remise après lui) et qu'aucun total de rayon
    ne le précède : le « net total » avant taxes, pas le dernier rayon."""
    priced = lines[rank]
    if not (contains_total(priced.line.text) or _is_subtotal(priced)):
        return False
    cents = _cents(priced.price)
    if any(
        section < rank and _cents(lines[section].price) != cents for section in sections
    ):
        return False
    return _closes_the_items(lines, rank)


def reference_ranks(lines: list[PricedLine]) -> set[int]:
    """Rangs pouvant porter la référence total : jamais un montant HT ; tout
    après le total final sauf un sous-total ; avant lui, seulement un total
    intermédiaire qui clôt les articles."""
    last_total = _last_total_rank(lines)
    sections = section_totals(lines)
    return {
        rank
        for rank, priced in enumerate(lines)
        if not _is_excluded_total(priced.line.text)
        and _is_eligible_reference(lines, rank, last_total, sections)
    }


def _is_eligible_reference(
    lines: list[PricedLine], rank: int, last_total: int | None, sections: list[int]
) -> bool:
    priced = lines[rank]
    if last_total is None:
        return not (_is_subtotal(priced) and _discount_follows(lines, rank))
    if rank >= last_total:
        return not _is_subtotal(priced)
    return _is_intermediate_reference(lines, rank, sections)


def _is_lexical(priced: PricedLine) -> bool:
    text = priced.line.text
    return (
        contains_total(text)
        or _is_subtotal(priced)
        or _contains(text, PAYMENT_WORDS)
        or _contains(text, TVA_WORDS)
        or _contains(text, DISCOUNT_WORDS)
        or _is_change_line(priced)
    )


def _is_item_candidate(priced: PricedLine, excluded: set[int], rank: int) -> bool:
    return priced.price > 0 and rank not in excluded and not _is_lexical(priced)


def section_totals(
    lines: list[PricedLine], excluded: set[int] | None = None
) -> list[int]:
    """Totaux de rayon : une ligne dont le montant égale la somme courante
    des articles depuis le rayon précédent. Sans lexique il faut au moins
    deux articles (un article ne vaut pas un autre par hasard) ; une ligne
    total lexicale ferme un rayon dès un article."""
    excluded = excluded or set()
    sections: list[int] = []
    running = 0
    count = 0
    last_total = _last_total_rank(lines)
    for rank, priced in enumerate(lines[: _section_scope(lines)]):
        cents = _cents(priced.price)
        if rank in excluded or cents <= 0:
            continue
        minimum = 1 if contains_total(priced.line.text) else MIN_BARE_SECTION_LINES
        closes_last_total = rank == last_total and not sections
        if count >= minimum and cents == running and not closes_last_total:
            sections.append(rank)
            running = 0
            count = 0
            continue
        if _is_item_candidate(priced, excluded, rank):
            running += cents
            count += 1
    return sections


def _section_scope(lines: list[PricedLine]) -> int:
    """Les rayons s'arrêtent au dernier total lexical inclus : quand le total
    à payer est illisible, la dernière ligne « Total » lue est un rayon."""
    last_total = _last_total_rank(lines)
    return len(lines) if last_total is None else last_total + 1


def _sections_cover_items(
    lines: list[PricedLine], sections: list[int], excluded: set[int]
) -> bool:
    last_total = _last_total_rank(lines)
    scope = len(lines) if last_total is None else last_total
    return not any(
        _is_item_candidate(lines[rank], excluded, rank)
        for rank in range(sections[-1] + 1, scope)
    )


def _sections_evidence(
    lines: list[PricedLine], sections: list[int], excluded: set[int]
) -> Evidence | None:
    if len(sections) < MIN_SECTIONS_FOR_EVIDENCE:
        return None
    if not _sections_cover_items(lines, sections, excluded):
        return None
    total = sum(_cents(lines[rank].price) for rank in sections)
    return Evidence(total, sections[-1], SECTIONS, None)


def constraints(lines: list[PricedLine]) -> Constraints:
    tax, tax_ignored = tax_evidence(lines)
    summaries = summary_discount_ranks(lines)
    forced = frozenset(tax_ignored | summaries | discount_recap_ranks(lines))
    sections = section_totals(lines, set(forced))
    evidences: list[Evidence] = []
    if tax is not None:
        evidences.append(tax)
    settled = payment_change_evidence(lines)
    if settled is not None:
        evidences.append(settled)
    by_sections = _sections_evidence(lines, sections, set(forced))
    if by_sections is not None:
        evidences.append(by_sections)
    last_total = _last_total_rank(lines)
    if last_total is not None and lines[last_total].price > 0:
        evidences.append(
            Evidence(
                _cents(lines[last_total].price), last_total, TOTAL_LINE, last_total
            )
        )
    return Constraints(
        forced_ignore=forced,
        reference_ranks=frozenset(reference_ranks(lines) - forced),
        evidences=tuple(evidences),
        soft_ignore=frozenset(sections),
    )
