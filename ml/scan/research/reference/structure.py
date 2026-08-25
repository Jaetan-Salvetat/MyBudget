"""Structure les lignes physiques d'un ticket en articles + prix + remises.

Règles géométriques et lexicales pures, sans modèle : l'objectif est de
mesurer jusqu'où elles montent avant de décider si un classifieur de lignes
est nécessaire.
"""

from __future__ import annotations

import re
import unicodedata
from dataclasses import dataclass, field

from reference.lines import PhysicalLine, Word, cluster_lines

PRICE_PATTERN = re.compile(r"^-?\d{1,4}[.,]\d{2}$")
QUANTITY_PATTERN = re.compile(r"^(\d{1,2})[xX*](-?\d{1,4}[.,]\d{2})$")
WEIGHT_PATTERN = re.compile(
    r"^\d{1,3}[.,]\d{1,3}\s?[Kk]?[Gg][xX*]\d{1,4}[.,]\d{1,2}.*$"
)
# Un numéro de téléphone français, retiré du texte avant toute recherche de
# date. Sans ce masque, « 05.46.27.02.12 » se lit « 27.02.12 » : mesuré, 170
# tickets de plus repartaient avec une fausse date. Le masquer vaut mieux
# qu'un garde-fou sur la date elle-même, qui rejetait aussi les dates
# légitimement encadrées de séparateurs (« /000003/07/01/2017/ »).
#
# Le séparateur doit être présent et le *même* entre les cinq paires. Sans
# l'exiger identique, « 08-03-2017 12:42 » compacté ressemblait à un numéro ;
# sans l'exiger présent, le masque avalait les codes de caisse — un ticket est
# plein de suites de dix chiffres commençant par zéro, et « 0002 G04 000643
# 22/02/2017 » y perdait sa date. Un numéro imprimé sans séparateur ne se
# confond avec aucune date, il n'a pas besoin d'être masqué.
PHONE_PATTERN = re.compile(r"(?<!\d)0\d([.\-])\d{2}(?:\1\d{2}){3}(?!\d)")

# Une date de ticket, année sur quatre chiffres ou sur deux. L'année courte
# exige une frontière à droite, sinon elle mord sur l'heure que le compactage
# des espaces a recollée (« 13/03/17 20:30 » → « 13/03/1720:30 »).
# Jour et mois peuvent n'avoir qu'un chiffre (« 7/10/15 », « 14/1/17 ») : le
# masque des numéros et la validation calendaire tiennent les faux positifs.
DATE_PATTERN = re.compile(
    r"(\d{1,2})[/.-](\d{1,2})[/.-](\d{4}|\d{2}(?![\d./-]))"
)

# Mois en toutes lettres ou abrégé : un ticket sur six de T1-test l'imprime
# ainsi. Les accents sont retirés en amont, la casse est indifférente.
MONTH_NAMES = (
    "JANV|JAN",
    "FEVR|FEV",
    "MARS|MAR",
    "AVRIL|AVR",
    "MAI",
    "JUIN|JUN",
    "JUILLET|JUIL|JUL",
    "AOUT|AOU",
    "SEPTEMBRE|SEPT|SEP",
    "OCTOBRE|OCT",
    "NOVEMBRE|NOV",
    "DECEMBRE|DEC",
)
LITERAL_DATE_PATTERN = re.compile(
    r"(\d{1,2})(?:ER)?[/.\- ]?(" + "|".join(MONTH_NAMES) + r")[A-Z]*[/.\- ]?(\d{4}|\d{2})",
    re.IGNORECASE,
)
# Bornes d'une date de ticket : au-delà, l'année lue n'en est pas une.
MIN_YEAR, MAX_YEAR = 1990, 2035
MAX_DAY, MAX_MONTH = 31, 12
# Pivot POSIX pour les années sur deux chiffres. Un ticket de caisse est
# toujours du siècle courant, mais le pivot coûte moins qu'une hypothèse.
CENTURY_PIVOT = 70
INTEGER_PATTERN = re.compile(r"^-?\d{1,4}$")
DECIMALS_PATTERN = re.compile(r"^[.,]?\d{2}$")
LEADER_DOTS_PATTERN = re.compile(r"^[.…]+")

DISCOUNT_WORDS = (
    "REMISE",
    "AVANTAGE",
    "RISTOURNE",
    "PROMO",
    "FID",
    "GRATUIT",
    "DISCOUNT",
    "COUPON",
    "SAVINGS",
)
TOTAL_WORDS = (
    "TOTAL",
    "TOT",
    "PAYER",
    "MONTANT DU",
    "AMOUNT DUE",
    "BALANCE DUE",
    "TOT TTC",
    "NET A REGLER",
    "A REGLER",
    "DOIT",
    "PRIX TTC",
    "MONTANT TTC",
)
FUZZY_TOTAL_WORD = "TOTAL"
FUZZY_TOTAL_MAX_DISTANCE = 1
FUZZY_TOTAL_TOKEN_LENGTHS = range(4, 7)
SUBTOTAL_WORDS = (
    "SOUS-TOTAL",
    "SOUS TOTAL",
    "SOUS TOT",
    "SUBTOTAL",
    "SUB-TOTAL",
    "SUB TOTAL",
    "S/TOTAL",
    "S/TOT",
    "AMOUNT",
    "TAXABLE",
)
STOP_WORDS = (
    "TOTAL",
    "PAYER",
    "SOUS-TOTAL",
    "TVA",
    "TUA",
    "CB ",
    "CARTE BANCAIRE",
    "ESPECES",
    "RENDU",
    "A RENDRE",
    "MONNAIE",
    "CHEQUE",
    "ARTICLE(",
    "ARTICLES",
    "MERCI",
    "BIENTOT",
    "TEL",
    "SIRET",
    "CAISSE",
    "TICKET",
    "TTC",
    "EMV",
    "SANS CONTACT",
    "COUVERT",
    "VISITE",
    "MWST",
    "MUST",
    "INCL",
    "DUPLICATA",
    "DOCUMENT",
    "TAX",
    "CASH",
    "CHANGE",
    "TIP",
    "GRATUITY",
    "VISA",
    "MASTERCARD",
    "DEBIT",
    "CREDIT",
    "BALANCE",
    "TEND",
    "APPROVED",
    "AUTH",
    "SERVER",
    "GUEST",
    "THANK",
    "WELCOME",
    "CUMUL",
    "FIDELITE",
    "CARTE BLEUE",
    "TOTAUX",
    "SOLDE",
    "PAIEMENT",
    "REGLEMENT",
    "PERCU",
    "RECU",
)

EXCLUDED_TOTAL_WORDS = (
    "HT",
    "H.T",
    "TVA",
    "TUA",
    "ELIGIBLE",
    "POINTS",
    "FRANC",
    "FRF",
)

PAYMENT_WORDS = (
    "CB",
    "CARTE BANCAIRE",
    "CARTES BANCAIRES",
    "CARTE BLEUE",
    "VISA",
    "MASTERCARD",
    "SANS CONTACT",
    "EMV",
    "ESPECES",
    "CHEQUE",
    "PAIEMENT",
    "REGLEMENT",
    "MONTANT PERCU",
    "PERCU",
    "RECU",
)
TVA_WORDS = ("TVA", "TUA", "TAX", "TAXE", "TAXES")
TAX_INCLUSIVE_WORDS = ("INCL",)
MISSING_SEPARATOR_TOTAL_PATTERN = re.compile(r"(\d{3,6})\s*$")
ARTICLE_COUNT_PATTERN = re.compile(r"(\d{1,3})ARTICLE")


@dataclass
class ExtractedItem:
    name: str
    amount: float
    discount: float
    # Ligne dont l'article vient. Sans elle, impossible de confronter un
    # libellé à ce que le tagger de rôles dit de son voisinage — et 84 des
    # 131 tickets aux articles faux ont les bons montants, seul le libellé
    # est allé chercher la mauvaise ligne.
    line_index: int | None = None


@dataclass
class ExtractedReceipt:
    store: str | None
    date: str | None
    total: float | None
    subtotal: float | None
    payment: float | None
    items: list[ExtractedItem]
    tva_ttc_sum: float | None = None
    printed_count: int | None = None
    fallback_references: list[float] = field(default_factory=list)

    @property
    def items_sum(self) -> float:
        return round(sum(item.amount - item.discount for item in self.items), 2)

    @property
    def checksum_ok(self) -> bool:
        """La somme des articles doit retomber sur un montant imprimé : le
        total TTC en Europe, ou le sous-total hors taxe aux États-Unis. Le
        montant débité par carte ne sert de référence que si aucun total n'a
        été lu : quand un total lu ne colle pas, on flague — accepter sur la
        seule ligne de paiement laisserait passer des extractions fausses.
        Deux références de secours mesurées sur corpus : la somme des TTC de
        la table TVA (décomposition imprimée du total), et la ligne CB quand
        le compteur « N ARTICLE(S) » confirme qu'aucun article ne manque."""
        if self._matches(self.total) or self._matches(self.subtotal):
            return True
        if self.total is None and self._matches(self.tva_ttc_sum):
            return True
        if self.total is None and any(
            self._matches(candidate) for candidate in self.fallback_references
        ):
            return True
        if self._matches(self.payment):
            if self.total is None:
                return True
            if self.printed_count == len(self.items):
                return True
        return False

    @property
    def verified_total(self) -> float | None:
        """Le montant qui a réellement vérifié la somme des articles — c'est
        lui qu'on affiche, jamais un total lu qui ne colle pas."""
        if self._matches(self.total):
            return self.total
        if self._matches(self.subtotal):
            return self.subtotal
        if self.total is None and self._matches(self.tva_ttc_sum):
            return self.tva_ttc_sum
        if self.total is None:
            for candidate in self.fallback_references:
                if self._matches(candidate):
                    return candidate
        if self.checksum_ok and self._matches(self.payment):
            return self.payment
        return None

    def _matches(self, reference: float | None) -> bool:
        return reference is not None and abs(self.items_sum - reference) < 0.005


GLYPH_PRICE_PATTERN = re.compile(r"^-?[\dIlOoS]{1,4}[.,][\dIlOoS]{2}$")
GLYPH_TRANSLATION = str.maketrans("IlOoS", "11005")
DAMAGED_SEPARATOR_TRANSLATION = str.maketrans(";", ",")
LEADING_PUNCTUATION = ":"


def parse_price(text: str) -> float | None:
    normalized = text.translate(DAMAGED_SEPARATOR_TRANSLATION).lstrip(
        LEADING_PUNCTUATION
    )
    cleaned = LEADER_DOTS_PATTERN.sub(
        "", normalized.replace("€", "").replace("$", "").strip("eE")
    )
    cleaned = re.sub(r"([.,]\d{2})[A-Za-z]$", r"\1", cleaned)
    if not PRICE_PATTERN.match(cleaned):
        cleaned = _deglyphed(cleaned)
        if cleaned is None:
            return None
    try:
        return float(cleaned.replace(",", "."))
    except ValueError:
        return None


def _deglyphed(text: str) -> str | None:
    """Prix dont l'OCR a confondu un chiffre avec une lettre (« 2.I8 »).
    Substitution seulement quand la forme est clairement un prix et que les
    chiffres restent majoritaires : le checksum valide derrière."""
    if not GLYPH_PRICE_PATTERN.match(text):
        return None
    digits = sum(char.isdigit() for char in text)
    letters = sum(char.isalpha() for char in text)
    if letters == 0 or digits < 2 * letters:
        return None
    candidate = text.translate(GLYPH_TRANSLATION)
    return candidate if PRICE_PATTERN.match(candidate) else None


FRAGMENT_HEAD_PATTERN = re.compile(r"^-?\d{1,4}[.,]$")
FRAGMENT_TAIL_PATTERN = re.compile(r"^\d{2}[€eE]?$")


def merge_price_fragments(line: PhysicalLine) -> PhysicalLine:
    """Refusionne un prix que l'OCR a coupé au séparateur décimal
    (« -1, 00 », « 5. 16 ») quand les deux morceaux se touchent presque."""
    words = list(line.words)
    merged: list[Word] = []
    index = 0
    while index < len(words):
        word = words[index]
        if index + 1 < len(words):
            tail = words[index + 1]
            gap = tail.left - word.right
            close_enough = gap < (word.bottom - word.top) * 1.2
            if (
                FRAGMENT_HEAD_PATTERN.match(word.text)
                and FRAGMENT_TAIL_PATTERN.match(tail.text)
                and close_enough
            ):
                merged.append(
                    Word(
                        text=word.text + tail.text,
                        left=word.left,
                        top=min(word.top, tail.top),
                        right=tail.right,
                        bottom=max(word.bottom, tail.bottom),
                        confidence=_min_confidence(word, tail),
                    )
                )
                index += 2
                continue
        merged.append(word)
        index += 1
    return PhysicalLine(words=merged)


def _min_confidence(first: Word, second: Word) -> float | None:
    scores = [w.confidence for w in (first, second) if w.confidence is not None]
    return min(scores) if scores else None


GLUED_PRICE_PATTERN = re.compile(r"^[A-Za-z]{1,5}(-?\d{1,4}[.,]\d{2})[€eE]?$")
TRAILING_JUNK_PRICE_PATTERN = re.compile(r"^(-?\d{1,4}[.,]\d{2})\S$")


def _rightmost_price(line: PhysicalLine) -> tuple[float, Word] | None:
    for word in reversed(line.words):
        price = parse_price(word.text)
        if price is not None:
            return price, word
    for word in reversed(line.words):
        glued = GLUED_PRICE_PATTERN.match(word.text)
        if glued is not None:
            return float(glued.group(1).replace(",", ".")), word
    if contains_total(line.text):
        return _trailing_junk_price(line) or _split_price(line)
    return None


def _trailing_junk_price(line: PhysicalLine) -> tuple[float, Word] | None:
    """Prix d'une ligne total suivi d'un caractère parasite (« 7.074 »,
    « 3.10D ») : seul le contexte total autorise cette lecture, le checksum
    valide derrière."""
    for word in reversed(line.words):
        junk = TRAILING_JUNK_PRICE_PATTERN.match(word.text)
        if junk is not None:
            return float(junk.group(1).replace(",", ".")), word
    return None


def _split_price(line: PhysicalLine) -> tuple[float, Word] | None:
    """Récupère un prix dont le séparateur décimal n'a pas été lu : les gros
    totaux en gras sortent parfois « 54 50 » en deux mots adjacents."""
    words = line.words
    if len(words) < 2:
        return None
    units, decimals = words[-2], words[-1]
    if not INTEGER_PATTERN.match(units.text) or not DECIMALS_PATTERN.match(
        decimals.text
    ):
        return None
    gap = decimals.left - units.right
    if gap > (units.bottom - units.top) * 1.5:
        return None
    value = float(f"{units.text}.{decimals.text.lstrip('.,')}")
    return value, decimals


def _label_of(line: PhysicalLine, price_word: Word) -> str:
    return " ".join(word.text for word in line.words if word is not price_word)


def levenshtein(left: str, right: str) -> int:
    previous = list(range(len(right) + 1))
    for row, left_char in enumerate(left, start=1):
        current = [row]
        for column, right_char in enumerate(right, start=1):
            current.append(
                min(
                    previous[column] + 1,
                    current[column - 1] + 1,
                    previous[column - 1] + (left_char != right_char),
                )
            )
        previous = current
    return previous[-1]


def contains_total(text: str) -> bool:
    """Lexique total exact, ou un mot à une édition de « TOTAL » (« TO'AL »,
    « OTAL », « T0TAL ») : l'OCR abîme surtout cette ligne, imprimée en gras."""
    if _contains(text, TOTAL_WORDS):
        return True
    return any(
        len(token) in FUZZY_TOTAL_TOKEN_LENGTHS
        and levenshtein(token.upper(), FUZZY_TOTAL_WORD) <= FUZZY_TOTAL_MAX_DISTANCE
        for token in text.split()
    )


def _contains(text: str, lexicon: tuple[str, ...]) -> bool:
    """Compare aussi le texte compacté : l'OCR éclate ou fusionne des mots
    (« Monna ie », « TOTALA PAYER ») et le lexique doit y résister. Les
    entrées courtes exigent une frontière de mot : « TEL » ne doit pas
    matcher dans « TORTELL.PESTO »."""
    upper = "".join(
        char
        for char in unicodedata.normalize("NFD", text.upper())
        if not unicodedata.combining(char)
    )
    compact = re.sub(r"\s+", "", upper)
    undotted = upper.replace(".", "")
    unglyphed = re.sub(r"\s+", "", upper.translate(str.maketrans("015", "OIS")))
    for entry in lexicon:
        stripped = entry.strip()
        if len(stripped) < 5:
            pattern = rf"(?<![A-Z0-9]){re.escape(stripped)}(?![A-Z0-9])"
            if re.search(pattern, upper):
                return True
            dotted = rf"(?<![A-Z]){re.escape(stripped)}(?![A-Z])"
            if re.search(dotted, undotted):
                return True
            continue
        boundary = rf"(?<![A-Z]){re.escape(entry)}(?![A-Z])"
        if re.search(boundary, upper):
            return True
        if entry in upper:
            continue
        squeezed = entry.replace(" ", "")
        if squeezed in compact or squeezed in unglyphed:
            return True
    return False


def _price_column_left(lines: list[PhysicalLine]) -> float | None:
    """Bord gauche minimal des prix : la colonne des prix est à droite du
    ticket, tout prix nettement à gauche (quantités, codes) n'en fait pas
    partie."""
    rights = []
    for line in lines:
        priced = _rightmost_price(line)
        if priced is not None:
            rights.append(priced[1].right)
    if not rights:
        return None
    rights.sort()
    median_right = rights[len(rights) // 2]
    return median_right * 0.75


def extract(
    lines: list[PhysicalLine],
    roles: dict[int, str] | None = None,
) -> ExtractedReceipt:
    """`roles`, si fourni, reçoit le rôle joué par chaque ligne indexée :
    item / discount / total / subtotal / payment / stop — matière première
    d'entraînement du classifieur de lignes (V2)."""
    store = lines[0].text if lines else None
    date = _find_date(lines)
    column_left = _price_column_left(lines)
    merged = [merge_price_fragments(line) for line in lines]
    total_index, total = _find_final_total(merged)
    if roles is not None and total_index is not None:
        roles[total_index] = "total"

    items: list[ExtractedItem] = []
    pending_label: str | None = None
    subtotal: float | None = None
    payment: float | None = None

    for index, line in enumerate(merged):
        text = line.text
        priced = _rightmost_price(line)

        if _contains(text, SUBTOTAL_WORDS) and priced is not None:
            if subtotal is None:
                subtotal = priced[0]
                if roles is not None:
                    roles.setdefault(index, "subtotal")
            pending_label = None
            continue

        if contains_total(text):
            pending_label = None
            continue

        if _contains(text, STOP_WORDS):
            if (
                payment is None
                and priced is not None
                and _contains(text, PAYMENT_WORDS)
            ):
                payment = priced[0]
                if roles is not None:
                    roles.setdefault(index, "payment")
            pending_label = None
            continue

        if total_index is not None and index > total_index:
            continue

        if priced is None:
            pending_label = _plausible_label(text)
            continue

        price, price_word = priced
        if column_left is not None and price_word.right < column_left:
            pending_label = _plausible_label(text)
            continue
        if price == 0:
            pending_label = None
            continue

        label = _label_of(line, price_word).strip()

        if price < 0 or _is_discount_line(label):
            if items:
                items[-1].discount = round(items[-1].discount + abs(price), 2)
                if roles is not None:
                    roles.setdefault(index, "discount")
            pending_label = None
            continue

        compact_label = re.sub(r"EUR|[€]|\s+", "", label)
        quantity_match = QUANTITY_PATTERN.match(compact_label) or WEIGHT_PATTERN.match(
            compact_label
        )
        if quantity_match and pending_label is not None:
            items.append(
                ExtractedItem(
                    name=_clean_name(pending_label),
                    amount=price,
                    discount=0.0,
                    line_index=index,
                )
            )
            if roles is not None:
                roles.setdefault(index, "item")
            pending_label = None
            continue

        if _plausible_label(label) is None:
            if pending_label is not None and _is_detail_line(label):
                items.append(
                    ExtractedItem(
                        name=_clean_name(pending_label),
                        amount=price,
                        discount=0.0,
                        line_index=index,
                    )
                )
                if roles is not None:
                    roles.setdefault(index, "item")
            pending_label = None
            continue

        items.append(
            ExtractedItem(
                name=_clean_name(label),
                amount=price,
                discount=0.0,
                line_index=index,
            )
        )
        if roles is not None:
            roles.setdefault(index, "item")
        pending_label = None

    return ExtractedReceipt(
        store=store,
        date=date,
        total=total,
        subtotal=subtotal,
        payment=payment,
        items=items,
        tva_ttc_sum=_tva_ttc_sum(merged),
        printed_count=_printed_count(merged),
        fallback_references=_fallback_references(merged),
    )


def _fallback_references(merged: list[PhysicalLine]) -> list[float]:
    """Montants de secours pour le checksum, quand le total régulier manque :
    total sans séparateur décimal sur une ligne « total » pâlie (« 2790 » =
    27,90), et prix orphelin d'une ligne sans texte (total en gras dont le
    libellé a été détruit par l'OCR). Jamais utilisés seuls : une somme
    d'articles doit retomber dessus au centime."""
    candidates: list[float] = []
    for line in merged:
        text = line.text
        if contains_total(text) and not (
            _contains(text, EXCLUDED_TOTAL_WORDS)
            and not _contains(text, TAX_INCLUSIVE_WORDS)
        ):
            if _rightmost_price(line) is None and _embedded_price(text) is None:
                match = MISSING_SEPARATOR_TOTAL_PATTERN.search(text)
                if match:
                    candidates.append(round(int(match.group(1)) / 100, 2))
            continue
        letters = sum(char.isalpha() for char in text)
        if letters >= 2:
            continue
        prices = [
            price
            for word in line.words
            if (price := parse_price(word.text)) is not None
        ]
        if len(prices) == 1 and prices[0] > 0:
            candidates.append(prices[0])
    return candidates


def _tva_ttc_sum(merged: list[PhysicalLine]) -> float | None:
    """Somme des TTC de la table TVA (« B TVA 20.00 5.67 1.13 6.80 ») : une
    ligne-tableau porte au moins trois montants, le TTC est le plus à droite.
    Les lignes « TVA 10% : 0,81 » (montant de taxe seul) sont ignorées."""
    total = 0.0
    rows = 0
    for line in merged:
        if not _contains(line.text, TVA_WORDS):
            continue
        prices = [
            price
            for word in line.words
            if (price := parse_price(word.text)) is not None
        ]
        if len(prices) >= 3:
            total += prices[-1]
            rows += 1
    return round(total, 2) if rows else None


def _printed_count(merged: list[PhysicalLine]) -> int | None:
    """Compteur d'articles imprimé (« 11 ARTICLE(S) »), compacté car l'OCR
    éclate ou colle les mots."""
    for line in merged:
        compact = re.sub(r"\s+", "", line.text.upper())
        match = ARTICLE_COUNT_PATTERN.search(compact)
        if match:
            return int(match.group(1))
    return None


def _find_final_total(
    merged: list[PhysicalLine],
) -> tuple[int | None, float | None]:
    """Le total à payer est le DERNIER montant d'une ligne « total » du
    ticket : les enseignes impriment des sous-totaux par rayon
    (« TOTAL ALIMENTAIRE ») avant le « MONTANT A PAYER » final."""
    total_index: int | None = None
    total: float | None = None
    for index, line in enumerate(merged):
        if not contains_total(line.text) or _contains(line.text, SUBTOTAL_WORDS):
            continue
        if _contains(line.text, EXCLUDED_TOTAL_WORDS) and not _contains(
            line.text, TAX_INCLUSIVE_WORDS
        ):
            continue
        priced = _rightmost_price(line)
        price = priced[0] if priced is not None else _embedded_price(line.text)
        if price is not None:
            total_index = index
            total = price
    return total_index, total


def _embedded_price(text: str) -> float | None:
    """Prix soudé au libellé par l'OCR (« TOTAL A PAYER14.59€ »)."""
    match = re.search(r"(\d{1,4}[.,]\d{2})\s*€?\s*$", text)
    if match is None:
        return None
    return float(match.group(1).replace(",", "."))


DETAIL_TOKEN_PATTERN = re.compile(r"^[\d.,()xX*/€%-]*(?:kg|KG|Kg|EUR|[A-Za-z])?$")


def _is_detail_line(label: str) -> bool:
    """Ligne de détail sous un libellé : code-barres + prix (« 3177810004089
    3.13 »), pesée de balance (« 0,070 10,00 »), décomposition pharmacie
    (« (2 x 15,92) »), ou rien du tout (prix seul sur sa ligne). Aucun mot :
    le libellé de l'article est sur la ligne du dessus."""
    stripped = label.strip()
    if not stripped:
        return True
    letters = sum(char.isalpha() for char in stripped)
    if letters > 3:
        return False
    return all(DETAIL_TOKEN_PATTERN.fullmatch(token) for token in stripped.split())


def _is_discount_line(label: str) -> bool:
    """Une ligne de remise commence par un mot du lexique (« REMISE FID. »).
    Un article dont le nom contient « (promotion) » n'en est pas une : seule
    la position en tête distingue les deux."""
    return label.strip().upper().startswith(DISCOUNT_WORDS)


def _clean_name(label: str) -> str:
    """Libellé prêt pour la catégorisation : sans préfixe quantité, sans
    points de conduite ni prix unitaire résiduel."""
    cleaned = re.sub(r"^\d{1,2}\s?(?=[A-Za-zÀ-ÿ])", "", label.strip())
    cleaned = re.sub(r"[.…]{2,}", " ", cleaned)
    cleaned = re.sub(r"\s?-?\d{1,4}[.,]\d{2}[€eE]?$", "", cleaned)
    cleaned = re.sub(r"\s+[€eE]$", "", cleaned)
    return re.sub(r"\s{2,}", " ", cleaned).strip()


def _plausible_label(text: str) -> str | None:
    stripped = text.strip()
    letters = sum(char.isalpha() for char in stripped)
    if letters < 2:
        return None
    if _contains(stripped, STOP_WORDS):
        return None
    return stripped


def _year_of(digits: str) -> str:
    """L'année d'une date de ticket, sur deux ou quatre chiffres.

    Compacter les espaces recolle l'heure à la date (« 13/03/17 20:30 »
    devient « 13/03/1720:30 ») : quatre chiffres qui ne forment pas une année
    plausible sont donc une année sur deux chiffres suivie de l'heure, et
    c'est ainsi qu'il faut les relire."""
    if len(digits) == 4:
        year = int(digits)
        if MIN_YEAR <= year <= MAX_YEAR:
            return digits
        digits = digits[:2]  # l'heure avait été recollée à l'année
    century = 2000 if int(digits) < CENTURY_PIVOT else 1900
    return str(century + int(digits))


def _is_calendar_day(day: str, month: str) -> bool:
    return 1 <= int(day) <= MAX_DAY and 1 <= int(month) <= MAX_MONTH


def _month_number(name: str) -> str:
    """Le rang du mois nommé, sur deux chiffres."""
    upper = name.upper()
    for index, alternatives in enumerate(MONTH_NAMES, start=1):
        if any(upper.startswith(entry) for entry in alternatives.split("|")):
            return f"{index:02d}"
    raise ValueError(f"mois inconnu : {name}")


def _numeric_date(compact: str) -> str | None:
    """L'OCR confond o et 0 dans les chiffres — substitution réservée à cette
    lecture-ci, elle détruirait les mois en lettres (« OCTOBRE »)."""
    digits_only = compact.replace("o", "0").replace("O", "0")
    for match in DATE_PATTERN.finditer(digits_only):
        day, month, year = match.groups()
        if _is_calendar_day(day, month):
            return f"{_year_of(year)}-{int(month):02d}-{int(day):02d}"
    return None


def _literal_date(compact: str) -> str | None:
    """Les mois s'impriment accentués (« août ») : la comparaison se fait sur
    la forme sans accent, comme le reste des lexiques."""
    unaccented = "".join(
        char
        for char in unicodedata.normalize("NFD", compact)
        if not unicodedata.combining(char)
    )
    for match in LITERAL_DATE_PATTERN.finditer(unaccented):
        day, name, year = match.groups()
        month = _month_number(name)
        if _is_calendar_day(day, month):
            return f"{_year_of(year)}-{month}-{int(day):02d}"
    return None


def _find_date(lines: list[PhysicalLine]) -> str | None:
    """La date de l'achat, sous l'une de ses formes imprimées.

    Les espaces sont compactés (l'OCR éclate « 202 6 ») et les numéros de
    téléphone masqués avant toute recherche. La forme numérique prime : elle
    est la plus courante et la moins ambiguë. La première occurrence *valide*
    gagne — un jour ou un mois impossible n'est pas une date, et la vraie est
    souvent plus loin sur la même ligne."""
    for line in lines:
        compact = PHONE_PATTERN.sub(" ", re.sub(r"\s+", "", line.text))
        found = _numeric_date(compact) or _literal_date(compact)
        if found is not None:
            return found
    return None


def extract_from_result(result_path) -> ExtractedReceipt:
    from pathlib import Path

    from reference.lines import deskew_words, load_words, median_angle

    words, data = load_words(Path(result_path))
    words = deskew_words(words, median_angle(data))
    return extract(cluster_lines(words))
