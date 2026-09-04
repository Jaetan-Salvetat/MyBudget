from training.contradictions import drop_contradictory_texts


def row(text: str, category: int) -> dict:
    return {"text": text, "type_label": 0, "category_label": category, "recurrence_label": 0}


def test_a_text_labelled_two_ways_across_corpora_is_dropped_everywhere():
    rows = [row("aquarium", 1), row("aquarium", 2), row("kawa", 3), row("kawa", 3)]
    assert drop_contradictory_texts(rows) == [row("kawa", 3), row("kawa", 3)]


def test_a_consistent_corpus_is_returned_untouched():
    rows = [row("a", 1), row("b", 2)]
    assert drop_contradictory_texts(rows) == rows
