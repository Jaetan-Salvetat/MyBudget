"""Génère le contenu texte d'un ticket de caisse français réaliste.

Le style des libellés reproduit ce que les caisses impriment vraiment :
majuscules, abréviations, troncatures. Le ground truth porte les articles,
leurs remises et le total, c'est la référence contre laquelle on mesure
tout le pipeline.
"""

from __future__ import annotations

import random
from dataclasses import dataclass, field

STORES = [
    ("CARREFOUR MARKET", "12 RUE DE LA GARE", "69003 LYON"),
    ("INTERMARCHE", "ZAC DES PEUPLIERS", "38300 BOURGOIN"),
    ("E.LECLERC", "AV DU GENERAL DE GAULLE", "35000 RENNES"),
    ("LIDL", "45 ROUTE DE PARIS", "14600 HONFLEUR"),
    ("MONOPRIX", "8 PLACE BELLECOUR", "69002 LYON"),
    ("AUCHAN SUPERMARCHE", "CC LES TERRASSES", "31000 TOULOUSE"),
    ("BOULANGERIE DUPAIN", "3 RUE VICTOR HUGO", "75011 PARIS"),
    ("PHARMACIE CENTRALE", "1 PLACE DU MARCHE", "44000 NANTES"),
]

PRODUCTS = [
    ("LAIT 1/2 ECREME 1L", 0.89, 1.35),
    ("BISC.CHOC LU", 1.80, 2.60),
    ("YAOURT NAT X8", 1.50, 2.40),
    ("POM.TERRE 2.5KG", 2.90, 4.10),
    ("CAFE MOULU 250G", 2.80, 4.50),
    ("JAMBON SUP 4TR", 2.60, 3.90),
    ("PATES PENNE 500G", 0.80, 1.60),
    ("RIZ LONG 1KG", 1.60, 2.80),
    ("EAU SOURCE 6X1.5L", 1.50, 2.70),
    ("JUS ORANGE 1L", 1.30, 2.50),
    ("BEURRE DOUX 250G", 1.90, 3.20),
    ("OEUFS PLEIN AIR X12", 2.80, 4.20),
    ("FROMAGE RAPE 200G", 1.70, 2.90),
    ("POULET FERMIER", 6.50, 11.90),
    ("STEACK HACHE X2", 3.90, 6.50),
    ("SAUMON FUME 4TR", 4.50, 7.90),
    ("BAGUETTE TRADITION", 1.10, 1.40),
    ("CROISSANT X4", 2.40, 3.60),
    ("PIZZA SURGELEE", 2.90, 5.50),
    ("GLACE VANILLE 500ML", 2.50, 4.90),
    ("LESSIVE LIQ 1.5L", 5.90, 9.90),
    ("PQ 12 ROULEAUX", 4.50, 7.50),
    ("DENTIFRICE MENTHE", 1.80, 3.20),
    ("SHAMPOING 250ML", 2.20, 4.50),
    ("BANANE VRAC", 1.20, 2.60),
    ("POMME GALA 1KG", 1.90, 3.20),
    ("TOMATE GRAPPE", 2.30, 3.80),
    ("SALADE BATAVIA", 0.90, 1.50),
    ("VIN ROUGE BORDEAUX", 4.90, 12.50),
    ("BIERE BLONDE 6X25CL", 4.20, 7.80),
    ("CHIPS NATURE 150G", 1.30, 2.40),
    ("CHOCOLAT NOIR 200G", 1.90, 3.50),
]

DISCOUNT_LABELS = ["REMISE IMMEDIATE", "AVANTAGE CARTE", "PROMO -30%", "REMISE FID."]


@dataclass(frozen=True)
class ReceiptItem:
    label: str
    quantity: int
    unit_price: float
    discount: float

    @property
    def amount(self) -> float:
        return round(self.quantity * self.unit_price, 2)


@dataclass(frozen=True)
class Receipt:
    store: str
    address: str
    city: str
    date: str
    time: str
    items: list[ReceiptItem]
    payment: str

    @property
    def total(self) -> float:
        return round(sum(i.amount - i.discount for i in self.items), 2)

    def ground_truth(self) -> dict:
        return {
            "store": self.store,
            "date": self.date,
            "total": self.total,
            "items": [
                {
                    "name": item.label,
                    "amount": item.amount,
                    "discount": item.discount,
                }
                for item in self.items
            ],
        }


@dataclass
class ReceiptGenerator:
    rng: random.Random = field(default_factory=lambda: random.Random(0))

    def generate(self) -> Receipt:
        store, address, city = self.rng.choice(STORES)
        item_count = self.rng.randint(3, 14)
        products = self.rng.sample(PRODUCTS, min(item_count, len(PRODUCTS)))
        items = [self._make_item(label, low, high) for label, low, high in products]
        return Receipt(
            store=store,
            address=address,
            city=city,
            date=self._date(),
            time=self._time(),
            items=items,
            payment=self.rng.choice(["CB EMV", "ESPECES", "CB SANS CONTACT"]),
        )

    def _make_item(self, label: str, low: float, high: float) -> ReceiptItem:
        unit_price = round(self.rng.uniform(low, high), 2)
        quantity = self.rng.choice([1, 1, 1, 1, 2, 3])
        amount = round(quantity * unit_price, 2)
        discount = 0.0
        if self.rng.random() < 0.18:
            discount = round(amount * self.rng.uniform(0.1, 0.4), 2)
        return ReceiptItem(
            label=label,
            quantity=quantity,
            unit_price=unit_price,
            discount=discount,
        )

    def _date(self) -> str:
        day = self.rng.randint(1, 28)
        month = self.rng.randint(1, 12)
        year = self.rng.randint(2024, 2026)
        return f"{day:02d}/{month:02d}/{year}"

    def _time(self) -> str:
        return f"{self.rng.randint(8, 20):02d}:{self.rng.randint(0, 59):02d}"


@dataclass(frozen=True)
class LayoutStyle:
    """Conventions d'impression d'une caisse : elles varient d'une enseigne à
    l'autre et la structuration doit y résister sans les connaître."""

    width: int
    decimal_separator: str
    currency_suffix: str
    quantity_inline: bool
    total_label: str
    with_tva_table: bool

    @staticmethod
    def sample(rng: random.Random) -> LayoutStyle:
        return LayoutStyle(
            width=rng.choice([32, 38, 42, 48]),
            decimal_separator=rng.choice([",", ",", ",", "."]),
            currency_suffix=rng.choice(["", "", " €", " EUR"]),
            quantity_inline=rng.random() < 0.4,
            total_label=rng.choice(
                ["TOTAL A PAYER", "TOTAL", "MONTANT DU", "TOTAL TTC"]
            ),
            with_tva_table=rng.random() < 0.4,
        )


def render_lines(
    receipt: Receipt, rng: random.Random, style: LayoutStyle | None = None
) -> list[str]:
    """Met en page le ticket en colonnes de caractères, prix alignés à droite."""
    if style is None:
        style = LayoutStyle.sample(rng)
    width = style.width
    lines: list[str] = []
    lines.append(receipt.store.center(width))
    lines.append(receipt.address.center(width))
    lines.append(receipt.city.center(width))
    lines.append("")
    lines.append(f"LE {receipt.date} A {receipt.time}".center(width))
    lines.append("-" * width)
    for item in receipt.items:
        lines.extend(_item_lines(item, rng, style))
    lines.append("-" * width)
    article_count = sum(item.quantity for item in receipt.items)
    lines.append(
        _priced_line(f"{style.total_label} ({article_count})", receipt.total, style)
    )
    lines.append(_priced_line(receipt.payment, receipt.total, style))
    lines.append("")
    tva = round(receipt.total * 0.055 / 1.055, 2)
    if style.with_tva_table:
        lines.append("TVA    BASE HT      TVA     TTC".center(width))
        base = round(receipt.total - tva, 2)
        row = (
            f"5,5%   {_amount(base, style)}   {_amount(tva, style)}"
            f"   {_amount(receipt.total, style)}"
        )
        lines.append(row.center(width))
    else:
        lines.append(_priced_line("DONT TVA 5.5%", tva, style))
    lines.append("")
    lines.append("MERCI DE VOTRE VISITE".center(width))
    lines.append("A BIENTOT".center(width))
    return lines


def _item_lines(
    item: ReceiptItem, rng: random.Random, style: LayoutStyle
) -> list[str]:
    lines: list[str] = []
    if item.quantity > 1 and style.quantity_inline:
        label = f"{item.label} X{item.quantity}"
        lines.append(_priced_line(label, item.amount, style))
    elif item.quantity > 1:
        lines.append(item.label[: style.width])
        detail = f"  {item.quantity} X {_amount(item.unit_price, style)}"
        lines.append(_priced_line(detail, item.amount, style))
    else:
        lines.append(_priced_line(item.label, item.amount, style))
    if item.discount > 0:
        label = rng.choice(DISCOUNT_LABELS)
        lines.append(_priced_line(f"  {label}", -item.discount, style))
    return lines


def _priced_line(label: str, amount: float, style: LayoutStyle) -> str:
    price = _amount(amount, style) + style.currency_suffix
    space = style.width - len(price)
    return f"{label[: space - 1]:<{space}}{price}"


def _amount(amount: float, style: LayoutStyle) -> str:
    text = f"{abs(amount):.2f}".replace(".", style.decimal_separator)
    return f"-{text}" if amount < 0 else text
