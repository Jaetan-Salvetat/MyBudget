from corpus.receipts.openprices import label_table, product_slug


def test_product_slug_prefers_the_beauty_truth_over_the_food_one():
    assert product_slug(["en:snacks"], ["en:mascaras"], None) == "sante_beaute.esthetique"


def test_product_slug_reads_the_food_truth_when_the_product_is_not_a_cosmetic():
    assert product_slug(["en:snacks"], None, None) == "alimentation.supermarche"


def test_product_slug_falls_back_on_the_raw_category_tag():
    assert product_slug(None, None, "en:bananas") == "alimentation.supermarche"


def test_product_slug_keeps_the_families_a_budget_separates():
    assert product_slug(["en:cat-food"], None, None) == "divers.animaux"
    assert product_slug(None, ["en:food-supplements"], None) == "sante_beaute.pharmacie"


def test_product_slug_is_none_when_nothing_carries_a_truth():
    assert product_slug(None, None, None) is None
    assert product_slug(["en:non-food-products"], None, None) is None


def test_label_table_keeps_a_label_repeated_under_one_class():
    lines = [("3", "lentilles bio crf", "alimentation.supermarche"),
             ("3", "lentilles", "alimentation.supermarche"),
             ("4", "lentilles", "alimentation.supermarche")]
    assert label_table(lines) == {
        "lentilles bio crf": "alimentation.supermarche",
        "lentilles": "alimentation.supermarche",
    }


def test_label_table_drops_a_label_that_two_products_class_differently():
    lines = [("3", "croquettes", "divers.animaux"),
             ("4", "croquettes", "alimentation.supermarche"),
             ("5", "yaourt", "alimentation.supermarche")]
    assert label_table(lines) == {"yaourt": "alimentation.supermarche"}


def test_food_slug_reads_only_the_most_specific_category():
    """Les tags portent toute l'ascendance : lire tout classerait le chocolat en boisson."""
    from corpus.receipts.categories import food_slug

    ancestry = ["en:plant-based-foods-and-beverages", "en:beverages", "en:dark-chocolate"]
    assert food_slug(ancestry) == "alimentation.supermarche"
    assert food_slug(["en:breads", "en:wholemeal-sliced-breads"]) == "alimentation.boulangerie"
    assert food_slug(["en:hot-beverages"]) == "alimentation.epicerie"


def test_food_slug_and_the_quick_add_harvest_answer_with_one_voice():
    from corpus.receipts.categories import food_family, food_slug

    assert food_slug(["en:breads"]) == food_family("Breads")
    assert food_slug(["en:teas"]) == food_family("Teas")
