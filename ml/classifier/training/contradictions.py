from collections import defaultdict


def drop_contradictory_texts(rows: list[dict]) -> list[dict]:
    categories: dict[str, set[int]] = defaultdict(set)
    for entry in rows:
        categories[entry["text"]].add(entry["category_label"])
    return [entry for entry in rows if len(categories[entry["text"]]) == 1]
