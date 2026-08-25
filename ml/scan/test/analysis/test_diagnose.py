from diagnose import StageResult, concordance, name_similarity, root_cause
from line_truth import IGNORE, ITEM, TOTAL, TVA, LineTruth


def stage(verified, items, edits=0):
    return StageResult(verified=verified, edits=edits, items=items, total=1.0)


class TestConcordance:
    def test_no_verified_stage(self):
        assert concordance({"a": stage(False, [(1.0, 0.0)])}) == ("none", 0)

    def test_agreeing_stages(self):
        stages = {
            "a": stage(True, [(1.0, 0.0), (2.0, 0.0)]),
            "b": stage(True, [(2.0, 0.0), (1.0, 0.0)]),
        }
        assert concordance(stages) == ("agree", 2)

    def test_disagreeing_stages_flag_a_collision(self):
        stages = {
            "a": stage(True, [(3.0, 0.0)]),
            "b": stage(True, [(1.0, 0.0), (2.0, 0.0)]),
        }
        assert concordance(stages) == ("disagree", 2)


class TestNameSimilarity:
    def test_identical_case_insensitive(self):
        assert name_similarity("pain", "PAIN") == 1.0

    def test_unrelated(self):
        assert name_similarity("PAIN", "VOITURE") < 0.5


def truth(role, price=1.0):
    return LineTruth(rank=0, index=0, price=price, text="", role=role)


def ocr_ok():
    return {"amounts_missing": [], "total_missing": False}


class TestRootCause:
    def test_verified(self):
        assert root_cause("local", 0, [], [], ocr_ok()) == "verified"

    def test_verified_wrong(self):
        assert root_cause("local_dp", 1, [], [], ocr_ok()) == "verified_wrong"

    def test_ocr_amount(self):
        ocr = {"amounts_missing": [2.5], "total_missing": False}
        assert root_cause("confirm", 1, [], [], ocr) == "ocr_amount_unreadable"

    def test_reference_line_not_priced(self):
        assert (
            root_cause("confirm", 1, [truth(ITEM)], [ITEM], ocr_ok())
            == "reference_line_not_priced"
        )

    def test_missed_item(self):
        truths = [truth(ITEM), truth(TOTAL)]
        assert (
            root_cause("confirm", 1, truths, [IGNORE, TOTAL], ocr_ok())
            == "classifier_missed_contributing_line"
        )

    def test_promoted_noise(self):
        truths = [truth(ITEM), truth(TVA), truth(TOTAL)]
        assert (
            root_cause("confirm", 1, truths, [ITEM, ITEM, TOTAL], ocr_ok())
            == "classifier_promoted_noise_line"
        )

    def test_reference_not_recognized(self):
        truths = [truth(ITEM), truth(TOTAL)]
        assert (
            root_cause("confirm", 1, truths, [ITEM, IGNORE], ocr_ok())
            == "reference_not_recognized"
        )
