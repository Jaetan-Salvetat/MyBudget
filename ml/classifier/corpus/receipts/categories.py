"""Ce qu'une catégorie Open Food Facts vaut dans notre taxonomie.

Une seule table de correspondance sert les deux entrées du corpus ticket : les
noms de produits moissonnés, et les libellés de caisse d'Open Prices que leur
code-barres relie aux mêmes catégories. Deux copies finiraient par diverger, et
un même produit porterait deux classes selon la porte par laquelle il entre.

La taxonomie est une taxonomie de marchands : la classe d'un produit est celle
du commerce où on l'achète normalement. Le pain va chez le boulanger, les
boissons à l'épicerie, l'alimentation animale à l'animalerie, la cosmétique et
la parapharmacie à leur rayon ; tout le reste est du supermarché.

`knowledge/sources/openfoodfacts.py` moissonne la même taxonomie pour le corpus
quick-add et lit ici la même règle. Deux règles feraient dire au modèle que
`baguette` est boulangerie quand elle vient du quick-add et supermarché quand
elle vient d'un ticket : mesuré sur les corpus livrés, 4,9 % des textes présents
des deux côtés portaient déjà deux classes.

Quatre bases partagent cette table. Open Food Facts et Open Beauty Facts ne
répondent que de la moitié alimentaire et cosmétique ; Open Products Facts
apporte l'entretien, la presse, l'électronique, le tabac et la papeterie, et
Open Pet Food Facts l'animalerie. Ce sont les classes où le corpus ticket était
le plus mince, et la seule chose qui change d'une base à l'autre est la table
de correspondance — jamais la règle.
"""

SUPERMARCHE = "alimentation.supermarche"
ANIMAUX = "divers.animaux"
ESTHETIQUE = "sante_beaute.esthetique"
PHARMACIE = "sante_beaute.pharmacie"

PET_TAGS = ("en:pet-food", "en:cat-food", "en:dog-food", "en:pet-", "fr:aliments-pour-animaux")
COSMETIC_TAGS = ("en:makeup", "en:make-up", "en:perfumes", "en:fragrances", "en:nail-polish",
                 "en:nail-makeup", "en:lip-cosmetics", "en:lipsticks", "en:mascaras", "en:eyeshadow",
                 "en:foundations", "en:eau-de-toilette", "en:eau-de-parfum", "en:colognes")
PHARMA_TAGS = ("en:medicines", "en:dietary-supplements", "en:food-supplements", "en:baby-milks",
               "en:infant-formulas", "en:first-aid")
SKIP_TAGS = ("en:non-food-products", "en:open-beauty-facts", "en:open-products-facts")

BOULANGERIE = "alimentation.boulangerie"
EPICERIE = "alimentation.epicerie"

BAKERY_WORDS = frozenset({"bread", "breads", "loaf", "loaves", "bun", "buns", "pastry",
                          "pastries", "cake", "cakes", "cookie", "cookies", "muffin", "muffins",
                          "donut", "donuts", "croissant", "croissants", "baguette", "baguettes",
                          "brioche", "brioches", "viennoiserie", "viennoiseries", "biscuit",
                          "biscuits", "pain", "pains", "gateau", "gateaux", "tarte", "tartes"})
GROCERY_WORDS = frozenset({"beverage", "beverages", "drink", "drinks", "juice", "juices",
                           "water", "waters", "soda", "sodas", "beer", "beers", "wine",
                           "wines", "spirit", "spirits", "coffee", "tea", "teas"})


def food_family(*names: str) -> str:
    """Le commerce d'un produit alimentaire, d'après les mots de sa catégorie."""
    words = {word.lower().strip(",") for name in names for word in name.split()}
    if words & BAKERY_WORDS:
        return BOULANGERIE
    if words & GROCERY_WORDS:
        return EPICERIE
    return SUPERMARCHE


def _words_of(tag: str) -> str:
    """« en:wholemeal-sliced-breads » → « wholemeal sliced breads »."""
    return tag.split(":", 1)[-1].replace("-", " ")


def food_slug(tags: list[str]) -> str | None:
    """La classe d'un produit alimentaire. `None` quand le produit n'en est pas un.

    Seule la catégorie la plus fine est lue : les tags portent toute
    l'ascendance, et `en:plant-based-foods-and-beverages` ferait passer une
    tablette de chocolat pour une boisson."""
    for tag in tags:
        if tag.startswith(PET_TAGS):
            return ANIMAUX
        if tag.startswith(SKIP_TAGS):
            return None
    return food_family(_words_of(tags[-1])) if tags else SUPERMARCHE


def beauty_slug(tags: list[str]) -> str:
    """La classe d'un produit d'hygiène-beauté : cosmétique, parapharmacie, ou rayon."""
    for tag in tags:
        if tag.startswith(COSMETIC_TAGS):
            return ESTHETIQUE
        if tag.startswith(PHARMA_TAGS):
            return PHARMACIE
    return SUPERMARCHE


# Open Products Facts ne décrit pas une famille de produits mais tout ce qui
# n'en est pas une : entretien, presse, électronique, tabac, papeterie. Sa
# taxonomie est celle de Google Shopping, où une catégorie porte toute son
# ascendance — d'où la lecture du tag le plus fin vers le plus large.
PRODUCT_TAGS: dict[str, tuple[str, ...]] = {
    # supermarché : entretien, hygiène courante, papier, jetable, bébé
    SUPERMARCHE: (
        "en:home-garden", "en:household-supplies", "en:household-cleaning-supplies",
        "en:household-chemicals", "en:household-cleaning-products",
        "en:cleaning-and-janitorial-supplies", "en:cleaning-equipment-and-supplies",
        "en:cleaning-and-disinfecting-solutions", "en:muti-surface-cleaners",
        "en:glass-surface-cleaners", "en:drain-cleaners", "en:toilet-bowl-cleaners",
        "en:toilet-gel", "en:descalers-decalcifiers", "en:bleach", "en:bleach-tabs",
        "en:detergents", "en:laundry-supplies", "en:laundry-detergents", "en:laundry-detergent",
        "en:liquid-detergent", "en:fabric-softeners-dryer-sheets", "en:dish-detergent-soap",
        "en:dishwasher-cleaners", "en:dishwasher-tablets", "en:liquide-vaisselle",
        "en:household-paper-products", "en:paper-products", "en:paper-materials-and-products",
        "en:toilet-papers", "en:facial-tissues", "en:garbage-bags", "en:sponges-scouring-pads",
        "en:household-sponges", "en:shop-towels-general-purpose-cleaning-cloths",
        "en:cleaning-gloves", "en:disposable-gloves", "en:food-wraps",
        "en:aluminium-kitchen-foil", "en:parchment-paper", "en:coffee-filters", "en:chemicals",
        "en:baby-toddler", "en:diapers", "en:diapering", "en:nursing-feeding",
        "en:food-beverage-carriers", "en:shipping-supplies", "en:packing-tape", "en:duct-tape",
        "en:tests", "fr:produit-menager", "fr:menager", "fr:nettoyant", "fr:nettoyage",
        "fr:produit-entretien", "fr:produit-d-entretien", "fr:vinaigre-menager",
        "fr:bicarbonate-de-soude", "en:bicarbonates-of-soda", "fr:sel-regenerant",
        "fr:desodorisant", "fr:insecticide", "fr:allume-feu", "fr:lingettes",
        "fr:lingettes-multi-usages", "fr:chiffons-microfibres", "fr:eponges", "fr:sopalin",
        "fr:mouchoirs", "fr:papiers-toilette", "fr:adoucissants", "fr:assouplissant",
        "fr:sachets-a-glacons", "fr:sacs-a-glacons", "fr:film-fraicheur", "fr:blocs-wc",
        "fr:colle", "en:glues", "en:adhesives", "fr:nettoyants-pour-vitroceramique",
        "fr:hard-surface-cleaning-products", "fr:dishwasher-detergents",
        "fr:hand-dishwashing-detergents", "en:tablettes-pour-lave-vaisselle",
        "fr:tissue-paper-and-tissue-products",
    ),
    # livre & presse
    "loisirs.livre_presse": (
        "en:printed-publications", "en:printed-media", "en:published-products",
        "en:publications", "en:media", "en:books", "en:magazines", "en:magazines-newspapers",
        "en:comic-books", "en:cooking-books", "en:electronic-publications-and-music",
        "en:electronic-reference-material", "en:dvds-videos", "en:film-television-dvds",
        "en:livres", "en:manuels-scolaires", "fr:dictionnaires", "fr:manga", "fr:carte",
    ),
    # électronique & électroménager
    "shopping.electronique": (
        "en:electronics", "en:electronics-accessories", "en:consumer-electronics",
        "en:smart-devices", "en:hardware-accessories", "en:telephony", "en:communications",
        "en:communications-devices-and-accessories", "en:personal-communication-devices",
        "en:mobile-phones", "en:mobile-phone-accessories", "en:smartphones",
        "en:android-smartphones", "en:iphone-smartphones", "en:ios-smartphone", "en:computers",
        "en:laptops", "en:tablet-computers", "en:computer-components", "en:input-devices",
        "en:mice-trackballs", "en:storage-devices", "en:hard-drives", "en:external-hard-drive",
        "en:audio", "en:audio-components", "en:audio-and-visual-equipment", "en:headphones",
        "en:headphones-headsets", "en:headsets", "en:cameras", "en:cameras-optics",
        "en:digital-cameras", "en:camera-optic-accessories", "en:smartwatches",
        "en:wearos-smartwatches", "en:watches", "en:batteries", "en:cr2032-batteries",
        "en:power", "en:usb-cables", "en:print-copy-scan-fax", "en:printer-consumables",
        "en:printer-copier-fax-machine-accessories", "en:toner-inkjet-cartridges",
        "en:cartouches-d-encre-et-toners", "en:appliances", "en:domestic-appliances",
        "en:household-appliances", "en:household-appliance-accessories",
        "en:domestic-appliances-and-supplies-and-consumer-electronic-products",
        "en:kitchen-appliances", "en:domestic-kitchen-appliances", "en:laundry-appliances",
        "en:kitchen-appliance-accessories", "en:dishwashers", "en:washing-machines",
        "en:vacuums", "en:vacuum-accessories", "en:aspirateurs", "en:toasters-grills",
        "en:deep-fryers", "en:coffee-maker-espresso-machine-accessories",
        "en:flashlights-headlamps", "en:headlamps", "en:light-bulbs", "en:lighting",
        "en:information-technology-broadcasting-and-telecommunications",
        "fr:ordinateur-portable", "fr:lave-vaisselle", "fr:lave-linge-top",
        "fr:lave-linge-hublot", "fr:aspirateurs", "fr:aspirateur-filaire",
        "fr:aspirateur-non-filaire", "fr:sacs-pour-aspirateurs", "fr:smartphones", "fr:phone",
        "fr:souris-d-ordinateur", "fr:casque-audio", "fr:cables-hdmi", "fr:multiprise",
        "fr:piles-rechargeables", "fr:cd-r",
    ),
    # jeux vidéo
    "loisirs.jeux_video": (
        "en:video-games", "en:video-game-consoles", "en:game-controllers",
    ),
    # jouets & activités enfants
    "famille_education.activites_enfants": (
        "en:toys-games", "en:toys", "en:games", "en:board-games", "en:card-games", "en:puzzles",
        "en:jigsaw-puzzles", "en:construction-sets", "en:building-toys",
        "en:childrens-blocks-and-building-systems",
        "en:musical-instruments-and-games-and-toys-and-arts-and-crafts-and-educational-equipment-and-materials-and-accessories-and-supplies",
        "fr:jeu-de-societe",
    ),
    # tabac & jeux
    "divers.tabac_jeux": (
        "en:tobacco-products", "en:tobacco", "en:tobacco-and-substitutes",
        "en:tobacco-and-smoking-products-and-substitutes", "en:cigarettes", "en:cigarillos",
        "en:cigarettes-or-cigars", "en:lighters-matches", "en:matches", "fr:tabac",
        "fr:tobacco", "fr:feuilles-a-rouler", "fr:e-liquide",
        "fr:liquide-pour-cigarettes-electroniques", "fr:jeux-de-grattage", "fr:jeux-de-hasard",
    ),
    # fournitures scolaires & bureau
    "famille_education.fournitures": (
        "en:office-supplies", "en:general-office-supplies", "en:office-instruments",
        "en:office-equipment-and-accessories-and-supplies", "en:writing-drawing-instruments",
        "en:writing-instruments", "en:pens", "en:pens-pencils", "en:pencils", "en:crayons",
        "en:markers-highlighters", "en:highlighters", "en:notebooks", "en:notebooks-notepads",
        "en:paper-pads-or-notebooks", "en:index-cards", "en:sticky-notes", "en:binders",
        "en:binding-supplies", "en:filing-organization", "en:staples", "en:paper-clips-clamps",
        "en:tacks-pushpins", "en:office-tape", "en:correction-tapes",
        "en:correction-fluids-pens-tapes", "en:printing-and-writing-paper", "en:papers",
        "en:arts-crafts", "en:art-crafting-tools", "en:art-crafting-materials",
        "en:hobbies-creative-arts", "fr:feutres", "fr:stylos-bille", "fr:crayons-de-couleur",
        "fr:cahiers-de-texte",
    ),
    # pharmacie & parapharmacie
    PHARMACIE: (
        "en:health-care", "en:medical", "en:medical-products", "en:medical-supplies",
        "en:medicine", "en:medicine-drugs", "en:medicaments", "en:medical-tape-bandages",
        "en:paracetamol", "en:first-aid", "en:dietary-supplements", "en:vitamins",
        "en:vitamins-supplements", "en:fitness-nutrition", "en:feminine-sanitary-supplies",
        "en:sanitary-napkins", "en:menstrual-protections", "en:tampons", "en:vision-care",
        "en:eyewear-accessories", "en:eyewear-lens-cleaning-solutions",
        "fr:complement-alimentaire", "fr:pansements", "fr:pansements-pour-ampoules",
        "fr:sparadrap", "fr:sparadrap-microporeux", "fr:masques-chirurgicaux",
        "fr:produits-menstruels", "fr:produits-menstruels-reutilisables",
        "fr:produits-menstruels-pour-flux-abondants",
        "fr:produits-menstruels-pour-flux-moderes", "fr:culottes-de-regles",
        "fr:protege-lingerie", "fr:tampons-hygieniques-avec-applicateur",
        "fr:tampons-hygieniques-sans-applicateur", "fr:lingettes-optiques",
        "fr:lingettes-pour-lunettes",
    ),
    # vêtements & accessoires
    "shopping.vetements": (
        "en:apparel-accessories", "en:apparel-and-luggage-and-personal-care-products",
        "en:clothing", "en:clothing-accessories", "en:underwear-socks", "en:socks",
        "en:hosiery", "en:t-shirts", "en:shoes", "en:sport-shoes", "en:shoe-care-tools",
        "en:luggage-bags", "en:jewelry", "en:cycling-apparel-accessories", "fr:veste",
        "fr:gants", "fr:chaussettes-de-course-a-pied", "fr:chaussettes-de-velo",
    ),
    # mobilier & déco
    "shopping.mobilier_deco": (
        "en:decor", "en:furniture", "en:chairs", "en:chaises", "en:linens-bedding", "en:towels",
        "en:home-fragrances", "en:candles", "en:scented-candles", "en:birthday-candles",
        "en:kitchen-dining", "en:kitchenware", "en:domestic-kitchenware-and-kitchen-supplies",
        "en:cookware", "en:cookware-bakeware", "en:domestic-cookware",
        "en:domestic-pressure-cookers", "en:pressure-cookers-canners", "en:tableware",
        "en:drinkware", "en:flatware", "en:tumblers", "en:glass", "en:kitchen-tools-utensils",
        "en:food-storage", "en:storage-organization", "en:bathroom-accessories",
        "en:seasonal-holiday-decorations", "en:holiday-ornaments", "en:halloween-supplies",
        "en:party-celebration", "en:party-supplies", "en:snow-globes", "en:snowglobes",
        "en:plants", "en:seeds", "en:lawn-garden", "en:gardening",
        "en:live-plant-and-animal-material-and-accessories-and-supplies", "en:measuring-scales",
        "fr:poeles", "fr:bocaux", "fr:bocaux-de-conserve", "fr:sapins", "fr:filtres-a-the",
        "fr:furniture", "fr:maison",
    ),
    # bricolage & travaux
    "logement.travaux": (
        "en:tools", "en:tool-accessories", "en:hardware", "en:hardware-fasteners",
        "en:wrenches", "en:plumbing", "en:plumbing-fixture-hardware-parts", "en:shower-parts",
        "en:ballcocks-flappers", "en:toilet-bidet-accessories", "en:building-materials",
        "en:building-consumables", "en:adhesives-and-sealants", "en:adhesives-sealants",
        "en:smoke-detectors", "en:smoke-carbon-monoxide-detectors", "en:flood-fire-gas-safety",
        "en:measuring-tools-sensors", "en:business-industrial",
        "en:manufacturing-components-and-supplies", "fr:embouts-de-tournevis", "fr:cadenas",
    ),
    # entretien du véhicule
    "transport.entretien_vehicule": (
        "en:vehicles-parts", "en:vehicle-parts-accessories", "en:motor-vehicle-parts",
        "en:vehicle-fluids", "en:vehicle-cooling-system-additives",
        "en:vehicle-maintenance-care-decor", "en:lubricants", "en:bicycle-parts",
        "en:bicycle-accessories",
    ),
    # sport
    "loisirs.sport": (
        "en:sporting-goods", "en:outdoor-recreation", "en:cycling", "fr:sport",
    ),
    # musique
    "loisirs.musique": (
        "en:music-on-tape-or-compact-disc", "fr:cordes-de-guitare-acoustique",
    ),
    # logiciel
    "numerique.logiciel_service": (
        "en:software",
    ),
    # animalerie
    ANIMAUX: (
        "en:animals-pet-supplies", "en:pet-supplies", "en:pet-litter", "en:dog-supplies",
        "fr:litiere",
    ),
    # cadeaux
    "divers.cadeau_offert": (
        "en:gift-giving", "en:gift-cards-certificates", "en:collectibles",
    ),
}

PRODUCT_SLUGS = {tag: slug for slug, tags in PRODUCT_TAGS.items() for tag in tags}

# Un produit d'Open Products Facts rangé sous l'alimentaire ou l'hygiène-beauté
# est rendu à la base qui en répond : deux tables pour la même question feraient
# du dentifrice un produit de rayon d'un côté et un cosmétique de l'autre.
BEAUTY_ROOTS = frozenset({
    "en:health-beauty", "en:personal-care", "en:personal-care-products", "en:cosmetics",
    "en:hair-care", "en:oral-care", "en:bath-body", "en:shaving-grooming", "en:hair-accessories",
    "en:hair-styling-tools", "en:massage-relaxation",
})
FOOD_ROOTS = frozenset({
    "en:plant-based-foods", "en:plant-based-foods-and-beverages", "en:beverages",
    "en:beverages-and-beverages-preparations", "en:dairies", "en:snacks", "en:sweet-snacks",
    "en:salty-snacks", "en:biscuits", "en:biscuits-and-cakes", "en:biscuits-and-crackers",
    "en:crackers-appetizers", "en:meals", "en:desserts", "en:appetizers", "en:breakfasts",
    "en:breakfast-cereals", "en:cereals-and-potatoes", "en:cereals-and-their-products",
    "en:condiments", "en:spreads", "en:sweet-spreads", "en:confectioneries", "en:candies",
    "en:chocolates", "en:cocoa-and-its-products", "en:honeys", "en:vinegars", "en:sweeteners",
    "en:legumes", "en:legumes-and-their-products", "en:fruits-and-vegetables-based-foods",
    "en:vegetables-based-foods", "en:meats", "en:meats-and-their-products", "en:prepared-meats",
    "en:cheeses", "en:yogurts", "en:fats", "en:nuts-and-their-products", "en:groceries",
    "en:alcoholic-beverages", "en:beers", "en:festive-foods", "en:culinary-plants",
    "en:food-additives", "en:anticaking-agents", "en:bee-products", "en:farming-products",
    "en:fermented-foods", "en:fermented-milk-products", "en:fermented-dairy-desserts",
    "en:dairy-desserts", "en:food-beverage-and-tobacco-products", "fr:vin", "fr:boisson",
})

# Un contributeur qui range un yaourt dans Open Products Facts le fait signaler
# par la base elle-même. Le produit existe, sa catégorie ne veut rien dire.
MISFILED_TAG = "en:incorrect-product-type"


def products_slug(tags: list[str]) -> str | None:
    """La classe d'un produit non alimentaire. `None` quand rien ne la porte.

    Les tags vont du plus large au plus fin ; les lire à l'envers prend la
    catégorie la plus précise que la table connaît, et laisse passer les
    feuilles qui ne décrivent pas un commerce (« en:3-ply », « en:160-sheets »).
    Un produit dont aucun tag ne parle sort du corpus : une ligne de moins vaut
    mieux qu'une ligne rangée au supermarché par défaut."""
    if MISFILED_TAG in tags:
        return None
    for tag in reversed(tags):
        if tag in PRODUCT_SLUGS:
            return PRODUCT_SLUGS[tag]
        if tag in BEAUTY_ROOTS:
            return beauty_slug(tags)
        if tag in FOOD_ROOTS:
            return food_slug(tags)
    return None


def petfood_slug(tags: list[str]) -> str | None:
    """La classe d'un produit d'Open Pet Food Facts.

    La base entière est de l'alimentation animale : lire ses catégories ne
    servirait qu'à ranger ailleurs les quelques produits que ses contributeurs
    ont mal étiquetés."""
    return None if MISFILED_TAG in tags else ANIMAUX
