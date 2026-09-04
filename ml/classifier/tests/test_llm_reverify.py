import json

from corpus.llm import lines as llm_lines
from corpus.llm import utterances as llm_utterances
from corpus.llm.utterances import Candidate
from corpus.quick_add.utterances import read_utterances
from corpus.receipts.lines import read_lines


def _verdicts(truth: dict[str, str]):
    def verify(texts: list[str], _model: str) -> list[str]:
        return [truth.get(text, llm_utterances.AMBIGUOUS) for text in texts]

    return verify


def test_reverify_keeps_only_the_utterances_the_reader_still_agrees_with(tmp_path, monkeypatch):
    llm_utterances.write("restauration.bar", [Candidate("pinte au pub", 0), Candidate("café au comptoir", 0)], tmp_path)
    llm_utterances.write("restauration.cafe", [Candidate("un expresso", 0)], tmp_path)
    monkeypatch.setattr(llm_utterances, "verify", _verdicts({
        "pinte au pub": "restauration.bar",
        "café au comptoir": "restauration.cafe",
        "un expresso": "restauration.cafe",
    }))
    monkeypatch.setattr(llm_utterances, "measured_inputs", lambda: set())

    llm_utterances.reverify_group(["restauration.bar", "restauration.cafe"], "fake", tmp_path)

    kept = {(u.slug, u.text) for u in read_utterances(tmp_path)}
    assert kept == {("restauration.bar", "pinte au pub"), ("restauration.cafe", "un expresso")}


def test_reverify_drops_a_line_that_now_reads_as_another_class(tmp_path, monkeypatch):
    llm_lines.write("sante_beaute.pharmacie", ["DOLIPRANE 1G", "LENTILLES X30"], tmp_path)
    monkeypatch.setattr(llm_lines, "verify", _verdicts({
        "DOLIPRANE 1G": "sante_beaute.pharmacie",
        "LENTILLES X30": "sante_beaute.optique",
    }))
    monkeypatch.setattr(llm_lines, "measured_lines", lambda: set())

    llm_lines.reverify_group(["sante_beaute.pharmacie"], "fake", tmp_path)

    assert read_lines(tmp_path) == {"sante_beaute.pharmacie": ["DOLIPRANE 1G"]}
    assert json.loads((tmp_path / "sante_beaute.pharmacie.json").read_text())["slug"] == "sante_beaute.pharmacie"
