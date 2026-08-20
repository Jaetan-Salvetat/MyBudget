from pathlib import Path

import torch
from transformers import AutoTokenizer

from train import BudgetClassifier, BudgetClassifierConfig

MODEL_PATH = Path(__file__).parent / "output" / "best"

LABELS: list[str] = [
    "alimentation.supermarché",
    "alimentation.marché",
    "alimentation.épicerie",
    "alimentation.boulangerie",
    "restauration.restaurant",
    "restauration.fast-food/friterie",
    "restauration.bar/apéro",
    "restauration.café",
    "restauration.livraison",
    "transport.essence",
    "transport.transport en commun",
    "transport.taxi/VTC",
    "transport.parking",
    "transport.péage",
    "transport.entretien véhicule",
    "logement.loyer",
    "logement.charges",
    "logement.énergie",
    "logement.eau",
    "logement.télécom/internet",
    "logement.assurance",
    "sante_beaute.médecin",
    "sante_beaute.pharmacie",
    "sante_beaute.mutuelle",
    "sante_beaute.coiffeur",
    "sante_beaute.esthétique",
    "loisirs.cinéma/sorties",
    "loisirs.jeux vidéo",
    "loisirs.sport",
    "loisirs.manga/livres",
    "loisirs.streaming",
    "loisirs.musique",
    "shopping.vêtements",
    "shopping.électronique",
    "shopping.mobilier/déco",
    "finance_taxes.retrait DAB",
    "finance_taxes.frais bancaires",
    "finance_taxes.impôts/taxes",
    "finance_taxes.amendes",
    "education.scolarité",
    "education.fournitures",
    "education.formation",
    "divers.cadeau offert",
    "divers.vétérinaire/animaux",
    "divers.tabac/jeux d'argent",
    "divers.autre",
    "salaire.salaire net",
    "salaire.prime",
    "salaire.revenu freelance",
    "transfert.virement reçu",
    "transfert.remboursement santé",
    "transfert.remboursement ami",
    "exceptionnel.vente occasion",
    "exceptionnel.don reçu",
    "exceptionnel.intérêts",
]

TYPE_LABELS = ["expense", "income"]
REC_LABELS = ["ponctuel", "fixe"]


# ── TEST CASES ──────────────────────────────────────────────────

EASY_TESTS: list[dict] = [
    {"text": "carrefour", "type": 0, "category": 0, "recurrence": 0},
    {"text": "macdo", "type": 0, "category": 5, "recurrence": 0},
    {"text": "loyer", "type": 0, "category": 15, "recurrence": 1},
    {"text": "netflix", "type": 0, "category": 30, "recurrence": 1},
    {"text": "salaire", "type": 1, "category": 46, "recurrence": 1},
    {"text": "uber", "type": 0, "category": 11, "recurrence": 0},
    {"text": "pharmacie", "type": 0, "category": 22, "recurrence": 0},
    {"text": "boulangerie", "type": 0, "category": 3, "recurrence": 0},
    {"text": "spotify", "type": 0, "category": 31, "recurrence": 1},
    {"text": "EDF", "type": 0, "category": 17, "recurrence": 1},
    {"text": "médecin", "type": 0, "category": 21, "recurrence": 0},
    {"text": "coiffeur", "type": 0, "category": 24, "recurrence": 0},
    {"text": "parking", "type": 0, "category": 12, "recurrence": 0},
    {"text": "essence", "type": 0, "category": 9, "recurrence": 0},
    {"text": "mutuelle", "type": 0, "category": 23, "recurrence": 1},
    {"text": "restaurant", "type": 0, "category": 4, "recurrence": 0},
    {"text": "assurance", "type": 0, "category": 20, "recurrence": 1},
    {"text": "internet", "type": 0, "category": 19, "recurrence": 1},
    {"text": "IKEA", "type": 0, "category": 34, "recurrence": 0},
    {"text": "prime", "type": 1, "category": 47, "recurrence": 0},
    {"text": "retrait", "type": 0, "category": 35, "recurrence": 0},
    {"text": "impôts", "type": 0, "category": 37, "recurrence": 1},
    {"text": "cigarettes", "type": 0, "category": 44, "recurrence": 0},
    {"text": "manga", "type": 0, "category": 29, "recurrence": 0},
    {"text": "amende", "type": 0, "category": 38, "recurrence": 0},
]

MEDIUM_TESTS: list[dict] = [
    {"text": "courses leclerc", "type": 0, "category": 0, "recurrence": 0},
    {"text": "dîner anniversaire", "type": 0, "category": 4, "recurrence": 0},
    {"text": "bières avec les potes", "type": 0, "category": 6, "recurrence": 0},
    {"text": "abonnement salle", "type": 0, "category": 28, "recurrence": 1},
    {"text": "commande deliveroo", "type": 0, "category": 8, "recurrence": 0},
    {"text": "facture EDF", "type": 0, "category": 17, "recurrence": 1},
    {"text": "pass navigo", "type": 0, "category": 10, "recurrence": 1},
    {"text": "plein d'essence", "type": 0, "category": 9, "recurrence": 0},
    {"text": "contrôle technique", "type": 0, "category": 14, "recurrence": 1},
    {"text": "frais de scolarité", "type": 0, "category": 39, "recurrence": 1},
    {"text": "cadeau anniversaire", "type": 0, "category": 42, "recurrence": 0},
    {"text": "vente vinted", "type": 1, "category": 52, "recurrence": 0},
    {"text": "remboursement sécu", "type": 1, "category": 50, "recurrence": 0},
    {"text": "client mensuel", "type": 1, "category": 48, "recurrence": 1},
    {"text": "virement salaire", "type": 1, "category": 46, "recurrence": 1},
    {"text": "PS Plus", "type": 0, "category": 27, "recurrence": 1},
    {"text": "charges copro", "type": 0, "category": 16, "recurrence": 1},
    {"text": "abonnement deezer", "type": 0, "category": 31, "recurrence": 1},
    {"text": "réparation voiture", "type": 0, "category": 14, "recurrence": 0},
    {"text": "vétérinaire", "type": 0, "category": 43, "recurrence": 0},
    {"text": "escape game", "type": 0, "category": 26, "recurrence": 0},
    {"text": "remboursement pote", "type": 1, "category": 51, "recurrence": 0},
    {"text": "carte cadeau", "type": 0, "category": 42, "recurrence": 0},
    {"text": "cotisation carte", "type": 0, "category": 36, "recurrence": 1},
    {"text": "intérêts livret A", "type": 1, "category": 54, "recurrence": 1},
]

HARD_TESTS: list[dict] = [
    # Unseen brands / formulations
    {"text": "Aldi Süd", "type": 0, "category": 0, "recurrence": 0},
    {"text": "Rewe Markt", "type": 0, "category": 0, "recurrence": 0},
    {"text": "gyoza bar", "type": 0, "category": 4, "recurrence": 0},
    {"text": "naan curry house", "type": 0, "category": 4, "recurrence": 0},
    {"text": "e-liquide", "type": 0, "category": 44, "recurrence": 0},
    # Informal / slang
    {"text": "clopes buraliste", "type": 0, "category": 44, "recurrence": 0},
    {"text": "bouquin SF", "type": 0, "category": 29, "recurrence": 0},
    {"text": "fringues soldes", "type": 0, "category": 32, "recurrence": 0},
    {"text": "la salle", "type": 0, "category": 28, "recurrence": 1},
    {"text": "abo netflix", "type": 0, "category": 30, "recurrence": 1},
    # Multilingual edge cases
    {"text": "Zahnarzt", "type": 0, "category": 21, "recurrence": 0},
    {"text": "supermercado compras", "type": 0, "category": 0, "recurrence": 0},
    {"text": "Lebensmittel", "type": 0, "category": 0, "recurrence": 0},
    {"text": "cuenta de luz", "type": 0, "category": 17, "recurrence": 1},
    # Complex / ambiguous
    {"text": "ravitaillement semaine", "type": 0, "category": 0, "recurrence": 0},
    {"text": "pot de départ collègue", "type": 0, "category": 6, "recurrence": 0},
    {"text": "pressing chemise", "type": 0, "category": 45, "recurrence": 0},
    {"text": "don grand-mère noël", "type": 1, "category": 53, "recurrence": 0},
    {"text": "enveloppe anniversaire", "type": 1, "category": 53, "recurrence": 0},
    {"text": "brocante dimanche", "type": 1, "category": 52, "recurrence": 0},
    # Recurrence edge cases
    {"text": "forfait free", "type": 0, "category": 19, "recurrence": 1},
    {"text": "ticket de bus", "type": 0, "category": 10, "recurrence": 0},
    {"text": "basic fit", "type": 0, "category": 28, "recurrence": 1},
    {"text": "formation en ligne", "type": 0, "category": 41, "recurrence": 0},
    {"text": "mission freelance client", "type": 1, "category": 48, "recurrence": 0},
]


def predict(model: BudgetClassifier, tokenizer, text: str) -> dict:
    tokens = tokenizer(text, return_tensors="pt", truncation=True, padding="max_length", max_length=64)
    with torch.no_grad():
        outputs = model(input_ids=tokens["input_ids"], attention_mask=tokens["attention_mask"])

    type_pred = outputs.type_logits.argmax(dim=-1).item()
    cat_pred = outputs.category_logits.argmax(dim=-1).item()
    rec_pred = outputs.recurrence_logits.argmax(dim=-1).item()

    type_conf = torch.softmax(outputs.type_logits, dim=-1).max().item()
    cat_conf = torch.softmax(outputs.category_logits, dim=-1).max().item()
    rec_conf = torch.softmax(outputs.recurrence_logits, dim=-1).max().item()

    return {
        "type": type_pred,
        "category": cat_pred,
        "recurrence": rec_pred,
        "type_conf": type_conf,
        "cat_conf": cat_conf,
        "rec_conf": rec_conf,
    }


def run_test_suite(model: BudgetClassifier, tokenizer, cases: list[dict], level: str) -> dict:
    type_correct = 0
    cat_correct = 0
    rec_correct = 0
    all_correct = 0
    total = len(cases)
    failures: list[str] = []

    for case in cases:
        result = predict(model, tokenizer, case["text"])

        type_ok = result["type"] == case["type"]
        cat_ok = result["category"] == case["category"]
        rec_ok = result["recurrence"] == case["recurrence"]

        if type_ok:
            type_correct += 1
        if cat_ok:
            cat_correct += 1
        if rec_ok:
            rec_correct += 1
        if type_ok and cat_ok and rec_ok:
            all_correct += 1

        if not (type_ok and cat_ok and rec_ok):
            parts: list[str] = []
            if not type_ok:
                parts.append(f"type: {TYPE_LABELS[result['type']]}({result['type_conf']:.0%}) != {TYPE_LABELS[case['type']]}")
            if not cat_ok:
                parts.append(f"cat: {LABELS[result['category']]}({result['cat_conf']:.0%}) != {LABELS[case['category']]}")
            if not rec_ok:
                parts.append(f"rec: {REC_LABELS[result['recurrence']]}({result['rec_conf']:.0%}) != {REC_LABELS[case['recurrence']]}")
            failures.append(f"  '{case['text']}' → {', '.join(parts)}")

    print(f"\n{'='*60}")
    print(f"  [{level.upper()}] {total} tests")
    print(f"  Type:       {type_correct}/{total} ({type_correct/total:.0%})")
    print(f"  Category:   {cat_correct}/{total} ({cat_correct/total:.0%})")
    print(f"  Recurrence: {rec_correct}/{total} ({rec_correct/total:.0%})")
    print(f"  All 3 OK:   {all_correct}/{total} ({all_correct/total:.0%})")

    if failures:
        print(f"\n  Failures:")
        for f in failures:
            print(f)

    return {
        "type_acc": type_correct / total,
        "cat_acc": cat_correct / total,
        "rec_acc": rec_correct / total,
    }


def main() -> None:
    config = BudgetClassifierConfig.from_pretrained(str(MODEL_PATH))
    model = BudgetClassifier.from_pretrained(str(MODEL_PATH), config=config)
    model.eval()

    tokenizer = AutoTokenizer.from_pretrained(str(MODEL_PATH))

    easy = run_test_suite(model, tokenizer, EASY_TESTS, "easy")
    medium = run_test_suite(model, tokenizer, MEDIUM_TESTS, "medium")
    hard = run_test_suite(model, tokenizer, HARD_TESTS, "hard")

    print(f"\n{'='*60}")
    print("  SUMMARY")
    for level, results in [("Easy", easy), ("Medium", medium), ("Hard", hard)]:
        print(f"  {level:8s} — type:{results['type_acc']:.0%}  cat:{results['cat_acc']:.0%}  rec:{results['rec_acc']:.0%}")


if __name__ == "__main__":
    main()
