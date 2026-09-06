from bench.exactness import ExtractedName
from bench.vlm_ollama import checksum_ok, extracted_names, iso_date


class TestExtractedNames:
    def test_reads_name_amount_and_discount(self):
        raw = {"items": [{"name": "PAIN", "amount": 1.2, "discount": 0.2}]}
        assert extracted_names(raw) == [ExtractedName("PAIN", 1.2, 0.2)]

    def test_missing_discount_defaults_to_zero(self):
        raw = {"items": [{"name": "PAIN", "amount": 1.2}]}
        assert extracted_names(raw) == [ExtractedName("PAIN", 1.2, 0.0)]

    def test_negative_discount_is_taken_as_amount(self):
        raw = {"items": [{"name": "PAIN", "amount": 1.2, "discount": -0.2}]}
        assert extracted_names(raw) == [ExtractedName("PAIN", 1.2, 0.2)]

    def test_item_without_numeric_amount_is_dropped(self):
        raw = {"items": [{"name": "PAIN", "amount": None, "discount": 0}]}
        assert extracted_names(raw) == []

    def test_missing_name_becomes_empty(self):
        raw = {"items": [{"amount": 1.2, "discount": 0}]}
        assert extracted_names(raw) == [ExtractedName("", 1.2, 0.0)]

    def test_no_items_key(self):
        assert extracted_names({"items": None}) == []


class TestChecksumOk:
    def test_net_sum_matches_total(self):
        items = [ExtractedName("A", 2.0, 0.5), ExtractedName("B", 3.0, 0.0)]
        assert checksum_ok(items, 4.5)

    def test_net_sum_off_by_one_cent(self):
        items = [ExtractedName("A", 2.0, 0.0)]
        assert not checksum_ok(items, 2.01)

    def test_total_absent(self):
        assert not checksum_ok([ExtractedName("A", 2.0, 0.0)], None)

    def test_no_item(self):
        assert not checksum_ok([], 0.0)


class TestIsoDate:
    def test_already_iso(self):
        assert iso_date("2024-01-25") == "2024-01-25"

    def test_french_slashes(self):
        assert iso_date("25/01/2024") == "2024-01-25"

    def test_french_dots(self):
        assert iso_date("25.01.2024") == "2024-01-25"

    def test_two_digit_year(self):
        assert iso_date("25/01/24") == "2024-01-25"

    def test_unparseable(self):
        assert iso_date("le 25 janvier") is None

    def test_absent(self):
        assert iso_date(None) is None
