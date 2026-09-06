from corpus.receipts.openprices import label_table, product_slug


def test_product_slug_prefers_the_beauty_truth_over_the_food_one():
    assert product_slug(["en:snacks"], ["en:mascaras"], None) == "sante_beaute.cosmetiques"


def test_product_slug_reads_the_food_truth_when_the_product_is_not_a_cosmetic():
    assert product_slug(["en:snacks"], None, None) == "alimentation.courses"


def test_product_slug_falls_back_on_the_raw_category_tag():
    assert product_slug(None, None, "en:bananas") == "alimentation.courses"


def test_product_slug_keeps_the_families_a_budget_separates():
    assert product_slug(["en:cat-food"], None, None) == "divers.animaux"
    assert product_slug(None, ["en:food-supplements"], None) == "sante_beaute.pharmacie"


def test_product_slug_is_none_when_nothing_carries_a_truth():
    assert product_slug(None, None, None) is None
    assert product_slug(["en:non-food-products"], None, None) is None


def test_label_table_keeps_a_label_repeated_under_one_class():
    lines = [("3", "lentilles bio crf", "alimentation.courses"),
             ("3", "lentilles", "alimentation.courses"),
             ("4", "lentilles", "alimentation.courses")]
    assert label_table(lines) == {
        "lentilles bio crf": "alimentation.courses",
        "lentilles": "alimentation.courses",
    }


def test_label_table_drops_a_label_that_two_products_class_differently():
    lines = [("3", "croquettes", "divers.animaux"),
             ("4", "croquettes", "alimentation.courses"),
             ("5", "yaourt", "alimentation.courses")]
    assert label_table(lines) == {"yaourt": "alimentation.courses"}


def test_food_slug_reads_only_the_most_specific_category():
    """Les tags portent toute l'ascendance : lire tout classerait le chocolat en boisson."""
    from corpus.receipts.categories import food_slug

    ancestry = ["en:plant-based-foods-and-beverages", "en:beverages", "en:dark-chocolate"]
    assert food_slug(ancestry) == "alimentation.courses"
    assert food_slug(["en:breads", "en:wholemeal-sliced-breads"]) == "alimentation.pain_patisserie"
    assert food_slug(["en:hot-beverages"]) == "alimentation.courses"


def test_food_slug_and_the_quick_add_harvest_answer_with_one_voice():
    from corpus.receipts.categories import food_family, food_slug

    assert food_slug(["en:breads"]) == food_family("Breads")
    assert food_slug(["en:teas"]) == food_family("Teas")


def test_product_slug_prefers_the_specialised_bases_over_the_food_one():
    """Une croquette et un liquide vaisselle sont d'abord dans leur base."""
    assert product_slug(["en:snacks"], None, None, petfood_tags=["en:cat-food"]) == "divers.animaux"
    assert product_slug(
        ["en:snacks"], None, None, products_tags=["en:home-garden", "en:dish-detergent-soap"]
    ) == "alimentation.courses"
    assert product_slug(
        ["en:snacks"], None, None, products_tags=["en:electronics", "en:smartphones"]
    ) == "shopping.electronique"


def test_products_slug_reads_the_finest_category_the_table_knows():
    """Les feuilles qui ne décrivent pas un commerce sont enjambées."""
    from corpus.receipts.categories import products_slug

    assert products_slug(
        ["en:home-garden", "en:household-supplies", "en:toilet-papers", "en:12-rolls", "en:3-ply"]
    ) == "alimentation.courses"
    assert products_slug(
        ["en:home-garden", "en:decor", "en:seasonal-holiday-decorations"]
    ) == "shopping.mobilier_deco"
    assert products_slug(["en:media", "en:printed-media", "en:books"]) == "loisirs.livre_presse"


def test_products_slug_hands_food_and_beauty_back_to_the_base_that_answers_them():
    """Deux tables pour la même question feraient deux classes pour un produit."""
    from corpus.receipts.categories import beauty_slug, food_slug, products_slug

    assert products_slug(["en:health-beauty", "en:personal-care", "en:oral-care"]) == beauty_slug(
        ["en:health-beauty", "en:personal-care", "en:oral-care"]
    )
    assert products_slug(["en:health-beauty", "en:cosmetics", "en:mascaras"]) == "sante_beaute.cosmetiques"
    assert products_slug(["en:beverages"]) == food_slug(["en:beverages"])


def test_products_slug_drops_what_no_category_describes():
    """Une ligne de moins vaut mieux qu'une ligne rangée au supermarché par défaut."""
    from corpus.receipts.categories import products_slug

    assert products_slug([]) is None
    assert products_slug(["en:open-products-facts", "en:non-food-products"]) is None
    assert products_slug(["en:electronics", "en:incorrect-product-type"]) is None


def test_petfood_slug_reads_the_base_and_not_its_categories():
    from corpus.receipts.categories import petfood_slug

    assert petfood_slug(["en:cat-food"]) == "divers.animaux"
    assert petfood_slug(["en:biscuits-and-cakes"]) == "divers.animaux"
    assert petfood_slug(["en:incorrect-product-type"]) is None


def test_every_product_tag_maps_to_one_expense_class():
    from corpus.receipts.categories import PRODUCT_SLUGS, PRODUCT_TAGS
    from taxonomy import LABELS, NUM_EXPENSE

    assert len(PRODUCT_SLUGS) == sum(len(tags) for tags in PRODUCT_TAGS.values())
    for slug in PRODUCT_TAGS:
        assert slug in LABELS[:NUM_EXPENSE], slug
    for tag in PRODUCT_SLUGS:
        assert tag.startswith(("en:", "fr:")), tag


def test_the_delegating_roots_never_carry_their_own_class():
    """Un tag ne peut pas être à la fois traduit et rendu à une autre base."""
    from corpus.receipts.categories import BEAUTY_ROOTS, FOOD_ROOTS, PRODUCT_SLUGS

    assert not (BEAUTY_ROOTS & FOOD_ROOTS)
    assert not (BEAUTY_ROOTS & PRODUCT_SLUGS.keys())
    assert not (FOOD_ROOTS & PRODUCT_SLUGS.keys())
