from corpus.llm.lines import accept, generation_prompt, verification_prompt


def test_generation_prompt_names_the_class_and_forbids_prices():
    prompt = generation_prompt("restauration.bar", 40)
    assert "restauration.bar" in prompt
    assert "restauration.cafe" in prompt
    assert "prix" in prompt.lower()
    assert "40" in prompt


def test_verification_prompt_only_offers_expense_classes():
    prompt = verification_prompt(["PINTE BLONDE 50CL"])
    assert "0. PINTE BLONDE 50CL" in prompt
    assert "restauration.bar" in prompt
    assert "salaire.salaire_net" not in prompt


def test_accept_keeps_verified_distinct_unmeasured_lines_in_receipt_form():
    lines = ["Pinte Blonde 50cl", "PINTE BLONDE 50CL", "MOJITO", "CAFE ALLONGE", ""]
    verdicts = ["restauration.bar", "restauration.bar", "restauration.bar", "restauration.cafe", "restauration.bar"]
    assert accept("restauration.bar", lines, verdicts, measured={"mojito"}) == ["PINTE BLONDE 50CL"]


def test_prune_shared_removes_a_line_owned_by_two_classes(tmp_path):
    from corpus.llm.lines import prune_shared, write
    from corpus.receipts.lines import read_lines

    write("restauration.bar", ["MOJITO", "PINTE BLONDE"], tmp_path)
    write("restauration.cafe", ["MOJITO", "EXPRESSO"], tmp_path)
    assert prune_shared(tmp_path) == ["mojito"]
    assert read_lines(tmp_path) == {"restauration.bar": ["PINTE BLONDE"], "restauration.cafe": ["EXPRESSO"]}
