"""Sonde capacité vs entraînement : few-shot et taille de modèle.

Compare sur les mêmes tickets : E2B base, E2B few-shot (proxy d'un
entraînement à la tâche), et 4B base (capacité supérieure, même
entraînement générique). Si le few-shot résorbe les erreurs → c'est de
l'entraînement ; si seul le 4B le fait → c'est de la capacité.
"""

from __future__ import annotations

import json
import sys
import urllib.request

from llm.structure import (
    OLLAMA_URL,
    PROMPT,
    SCHEMA,
    amounts_in_text,
    ocr_lines_text,
    parse_llm_receipt,
)
from paths import RESULTS_DIR
from truth.selection import truth_backed_receipts
from truth.transcript import extract_from_transcript

FEW_SHOT = """Voici deux exemples de la tâche.

Exemple 1 — ticket :
SUPERMARCHE DES HALLES
DESCRIPTION QTE MONTANT
YAOURT NAT X8 1.89€
CAFE MOULU 250G
2 X 3,20 6,40€
REMISE FID. -0,50€
TOTAL A PAYER (3) 7,79€
CB EMV 7,79€

JSON attendu :
{"store": "SUPERMARCHE DES HALLES", "date": null, "total": 7.79, "items": [
 {"name": "YAOURT NAT X8", "amount": 1.89, "discount": 0},
 {"name": "CAFE MOULU 250G", "amount": 6.40, "discount": 0.50}]}

Attention : pour CAFE MOULU, le montant est 6,40 (le total de la ligne),
jamais 3,20 (l'unitaire) ni un calcul de ta part. Tu recopies, tu ne
calcules jamais.

Exemple 2 — ticket :
BOULANGERIE
BAGUETTE TRADITION 1.10€
0.450kg x 2.40€/kg
POMME GALA 1.08€
TOTAL 2.18€

JSON attendu :
{"store": "BOULANGERIE", "date": null, "total": 2.18, "items": [
 {"name": "BAGUETTE TRADITION", "amount": 1.10, "discount": 0},
 {"name": "POMME GALA", "amount": 1.08, "discount": 0}]}

Maintenant la vraie tâche.

"""


def call(model: str, prompt: str, timeout: int = 300) -> dict:
    payload = {
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
        "format": SCHEMA,
        "stream": False,
        "options": {"temperature": 0, "num_ctx": 4096},
    }
    request = urllib.request.Request(
        OLLAMA_URL,
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:
        body = json.load(response)
    return json.loads(body["message"]["content"])


def run(model: str, few_shot: bool, limit: int) -> None:
    label = f"{model}{'+fewshot' if few_shot else ''}"
    cache = RESULTS_DIR / f"probe_{label.replace(':', '_').replace('+', '_')}"
    cache.mkdir(exist_ok=True)

    edits_total = items_total = invented = 0
    zero = scored = 0
    for name, result, txt in truth_backed_receipts()[:limit]:
        cache_file = cache / f"{name}.json"
        lines_text = ocr_lines_text(result)
        if cache_file.exists():
            raw = json.loads(cache_file.read_text())
        else:
            prompt = (FEW_SHOT if few_shot else "") + PROMPT.format(
                receipt=lines_text
            )
            try:
                raw = call(model, prompt)
            except Exception as error:
                print(f"  FAIL {name}: {error}")
                continue
            cache_file.write_text(json.dumps(raw, ensure_ascii=False))

        truth = extract_from_transcript(txt)
        ocr_amounts = amounts_in_text(lines_text)
        got, _total = parse_llm_receipt(raw)
        remaining = [round(i.amount, 2) for i in truth.items]
        wrong = 0
        for amount, _discount in got:
            hit = next((p for p in remaining if abs(p - amount) < 0.005), None)
            if hit is not None:
                remaining.remove(hit)
            else:
                wrong += 1
                if amount not in ocr_amounts:
                    invented += 1
        edits = len(remaining) + wrong
        edits_total += edits
        items_total += len(truth.items)
        scored += 1
        if edits == 0:
            zero += 1

    print(f"\n=== {label} ({scored} tickets)")
    print(f"  zéro correction : {zero}/{scored} ({zero/scored:.0%})")
    print(f"  moyenne : {edits_total/scored:.2f} correction/ticket")
    print(f"  articles à corriger : {edits_total}/{items_total} ({edits_total/items_total:.1%})")
    print(f"  montants absents du texte OCR : {invented}")


if __name__ == "__main__":
    limit = int(sys.argv[3]) if len(sys.argv) > 3 else 50
    run(sys.argv[1], sys.argv[2] == "fewshot", limit)
