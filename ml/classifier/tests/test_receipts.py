import json
import random

from corpus.receipts.labels import EXCLUDED_ITEMS, ITEM_OVERRIDES, STORE_LABELS
from corpus.receipts.lexicon import RECEIPT_LEXICON, STORE_ABBREVIATIONS
from corpus.receipts.style import format_quantity, receipt_line
from corpus.receipts.truth import item_label
from serving.contract import write_taxonomy_stamp
from serving.normalize import normalize_query, normalize_receipt_line
from taxonomy import LABELS, NUM_EXPENSE
from training.train import training_rows


def test_normalize_lands_in_the_same_canonical_form_as_a_typed_query():
    assert normalize_receipt_line("*160G PÂTÉ CROÛTE") == "pate croute"
    assert normalize_receipt_line("PÈRE&FILS") == normalize_query("Père & Fils")


def test_normalize_strips_receipt_noise_and_lowercases():
    assert normalize_receipt_line("*160G BLC PLT 4TR.F") == "blc plt .f"
    assert normalize_receipt_line("*4X100G YOPA 0% LIT") == "yopa lit"
    assert normalize_receipt_line("2120017210877 SAO PAULO DENIM BER 42") == "sao paulo denim ber"
    assert normalize_receipt_line("1 MENU SUPREME") == "menu supreme"
    assert normalize_receipt_line("6X1.5L EAU SOURCE") == "eau source"


def test_normalize_keeps_a_line_made_of_numbers():
    assert normalize_receipt_line("0,180 4,00") == "0 , 180 4 , 00"


def test_normalize_never_returns_empty():
    assert normalize_receipt_line("***") == "*"


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


def test_item_label_applies_exclusion_then_override_then_the_real_labels():
    labels = {"carotte": "alimentation.supermarche"}
    assert item_label("LITIERE SILICE POUR CHAT U 5L", labels) == "divers.animaux"
    assert item_label("CAROTTE", labels) == "alimentation.supermarche"
    assert item_label("ADMISSION", labels) is None


def test_item_label_never_reads_the_store():
    """Le même libellé garde sa classe quel que soit le ticket où il est lu."""
    labels = {"pain": "alimentation.boulangerie"}
    assert item_label("PAIN", labels) == "alimentation.boulangerie"
    assert item_label("PAIN", {}) is None


def test_store_abbreviations_are_uppercase_receipt_headers():
    for _slug, forms in STORE_ABBREVIATIONS.values():
        for form in forms:
            assert form == form.upper(), form


def _write_jsonl(path, rows):
    path.write_text("\n".join(json.dumps(row) for row in rows) + "\n", encoding="utf-8")
    write_taxonomy_stamp(path)


def test_training_rows_merges_receipts_when_present(tmp_path):
    _write_jsonl(tmp_path / "train.jsonl", [{"text": "netflix"}])
    assert training_rows(tmp_path) == [{"text": "netflix"}]
    _write_jsonl(tmp_path / "receipts_train.jsonl", [{"text": "yaourt nat"}])
    assert training_rows(tmp_path) == [{"text": "netflix"}, {"text": "yaourt nat"}]


def test_cap_per_class_bounds_every_class():
    from corpus.receipts.build import cap_per_class

    rows = [{"category_label": 0, "text": str(i)} for i in range(50)] + [
        {"category_label": 1, "text": "x"}
    ]
    capped = cap_per_class(rows, 10, random.Random(0))
    assert sum(1 for r in capped if r["category_label"] == 0) == 10
    assert sum(1 for r in capped if r["category_label"] == 1) == 1


def test_cap_per_class_reads_the_class_where_it_is_told_to():
    from corpus.receipts.build import cap_per_class

    lines = [(str(i), "x", "alimentation.supermarche") for i in range(50)]
    lines += [("k", "y", "divers.animaux")]
    capped = cap_per_class(lines, 10, random.Random(0), key=lambda line: line[2])
    assert sum(1 for line in capped if line[2] == "alimentation.supermarche") == 10
    assert sum(1 for line in capped if line[2] == "divers.animaux") == 1


def test_drop_contradictions_removes_a_label_two_sources_disagree_on():
    from corpus.receipts.build import drop_contradictions

    lines = [
        ("lexique", "shampooing", "transport.entretien_vehicule"),
        ("3760", "shampooing", "alimentation.supermarche"),
        ("3761", "yaourt nature", "alimentation.supermarche"),
    ]
    assert drop_contradictions(lines) == [("3761", "yaourt nature", "alimentation.supermarche")]


def test_drop_contradictions_keeps_a_label_repeated_under_one_class():
    from corpus.receipts.build import drop_contradictions

    lines = [("a", "baguette", "alimentation.boulangerie"),
             ("b", "baguette", "alimentation.boulangerie")]
    assert drop_contradictions(lines) == lines
