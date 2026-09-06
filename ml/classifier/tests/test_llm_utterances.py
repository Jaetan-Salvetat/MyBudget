from corpus.llm.openrouter import parse_json_payload
from corpus.llm.utterances import (
    Candidate,
    accept,
    align_verdicts,
    generation_prompt,
    verification_prompt,
)
from taxonomy import ONE_TIME, RECURRING


def test_parse_json_payload_strips_markdown_fences():
    text = '```json\n[{"text": "plein", "recurrence": "ponctuel"}]\n```'
    assert parse_json_payload(text) == [{"text": "plein", "recurrence": "ponctuel"}]


def test_parse_json_payload_reads_bare_json():
    assert parse_json_payload('{"a": 1}') == {"a": 1}


def test_generation_prompt_carries_the_class_guide_and_its_neighbours():
    prompt = generation_prompt("restauration.cafe", 50)
    assert "restauration.cafe" in prompt
    assert "Starbucks" in prompt
    assert "restauration.bar" in prompt
    assert "50" in prompt


def test_verification_prompt_lists_candidates_by_index_without_their_class():
    prompt = verification_prompt(["kawa du matin", "pinte au pub"])
    assert "0. kawa du matin" in prompt
    assert "1. pinte au pub" in prompt
    assert "restauration.cafe" in prompt


def test_accept_keeps_only_verified_distinct_unpriced_unmeasured_candidates():
    candidates = [
        Candidate("kawa du matin", ONE_TIME),
        Candidate("Kawa du matin", ONE_TIME),
        Candidate("café à 3 euros", ONE_TIME),
        Candidate("abonnement café", RECURRING),
        Candidate("pinte au pub", ONE_TIME),
        Candidate("expresso", ONE_TIME),
    ]
    verdicts = [
        "restauration.cafe",
        "restauration.cafe",
        "restauration.cafe",
        "restauration.cafe",
        "restauration.bar",
        "restauration.cafe",
    ]
    kept = accept("restauration.cafe", candidates, verdicts, measured={"expresso"})
    assert [c.text for c in kept] == ["kawa du matin", "abonnement café"]


def test_align_verdicts_maps_by_index_and_defaults_to_ambiguous():
    payload = [{"i": 1, "slug": "restauration.bar"}, {"i": 5, "slug": "x"}, "junk"]
    assert align_verdicts(payload, 3) == ["ambigu", "restauration.bar", "ambigu"]


def test_prune_shared_removes_a_text_owned_by_two_classes(tmp_path):
    from corpus.llm.utterances import prune_shared, write

    write("restauration.cafe", [Candidate("kawa", ONE_TIME), Candidate("pension", ONE_TIME)], tmp_path)
    write("salaire.retraite", [Candidate("Pension", RECURRING), Candidate("retraite", RECURRING)], tmp_path)
    assert prune_shared(tmp_path) == ["pension"]
    from corpus.quick_add.utterances import read_utterances

    assert [u.text for u in read_utterances(tmp_path)] == ["kawa", "retraite"]
