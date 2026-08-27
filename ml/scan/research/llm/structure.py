"""Le contrat JSON d'une extraction par VLM, et sa lecture.

Le schéma décrit ce qu'on demande au modèle ; `parse_llm_receipt` en tire les
seules valeurs que la métrique compare — montants et total, au centime. Il
sert à annoter le golden (`truth/annotate.py`) et à mesurer le plafond VLM
cloud (`bench/gemini.py`), qui partagent ainsi la même définition.
"""

from __future__ import annotations

SCHEMA = {
    "type": "object",
    "properties": {
        "store": {"type": ["string", "null"]},
        "date": {"type": ["string", "null"]},
        "total": {"type": ["number", "null"]},
        "items": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "name": {"type": "string"},
                    "amount": {"type": "number"},
                    "discount": {"type": "number"},
                },
                "required": ["name", "amount", "discount"],
            },
        },
    },
    "required": ["store", "date", "total", "items"],
}


def parse_llm_receipt(raw: dict) -> tuple[list[tuple[float, float]], float | None]:
    items: list[tuple[float, float]] = []
    for item in raw.get("items") or []:
        amount = item.get("amount")
        if not isinstance(amount, (int, float)):
            continue
        discount = item.get("discount")
        if not isinstance(discount, (int, float)):
            discount = 0.0
        items.append((round(float(amount), 2), round(abs(float(discount)), 2)))
    total = raw.get("total")
    total_value = round(float(total), 2) if isinstance(total, (int, float)) else None
    return items, total_value
