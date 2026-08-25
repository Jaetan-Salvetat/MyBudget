import json
import random

from receipts.build_eval import label_for
from receipts.labels import EXCLUDED_ITEMS, ITEM_OVERRIDES, STORE_LABELS
from receipts.lexicon import RECEIPT_LEXICON, STORE_ABBREVIATIONS
from receipts.normalize import normalize_receipt_line
from receipts.style import format_quantity, receipt_line
from taxonomy import LABELS, NUM_EXPENSE
from train import training_rows


def test_normalize_strips_receipt_noise_and_lowercases():
    assert normalize_receipt_line("*160G BLC PLT 4TR.F") == "blc plt .f"
    assert normalize_receipt_line("*4X100G YOPA 0% LIT") == "yopa lit"
    assert normalize_receipt_line("2120017210877 SAO PAULO DENIM BER 42") == "sao paulo denim ber"
    assert normalize_receipt_line("1 MENU SUPREME") == "menu supreme"
    assert normalize_receipt_line("6X1.5L EAU SOURCE") == "eau source"


def test_normalize_keeps_a_line_made_of_numbers():
    assert normalize_receipt_line("0,180 4,00") == "0,180 4,00"


def test_normalize_never_returns_empty():
    assert normalize_receipt_line("***") == "***"


def test_receipt_line_is_normalized_and_deterministic():
    first = receipt_line("Yaourt nature", random.Random(7), "Danone", "4 x 125 g")
    second = receipt_line("Yaourt nature", random.Random(7), "Danone", "4 x 125 g")
    assert first == second
    assert first == normalize_receipt_line(first)
    assert first


def test_format_quantity_reads_receipt_units():
    rng = random.Random(0)
    assert format_quantity("4 x 125 g", rng) in {"4X125G"}
    assert format_quantity("75 cl", rng) == "75CL"
    assert format_quantity(None, rng) == ""
    assert format_quantity("une bouteille", rng) == ""


def test_every_lexicon_slug_is_an_expense_class():
    for slug, entries in RECEIPT_LEXICON.items():
        assert slug in LABELS[:NUM_EXPENSE], slug
        assert len(entries) >= 10, slug
        assert len(set(entries)) == len(entries), slug


def test_store_labels_and_overrides_use_known_slugs():
    for slug in [*STORE_LABELS.values(), *ITEM_OVERRIDES.values()]:
        assert slug in LABELS[:NUM_EXPENSE], slug


def test_overrides_and_exclusions_do_not_overlap():
    assert not (set(ITEM_OVERRIDES) & EXCLUDED_ITEMS)


def test_label_for_applies_override_then_store_then_exclusion():
    assert label_for("HYPER U", "LITIERE SILICE POUR CHAT U 5L") == "divers.animaux"
    assert label_for("HYPER U", "CAROTTE") == "alimentation.supermarche"
    assert label_for("HYPER U", "ADMISSION") is None
    assert label_for("", "CAROTTE") is None
    assert label_for("ENSEIGNE INCONNUE", "CAROTTE") is None


def test_store_abbreviations_are_uppercase_receipt_headers():
    for _slug, forms in STORE_ABBREVIATIONS.values():
        for form in forms:
            assert form == form.upper(), form


def _write_jsonl(path, rows):
    path.write_text("\n".join(json.dumps(row) for row in rows) + "\n", encoding="utf-8")


def test_training_rows_merges_receipts_when_present(tmp_path):
    _write_jsonl(tmp_path / "train.jsonl", [{"text": "netflix"}])
    assert training_rows(tmp_path) == [{"text": "netflix"}]
    _write_jsonl(tmp_path / "receipts_train.jsonl", [{"text": "yaourt nat"}])
    assert training_rows(tmp_path) == [{"text": "netflix"}, {"text": "yaourt nat"}]


def test_cap_per_class_bounds_every_class():
    from receipts.generate_receipt_dataset import cap_per_class

    rows = [{"category_label": 0, "text": str(i)} for i in range(50)] + [
        {"category_label": 1, "text": "x"}
    ]
    capped = cap_per_class(rows, 10, random.Random(0))
    assert sum(1 for r in capped if r["category_label"] == 0) == 10
    assert sum(1 for r in capped if r["category_label"] == 1) == 1
