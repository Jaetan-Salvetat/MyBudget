import json
import random
from pathlib import Path

DATASET_DIR = Path(__file__).parent / "dataset"
SEED = 42

LABELS: list[str] = [
    "alimentation.supermarché",
    "alimentation.marché",
    "alimentation.épicerie",
    "alimentation.boulangerie",
    "restauration.restaurant",
    "restauration.fast-food/friterie",
    "restauration.bar/apéro",
    "restauration.café",
    "restauration.livraison",
    "transport.essence",
    "transport.transport en commun",
    "transport.taxi/VTC",
    "transport.parking",
    "transport.péage",
    "transport.entretien véhicule",
    "logement.loyer",
    "logement.charges",
    "logement.énergie",
    "logement.eau",
    "logement.télécom/internet",
    "logement.assurance",
    "sante_beaute.médecin",
    "sante_beaute.pharmacie",
    "sante_beaute.mutuelle",
    "sante_beaute.coiffeur",
    "sante_beaute.esthétique",
    "loisirs.cinéma/sorties",
    "loisirs.jeux vidéo",
    "loisirs.sport",
    "loisirs.manga/livres",
    "loisirs.streaming",
    "loisirs.musique",
    "shopping.vêtements",
    "shopping.électronique",
    "shopping.mobilier/déco",
    "finance_taxes.retrait DAB",
    "finance_taxes.frais bancaires",
    "finance_taxes.impôts/taxes",
    "finance_taxes.amendes",
    "education.scolarité",
    "education.fournitures",
    "education.formation",
    "divers.cadeau offert",
    "divers.vétérinaire/animaux",
    "divers.tabac/jeux d'argent",
    "divers.autre",
    "salaire.salaire net",
    "salaire.prime",
    "salaire.revenu freelance",
    "transfert.virement reçu",
    "transfert.remboursement santé",
    "transfert.remboursement ami",
    "exceptionnel.vente occasion",
    "exceptionnel.don reçu",
    "exceptionnel.intérêts",
]

NUM_EXPENSE = 46
NUM_INCOME = 9

# (text, recurrence)  —  rec: 0=ponctuel, 1=fixe
# type is derived: cat_idx < 46 → expense (0), else income (1)

DATA: dict[int, list[tuple[str, int]]] = {
    # ── alimentation.supermarché (0) ────────────────────────
    0: [
        ("carrefour", 0), ("leclerc", 0), ("auchan", 0), ("lidl", 0),
        ("intermarché", 0), ("casino", 0), ("monoprix", 0), ("franprix", 0),
        ("super u", 0), ("picard", 0), ("biocoop", 0), ("naturalia", 0),
        ("aldi", 0), ("netto", 0), ("cora", 0), ("géant", 0), ("hyper u", 0),
        ("match supermarché", 0), ("colruyt", 0), ("dia", 0),
        ("courses", 0), ("courses carrefour", 0), ("courses leclerc", 0),
        ("courses auchan", 0), ("provisions", 0), ("commissions", 0),
        ("supermarché", 0), ("grande surface", 0), ("ravitaillement", 0),
        ("courses de la semaine", 0), ("provisions du week-end", 0),
        ("plein de courses", 0), ("shopping alimentaire", 0),
        ("courses du samedi", 0), ("provisions ménage", 0),
        ("Einkaufen", 0), ("Supermarkt", 0), ("compras supermercado", 0),
        ("grocery", 0), ("groceries", 0), ("courses maison", 0),
        ("carrefour market", 0), ("monop", 0), ("courses bio", 0),
        ("grand frais", 0), ("courses hebdo", 0), ("provisions familiales", 0),
        ("fournitures alimentaires", 0), ("courses alimentaires", 0),
    ],

    # ── alimentation.marché (1) ─────────────────────────────
    1: [
        ("marché", 0), ("marché du dimanche", 0), ("marché du village", 0),
        ("marché bio", 0), ("marché fermier", 0), ("marché couvert", 0),
        ("producteur local", 0), ("légumes du marché", 0),
        ("fruits du marché", 0), ("marché du samedi", 0),
        ("marché aux légumes", 0), ("maraîcher", 0), ("producteur", 0),
        ("marché de plein air", 0), ("fruits et légumes", 0),
        ("panier de légumes", 0), ("marché nocturne", 0),
        ("petit marché", 0), ("vente directe producteur", 0),
        ("marché hebdomadaire", 0), ("Wochenmarkt", 0), ("mercado", 0),
        ("farmer market", 0), ("légumes frais", 0), ("fruits frais", 0),
        ("marché aux fleurs", 0), ("primeur", 0), ("marché local", 0),
        ("produits fermiers", 0), ("cueillette", 0),
    ],

    # ── alimentation.épicerie (2) ───────────────────────────
    2: [
        ("épicerie", 0), ("épicerie du coin", 0), ("petit casino", 0),
        ("proxy", 0), ("carrefour city", 0), ("carrefour express", 0),
        ("8 à huit", 0), ("épicerie fine", 0), ("épicerie bio", 0),
        ("petit commerce", 0), ("dépanneur", 0), ("supérette", 0),
        ("épicerie arabe", 0), ("épicerie asiatique", 0), ("tang frères", 0),
        ("paris store", 0), ("épicerie orientale", 0), ("Kiosk", 0),
        ("tienda", 0), ("corner shop", 0), ("convenience store", 0),
        ("mini market", 0), ("night shop", 0), ("petite commission", 0),
        ("spar", 0), ("vival", 0), ("utile", 0), ("coccinelle", 0),
        ("épicerie italienne", 0), ("traiteur", 0), ("épicerie de quartier", 0),
    ],

    # ── alimentation.boulangerie (3) ────────────────────────
    3: [
        ("boulangerie", 0), ("boulang", 0), ("paul", 0), ("pain", 0),
        ("baguette", 0), ("croissant", 0), ("pain au chocolat", 0),
        ("viennoiserie", 0), ("pâtisserie", 0), ("gâteau", 0),
        ("brioche", 0), ("tarte", 0), ("sandwich boulangerie", 0),
        ("éclair", 0), ("macaron", 0), ("mille-feuille", 0),
        ("fougasse", 0), ("quiche", 0), ("croque", 0),
        ("Bäckerei", 0), ("Brot", 0), ("panadería", 0), ("bakery", 0),
        ("la mie câline", 0), ("marie blachère", 0), ("feuillantine", 0),
        ("pain de campagne", 0), ("petit déj boulangerie", 0),
        ("goûter boulangerie", 0), ("tartine", 0), ("kouign-amann", 0),
        ("chausson aux pommes", 0), ("palmier", 0), ("chouquettes", 0),
    ],

    # ── restauration.restaurant (4) ─────────────────────────
    4: [
        ("restaurant", 0), ("resto", 0), ("pizzeria", 0), ("sushi", 0),
        ("thaï", 0), ("indien", 0), ("chinois", 0), ("libanais", 0),
        ("japonais", 0), ("italien", 0), ("mexicain", 0), ("couscous", 0),
        ("steakhouse", 0), ("brasserie", 0), ("bistrot", 0),
        ("trattoria", 0), ("auberge", 0), ("taverne", 0),
        ("dîner", 0), ("déjeuner", 0), ("repas", 0),
        ("manger dehors", 0), ("sortie resto", 0), ("repas en amoureux", 0),
        ("dîner anniversaire", 0), ("brunch", 0), ("buffet", 0),
        ("crêperie", 0), ("wok", 0), ("ramen", 0), ("pho", 0),
        ("resto du midi", 0), ("repas d'affaires", 0), ("gastro", 0),
        ("restaurant gastronomique", 0), ("table d'hôte", 0),
        ("resto entre amis", 0), ("grill", 0), ("fish and chips", 0),
        ("Restaurant", 0), ("Restaurante", 0), ("tapas", 0),
        ("dim sum", 0), ("fondue", 0), ("raclette resto", 0),
        ("cantine", 0), ("repas du soir", 0), ("lunch", 0),
    ],

    # ── restauration.fast-food/friterie (5) ─────────────────
    5: [
        ("macdo", 0), ("mcdo", 0), ("mcdonald's", 0), ("mac do", 0),
        ("burger king", 0), ("bk", 0), ("kfc", 0), ("subway", 0),
        ("five guys", 0), ("quick", 0), ("o'tacos", 0),
        ("kebab", 0), ("tacos", 0), ("hamburger", 0), ("burger", 0),
        ("wrap", 0), ("frites", 0), ("fast-food", 0), ("fastfood", 0),
        ("friterie", 0), ("baraque à frites", 0), ("frituur", 0),
        ("pizza à emporter", 0), ("döner", 0), ("shawarma", 0),
        ("gyros", 0), ("hot dog", 0), ("chicken wings", 0),
        ("nuggets", 0), ("Schnellimbiss", 0), ("comida rápida", 0),
        ("naan", 0), ("panini", 0), ("grec", 0),
        ("sandwich kebab", 0), ("galette kebab", 0), ("durum", 0),
        ("chipotle", 0), ("popeyes", 0), ("dominos", 0), ("pizza hut", 0),
    ],

    # ── restauration.bar/apéro (6) ──────────────────────────
    6: [
        ("bar", 0), ("apéro", 0), ("bière", 0), ("bières", 0),
        ("verre", 0), ("tournée", 0), ("cocktail", 0), ("cocktails", 0),
        ("happy hour", 0), ("afterwork", 0), ("pub", 0), ("taverne", 0),
        ("terrasse", 0), ("drink", 0), ("drinks", 0), ("soirée bar", 0),
        ("bières avec les potes", 0), ("apéro entre amis", 0),
        ("mojito", 0), ("pinte", 0), ("demi", 0), ("verre de vin", 0),
        ("shots", 0), ("Kneipe", 0), ("cerveza", 0), ("beer", 0),
        ("vin au bar", 0), ("soirée", 0), ("rooftop", 0),
        ("wine bar", 0), ("bar à cocktails", 0), ("lounge", 0),
        ("bière artisanale", 0), ("craft beer", 0), ("apéro dînatoire", 0),
        ("boire un coup", 0), ("pot entre collègues", 0), ("pot de départ", 0),
    ],

    # ── restauration.café (7) ───────────────────────────────
    7: [
        ("café", 0), ("starbucks", 0), ("columbus café", 0),
        ("expresso", 0), ("espresso", 0), ("cappuccino", 0),
        ("latte", 0), ("thé", 0), ("chocolat chaud", 0),
        ("café du matin", 0), ("pause café", 0), ("coffee shop", 0),
        ("café crème", 0), ("noisette", 0), ("allongé", 0),
        ("matcha", 0), ("chai latte", 0), ("café glacé", 0),
        ("frappuccino", 0), ("café gourmand", 0), ("thé glacé", 0),
        ("coffee", 0), ("Kaffee", 0), ("café con leche", 0),
        ("bubble tea", 0), ("salon de thé", 0), ("tisane", 0),
        ("décaféiné", 0), ("café à emporter", 0), ("viennois", 0),
    ],

    # ── restauration.livraison (8) ──────────────────────────
    8: [
        ("uber eats", 0), ("deliveroo", 0), ("just eat", 0),
        ("frichti", 0), ("livraison", 0), ("commande livrée", 0),
        ("livraison repas", 0), ("à emporter", 0), ("takeaway", 0),
        ("commande uber eats", 0), ("commande deliveroo", 0),
        ("livraison sushi", 0), ("livraison pizza", 0),
        ("livraison chinois", 0), ("livraison thaï", 0),
        ("lieferando", 0), ("Lieferung", 0), ("delivery", 0),
        ("glovo", 0), ("wolt", 0), ("commande en ligne repas", 0),
        ("repas livré", 0), ("livraison à domicile", 0),
        ("click and collect resto", 0), ("meal delivery", 0),
        ("commande resto", 0), ("take away", 0), ("emporter", 0),
    ],

    # ── transport.essence (9) ───────────────────────────────
    9: [
        ("essence", 0), ("plein", 0), ("carburant", 0), ("diesel", 0),
        ("gasoil", 0), ("gazole", 0), ("sans plomb", 0), ("SP95", 0),
        ("SP98", 0), ("plein d'essence", 0), ("station-service", 0),
        ("plein voiture", 0), ("total", 0), ("totalenergies", 0),
        ("bp", 0), ("shell", 0), ("esso", 0), ("avia", 0),
        ("Tankstelle", 0), ("Benzin", 0), ("gasolina", 0), ("fuel", 0),
        ("gas station", 0), ("pompe à essence", 0), ("plein diesel", 0),
        ("plein SP95", 0), ("ravitaillement voiture", 0),
        ("carburant voiture", 0), ("recharge carburant", 0),
        ("faire le plein", 0), ("plein du véhicule", 0),
    ],

    # ── transport.transport en commun (10) — MIXED ──────────
    10: [
        ("ticket métro", 0), ("billet de bus", 0), ("trajet tram", 0),
        ("ticket de tram", 0), ("billet de train", 0),
        ("aller simple", 0), ("aller-retour", 0), ("ticket bus", 0),
        ("ticket RER", 0), ("billet RER", 0), ("billet TGV", 0),
        ("TER", 0), ("SNCF", 0), ("trajet en bus", 0),
        ("Fahrkarte", 0), ("billete metro", 0), ("bus ticket", 0),
        ("train ticket", 0), ("billet avion", 0), ("vol", 0),
        ("transport en commun", 0), ("métro", 0), ("tram", 0),
        ("ticket t+", 0), ("carnet de tickets", 0),
        ("navigo", 1), ("pass navigo", 1), ("abonnement bus", 1),
        ("carte de transport", 1), ("abonnement tram", 1),
        ("abonnement métro", 1), ("pass mensuel", 1),
        ("carte orange", 1), ("imagine R", 1), ("abonnement TER", 1),
        ("abonnement SNCF", 1), ("pass transport", 1),
        ("forfait transport", 1), ("Monatskarte", 1),
        ("monthly pass", 1), ("abono transporte", 1),
    ],

    # ── transport.taxi/VTC (11) ─────────────────────────────
    11: [
        ("uber", 0), ("bolt", 0), ("heetch", 0), ("lyft", 0),
        ("kapten", 0), ("taxi", 0), ("VTC", 0), ("vtc", 0),
        ("course taxi", 0), ("trajet uber", 0), ("chauffeur privé", 0),
        ("course vtc", 0), ("taxi aéroport", 0), ("taxi gare", 0),
        ("uber trajet", 0), ("bolt course", 0), ("G7", 0),
        ("taxi parisien", 0), ("Taxi", 0), ("taxi ride", 0),
        ("cab", 0), ("taxista", 0), ("ride", 0),
        ("course en taxi", 0), ("voiture avec chauffeur", 0),
        ("marcel", 0), ("freenow", 0), ("taxi de nuit", 0),
    ],

    # ── transport.parking (12) ──────────────────────────────
    12: [
        ("parking", 0), ("parcmètre", 0), ("stationnement", 0),
        ("place de parking", 0), ("parking aéroport", 0),
        ("horodateur", 0), ("park", 0), ("parking gare", 0),
        ("parking souterrain", 0), ("parking relais", 0),
        ("Parkplatz", 0), ("aparcamiento", 0), ("car park", 0),
        ("parking centre-ville", 0), ("vinci parking", 0),
        ("effia", 0), ("indigo", 0), ("Q-Park", 0),
        ("parking visiteur", 0), ("place de stationnement", 0),
        ("frais de parking", 0), ("ticket parking", 0),
        ("parking hôpital", 0), ("parking commercial", 0),
    ],

    # ── transport.péage (13) ────────────────────────────────
    13: [
        ("péage", 0), ("autoroute", 0), ("péage autoroute", 0),
        ("télépéage", 0), ("badge autoroute", 0), ("vinci autoroutes", 0),
        ("sanef", 0), ("aprr", 0), ("cofiroute", 0), ("area", 0),
        ("frais d'autoroute", 0), ("Maut", 0), ("peaje", 0),
        ("toll", 0), ("highway toll", 0), ("péage aller-retour", 0),
        ("badge télépéage", 0), ("liber-t", 0), ("bip&go", 0),
        ("trajet autoroute", 0), ("section à péage", 0),
        ("péage tunnel", 0), ("péage pont", 0),
    ],

    # ── transport.entretien véhicule (14) — MIXED ───────────
    14: [
        ("réparation voiture", 0), ("pneu", 0), ("pneus", 0),
        ("vidange", 0), ("carrosserie", 0), ("batterie voiture", 0),
        ("réparation auto", 0), ("dépannage", 0), ("mécanicien", 0),
        ("garagiste", 0), ("changement pneu", 0), ("freins", 0),
        ("plaquettes de frein", 0), ("pot d'échappement", 0),
        ("amortisseurs", 0), ("pare-brise", 0), ("carglass", 0),
        ("norauto", 0), ("feu vert", 0), ("midas", 0),
        ("speedy", 0), ("euromaster", 0), ("Autowerkstatt", 0),
        ("car repair", 0), ("taller mecánico", 0),
        ("lavage auto", 0), ("nettoyage voiture", 0),
        ("contrôle technique", 1), ("révision annuelle", 1),
        ("entretien annuel", 1), ("révision voiture", 1),
        ("contrôle périodique", 1), ("TÜV", 1), ("MOT", 1),
        ("entretien véhicule", 1),
    ],

    # ── logement.loyer (15) — fixe ──────────────────────────
    15: [
        ("loyer", 1), ("loyer mensuel", 1), ("loyer du mois", 1),
        ("loyer mars", 1), ("loyer avril", 1), ("loyer mai", 1),
        ("loyer appartement", 1), ("loyer studio", 1), ("bail", 1),
        ("rent", 1), ("Miete", 1), ("alquiler", 1), ("renta", 1),
        ("loyer colocation", 1), ("loyer chambre", 1),
        ("loyer T2", 1), ("loyer T3", 1), ("loyer maison", 1),
        ("paiement loyer", 1), ("quittance", 1), ("loyer janvier", 1),
        ("loyer février", 1), ("loyer juin", 1), ("loyer juillet", 1),
        ("loyer août", 1), ("loyer septembre", 1), ("loyer octobre", 1),
        ("loyer novembre", 1), ("loyer décembre", 1),
        ("monthly rent", 1), ("Monatsmiete", 1),
    ],

    # ── logement.charges (16) — fixe ────────────────────────
    16: [
        ("charges", 1), ("charges locatives", 1), ("charges copro", 1),
        ("syndic", 1), ("charges de copropriété", 1),
        ("charges mensuelles", 1), ("charges trimestrielles", 1),
        ("provisions sur charges", 1), ("régularisation charges", 1),
        ("charges communes", 1), ("entretien immeuble", 1),
        ("Nebenkosten", 1), ("gastos comunidad", 1),
        ("service charges", 1), ("charges locataire", 1),
        ("charges propriétaire", 1), ("quote-part charges", 1),
        ("appel de fonds syndic", 1), ("charges annuelles", 1),
        ("contribution copro", 1),
    ],

    # ── logement.énergie (17) — fixe ────────────────────────
    17: [
        ("électricité", 1), ("EDF", 1), ("gaz", 1), ("engie", 1),
        ("énergie", 1), ("facture EDF", 1), ("facture gaz", 1),
        ("facture électricité", 1), ("totalenergies gaz", 1),
        ("enercoop", 1), ("direct énergie", 1), ("eni", 1),
        ("Strom", 1), ("Energie", 1), ("electricidad", 1),
        ("electricity bill", 1), ("gas bill", 1), ("energy", 1),
        ("facture énergie", 1), ("consommation électrique", 1),
        ("compteur EDF", 1), ("relevé compteur", 1),
        ("ekwateur", 1), ("ilek", 1), ("mint énergie", 1),
        ("sowee", 1), ("facture mensuelle EDF", 1),
    ],

    # ── logement.eau (18) — fixe ────────────────────────────
    18: [
        ("eau", 1), ("facture d'eau", 1), ("facture eau", 1),
        ("compteur d'eau", 1), ("veolia", 1), ("suez", 1),
        ("lyonnaise des eaux", 1), ("Wasser", 1), ("agua", 1),
        ("water bill", 1), ("consommation eau", 1),
        ("eau chaude", 1), ("relevé eau", 1), ("service des eaux", 1),
        ("abonnement eau", 1), ("facture trimestrielle eau", 1),
        ("redevance eau", 1), ("eau potable", 1),
        ("saur", 1), ("Wasserrechnung", 1),
    ],

    # ── logement.télécom/internet (19) — fixe ───────────────
    19: [
        ("orange", 1), ("SFR", 1), ("bouygues", 1), ("free", 1),
        ("sosh", 1), ("red by SFR", 1), ("B&You", 1), ("byou", 1),
        ("internet", 1), ("box", 1), ("fibre", 1), ("wifi", 1),
        ("forfait mobile", 1), ("téléphone", 1), ("forfait", 1),
        ("abonnement téléphone", 1), ("forfait internet", 1),
        ("box internet", 1), ("livebox", 1), ("freebox", 1),
        ("bbox", 1), ("sfr box", 1), ("Telekom", 1),
        ("Handyvertrag", 1), ("phone plan", 1), ("mobile plan", 1),
        ("facture téléphone", 1), ("facture mobile", 1),
        ("facture internet", 1), ("prixtel", 1), ("coriolis", 1),
        ("NRJ mobile", 1), ("la poste mobile", 1), ("lyca", 1),
        ("réglo mobile", 1), ("mint mobile", 1),
    ],

    # ── logement.assurance (20) — fixe ──────────────────────
    20: [
        ("assurance", 1), ("assurance habitation", 1),
        ("assurance logement", 1), ("assurance maison", 1),
        ("assurance auto", 1), ("assurance voiture", 1),
        ("cotisation assurance", 1), ("MAIF", 1), ("macif", 1),
        ("matmut", 1), ("AXA", 1), ("allianz", 1), ("groupama", 1),
        ("MMA", 1), ("MAAF", 1), ("GMF", 1), ("generali", 1),
        ("Versicherung", 1), ("seguro", 1), ("insurance", 1),
        ("prime d'assurance", 1), ("assurance responsabilité civile", 1),
        ("assurance scolaire", 1), ("assurance vie", 1),
        ("direct assurance", 1), ("luko", 1), ("lovys", 1),
        ("assurance locataire", 1), ("assurance RC", 1),
        ("assurance moto", 1), ("assurance deux-roues", 1),
    ],

    # ── sante_beaute.médecin (21) — ponctuel ────────────────
    21: [
        ("médecin", 0), ("docteur", 0), ("consultation", 0),
        ("généraliste", 0), ("spécialiste", 0), ("dermatologue", 0),
        ("ophtalmo", 0), ("dentiste", 0), ("kiné", 0),
        ("ostéopathe", 0), ("cardiologue", 0), ("pédiatre", 0),
        ("ORL", 0), ("rdv médecin", 0), ("visite médicale", 0),
        ("gynécologue", 0), ("urologue", 0), ("psy", 0),
        ("psychiatre", 0), ("psychologue", 0), ("allergologue", 0),
        ("gastro-entérologue", 0), ("rhumatologue", 0),
        ("Arzt", 0), ("doctor", 0), ("médico", 0),
        ("consultation médicale", 0), ("rdv docteur", 0),
        ("visite chez le médecin", 0), ("check-up", 0),
        ("bilan de santé", 0), ("radio", 0), ("IRM", 0),
        ("scanner", 0), ("prise de sang", 0), ("analyse sang", 0),
        ("labo", 0), ("laboratoire", 0), ("échographie", 0),
    ],

    # ── sante_beaute.pharmacie (22) — ponctuel ──────────────
    22: [
        ("pharmacie", 0), ("médicaments", 0), ("ordonnance", 0),
        ("doliprane", 0), ("paracétamol", 0), ("ibuprofène", 0),
        ("vitamines", 0), ("crème", 0), ("pommade", 0),
        ("sirop", 0), ("antibiotiques", 0), ("collyre", 0),
        ("pansements", 0), ("thermomètre", 0), ("test covid", 0),
        ("Apotheke", 0), ("pharmacy", 0), ("farmacia", 0),
        ("complément alimentaire", 0), ("huile essentielle", 0),
        ("homéopathie", 0), ("automédication", 0),
        ("médicament sans ordonnance", 0), ("gel douche pharma", 0),
        ("crème solaire", 0), ("achat pharmacie", 0),
        ("produits pharma", 0), ("antalgique", 0),
    ],

    # ── sante_beaute.mutuelle (23) — fixe ───────────────────
    23: [
        ("mutuelle", 1), ("complémentaire santé", 1),
        ("couverture santé", 1), ("cotisation mutuelle", 1),
        ("santé complémentaire", 1), ("Harmonie Mutuelle", 1),
        ("MGEN", 1), ("AG2R", 1), ("Alan", 1),
        ("Malakoff Humanis", 1), ("Swiss Life", 1), ("Apicil", 1),
        ("Henner", 1), ("Generali santé", 1),
        ("prévoyance", 1), ("garantie santé", 1),
        ("Krankenversicherung", 1), ("health insurance", 1),
        ("seguro médico", 1), ("cotisation prévoyance", 1),
        ("assurance maladie complémentaire", 1),
        ("mutuelle étudiante", 1), ("mutuelle entreprise", 1),
    ],

    # ── sante_beaute.coiffeur (24) — ponctuel ───────────────
    24: [
        ("coiffeur", 0), ("coupe", 0), ("coiffure", 0),
        ("barbier", 0), ("salon de coiffure", 0), ("coloration", 0),
        ("mèches", 0), ("brushing", 0), ("coupe de cheveux", 0),
        ("teinture", 0), ("lissage", 0), ("dégradé", 0),
        ("barbe", 0), ("rasage", 0), ("shampoing coupe", 0),
        ("Friseur", 0), ("haircut", 0), ("peluquería", 0),
        ("tondeuse coiffeur", 0), ("permanente", 0),
        ("balayage", 0), ("coupe homme", 0), ("coupe femme", 0),
        ("coupe enfant", 0), ("salon", 0), ("barber", 0),
    ],

    # ── sante_beaute.esthétique (25) — ponctuel ─────────────
    25: [
        ("esthétique", 0), ("manucure", 0), ("pédicure", 0),
        ("soin du visage", 0), ("épilation", 0),
        ("institut de beauté", 0), ("spa", 0), ("massage", 0),
        ("onglerie", 0), ("nail bar", 0), ("gommage", 0),
        ("soin corps", 0), ("enveloppement", 0), ("masque visage", 0),
        ("beauté", 0), ("soin esthétique", 0), ("maquillage pro", 0),
        ("pose de cils", 0), ("extension cils", 0),
        ("vernis semi-permanent", 0), ("gel UV", 0),
        ("Kosmetik", 0), ("beauty salon", 0), ("estética", 0),
        ("soins spa", 0), ("hammam", 0), ("sauna", 0),
    ],

    # ── loisirs.cinéma/sorties (26) — ponctuel ──────────────
    26: [
        ("cinéma", 0), ("ciné", 0), ("film", 0), ("séance", 0),
        ("UGC", 0), ("Pathé", 0), ("Gaumont", 0), ("MK2", 0),
        ("CGR", 0), ("concert", 0), ("spectacle", 0), ("théâtre", 0),
        ("exposition", 0), ("expo", 0), ("musée", 0), ("sortie", 0),
        ("parc d'attractions", 0), ("escape game", 0), ("bowling", 0),
        ("karting", 0), ("laser game", 0), ("paintball", 0),
        ("zoo", 0), ("aquarium", 0), ("opéra", 0), ("cirque", 0),
        ("festival", 0), ("place de concert", 0), ("billet spectacle", 0),
        ("Kino", 0), ("cinema", 0), ("cine", 0), ("movie", 0),
        ("entrée musée", 0), ("visite guidée", 0),
        ("soirée dansante", 0), ("discothèque", 0), ("boîte de nuit", 0),
        ("parc aquatique", 0), ("accrobranche", 0), ("mini golf", 0),
    ],

    # ── loisirs.jeux vidéo (27) — MIXED ─────────────────────
    27: [
        ("jeu vidéo", 0), ("jeux vidéo", 0), ("jeu PS5", 0),
        ("jeu Switch", 0), ("jeu PC", 0), ("achat Steam", 0),
        ("jeu Xbox", 0), ("game", 0), ("DLC", 0), ("skin", 0),
        ("V-Bucks", 0), ("jeu Nintendo", 0), ("jeu mobile", 0),
        ("carte PSN", 0), ("carte Xbox", 0), ("carte Nintendo", 0),
        ("Videospiel", 0), ("videojuego", 0), ("video game", 0),
        ("micro-transaction", 0), ("battle pass", 0),
        ("PlayStation Plus", 1), ("PS Plus", 1),
        ("Xbox Game Pass", 1), ("Nintendo Online", 1),
        ("abonnement gaming", 1), ("EA Play", 1),
        ("Game Pass", 1), ("PS Now", 1), ("Ubisoft+", 1),
    ],

    # ── loisirs.sport (28) — MIXED ──────────────────────────
    28: [
        ("match", 0), ("séance sport", 0), ("entrée piscine", 0),
        ("cours de yoga", 0), ("session escalade", 0),
        ("foot entre potes", 0), ("tennis", 0), ("badminton", 0),
        ("padel", 0), ("squash", 0), ("ping-pong", 0),
        ("course à pied", 0), ("marathon", 0), ("randonnée", 0),
        ("plongée", 0), ("ski", 0), ("forfait ski", 0),
        ("patinoire", 0), ("surf", 0), ("escalade", 0),
        ("Sportkurs", 0), ("deporte", 0), ("sports", 0),
        ("abonnement salle", 1), ("salle de sport", 1),
        ("fitness", 1), ("basic fit", 1), ("abonnement gym", 1),
        ("cotisation club", 1), ("licence sportive", 1),
        ("keep cool", 1), ("neoness", 1), ("CMG", 1),
        ("abonnement piscine", 1), ("club de sport", 1),
        ("crossfit box", 1), ("Fitnessstudio", 1),
        ("gym membership", 1), ("cuota gimnasio", 1),
    ],

    # ── loisirs.manga/livres (29) — ponctuel ────────────────
    29: [
        ("manga", 0), ("livre", 0), ("BD", 0), ("bande dessinée", 0),
        ("roman", 0), ("bouquin", 0), ("comics", 0), ("Fnac", 0),
        ("Amazon livre", 0), ("Cultura", 0), ("Gibert", 0),
        ("librairie", 0), ("poche", 0), ("tome", 0),
        ("light novel", 0), ("artbook", 0), ("guide", 0),
        ("essai", 0), ("polar", 0), ("SF", 0), ("fantasy", 0),
        ("Buch", 0), ("book", 0), ("libro", 0),
        ("ebook", 0), ("kindle", 0), ("kobo", 0),
        ("manga shonen", 0), ("manga seinen", 0), ("webtoon", 0),
        ("album BD", 0), ("coffret manga", 0),
    ],

    # ── loisirs.streaming (30) — fixe ───────────────────────
    30: [
        ("Netflix", 1), ("netflix", 1), ("Disney+", 1),
        ("Disney Plus", 1), ("disney plus", 1),
        ("Amazon Prime", 1), ("Prime Video", 1), ("prime video", 1),
        ("OCS", 1), ("Apple TV", 1), ("apple tv+", 1),
        ("Paramount+", 1), ("Crunchyroll", 1), ("ADN", 1),
        ("Hulu", 1), ("HBO", 1), ("HBO Max", 1), ("Canal+", 1),
        ("canal+", 1), ("canal plus", 1), ("mycanal", 1),
        ("abonnement streaming", 1), ("VOD", 1), ("streaming", 1),
        ("plateforme vidéo", 1), ("Streaming", 1),
        ("abonnement netflix", 1), ("abonnement disney", 1),
        ("abonnement prime", 1), ("abo streaming", 1),
        ("molotov", 1), ("salto", 1), ("Wakanim", 1),
    ],

    # ── loisirs.musique (31) — fixe ─────────────────────────
    31: [
        ("Spotify", 1), ("spotify", 1), ("Deezer", 1), ("deezer", 1),
        ("Apple Music", 1), ("apple music", 1),
        ("YouTube Music", 1), ("youtube music", 1),
        ("Tidal", 1), ("SoundCloud", 1), ("Amazon Music", 1),
        ("abonnement musique", 1), ("musique en ligne", 1),
        ("streaming musique", 1), ("abo musique", 1),
        ("Napster", 1), ("Qobuz", 1), ("abonnement spotify", 1),
        ("abonnement deezer", 1), ("abo deezer", 1), ("abo spotify", 1),
        ("premium musique", 1), ("Musik Abo", 1),
        ("suscripción música", 1), ("music subscription", 1),
    ],

    # ── shopping.vêtements (32) — ponctuel ──────────────────
    32: [
        ("zara", 0), ("H&M", 0), ("h&m", 0), ("uniqlo", 0),
        ("primark", 0), ("kiabi", 0), ("decathlon", 0), ("nike", 0),
        ("adidas", 0), ("celio", 0), ("jules", 0), ("mango", 0),
        ("pull & bear", 0), ("bershka", 0), ("ASOS", 0),
        ("vêtements", 0), ("fringues", 0), ("habits", 0),
        ("t-shirt", 0), ("jean", 0), ("pantalon", 0),
        ("chaussures", 0), ("baskets", 0), ("sneakers", 0),
        ("veste", 0), ("manteau", 0), ("robe", 0), ("chemise", 0),
        ("Kleidung", 0), ("clothes", 0), ("ropa", 0),
        ("puma", 0), ("new balance", 0), ("levi's", 0),
        ("sandro", 0), ("maje", 0), ("lacoste", 0), ("ralph lauren", 0),
        ("chaussettes", 0), ("sous-vêtements", 0), ("pull", 0),
        ("sweat", 0), ("blouson", 0), ("écharpe", 0), ("bonnet", 0),
    ],

    # ── shopping.électronique (33) — ponctuel ───────────────
    33: [
        ("Apple", 0), ("Samsung", 0), ("Sony", 0), ("Fnac", 0),
        ("Darty", 0), ("Boulanger", 0), ("LDLC", 0),
        ("smartphone", 0), ("téléphone neuf", 0), ("ordinateur", 0),
        ("pc portable", 0), ("laptop", 0), ("tablette", 0),
        ("casque", 0), ("écouteurs", 0), ("câble", 0),
        ("chargeur", 0), ("accessoire tech", 0), ("clavier", 0),
        ("souris", 0), ("écran", 0), ("moniteur", 0),
        ("Elektronik", 0), ("electrónica", 0), ("electronics", 0),
        ("disque dur", 0), ("SSD", 0), ("clé USB", 0),
        ("imprimante", 0), ("cartouche", 0), ("AirPods", 0),
        ("iPad", 0), ("MacBook", 0), ("iPhone", 0), ("Galaxy", 0),
        ("console", 0), ("PS5", 0), ("Switch", 0), ("Xbox", 0),
        ("enceinte", 0), ("caméra", 0), ("drone", 0),
    ],

    # ── shopping.mobilier/déco (34) — ponctuel ──────────────
    34: [
        ("IKEA", 0), ("ikea", 0), ("Maisons du Monde", 0),
        ("Conforama", 0), ("But", 0), ("Leroy Merlin", 0),
        ("Castorama", 0), ("Action", 0), ("Gifi", 0),
        ("Fly", 0), ("Alinéa", 0), ("meuble", 0), ("mobilier", 0),
        ("déco", 0), ("décoration", 0), ("lampe", 0), ("coussin", 0),
        ("tapis", 0), ("étagère", 0), ("cadre", 0), ("bougie", 0),
        ("Möbel", 0), ("muebles", 0), ("furniture", 0),
        ("canapé", 0), ("lit", 0), ("matelas", 0), ("table", 0),
        ("chaise", 0), ("bureau", 0), ("armoire", 0), ("commode", 0),
        ("rideau", 0), ("miroir", 0), ("vaisselle", 0),
        ("poêle", 0), ("casserole", 0), ("draps", 0), ("oreiller", 0),
        ("rangement", 0), ("brico", 0), ("bricolage", 0),
    ],

    # ── finance_taxes.retrait DAB (35) — ponctuel ───────────
    35: [
        ("retrait", 0), ("DAB", 0), ("distributeur", 0),
        ("retrait espèces", 0), ("cash", 0), ("liquide", 0),
        ("retrait banque", 0), ("retrait carte", 0),
        ("Geldautomat", 0), ("cajero", 0), ("ATM", 0),
        ("retrait DAB", 0), ("retrait au distributeur", 0),
        ("retirer de l'argent", 0), ("billets", 0),
        ("retrait guichet", 0), ("cash withdrawal", 0),
        ("Abhebung", 0), ("espèces", 0), ("retrait automatique", 0),
    ],

    # ── finance_taxes.frais bancaires (36) — fixe ───────────
    36: [
        ("frais bancaires", 1), ("frais de compte", 1),
        ("cotisation carte", 1), ("carte bancaire", 1),
        ("tenue de compte", 1), ("frais CB", 1),
        ("commission bancaire", 1), ("agios", 1),
        ("frais de tenue", 1), ("carte visa", 1),
        ("carte mastercard", 1), ("carte gold", 1),
        ("Bankgebühren", 1), ("bank fees", 1), ("comisiones bancarias", 1),
        ("frais annuels carte", 1), ("cotisation annuelle carte", 1),
        ("frais de gestion", 1), ("commission de mouvement", 1),
        ("frais d'intervention", 1), ("commission carte", 1),
    ],

    # ── finance_taxes.impôts/taxes (37) — fixe ──────────────
    37: [
        ("impôts", 1), ("taxes", 1), ("impôt sur le revenu", 1),
        ("taxe foncière", 1), ("taxe d'habitation", 1),
        ("prélèvement fiscal", 1), ("URSSAF", 1), ("CFE", 1),
        ("TVA", 1), ("cotisations sociales", 1),
        ("Steuern", 1), ("impuestos", 1), ("taxes", 1),
        ("prélèvement à la source", 1), ("impôt mensuel", 1),
        ("contribution sociale", 1), ("CSG", 1), ("CRDS", 1),
        ("taxe professionnelle", 1), ("taxe ordures ménagères", 1),
        ("impôt foncier", 1), ("déclaration impôts", 1),
    ],

    # ── finance_taxes.amendes (38) — ponctuel ───────────────
    38: [
        ("amende", 0), ("contravention", 0), ("PV", 0),
        ("procès-verbal", 0), ("amende stationnement", 0),
        ("radar", 0), ("excès de vitesse", 0), ("infraction", 0),
        ("amende RATP", 0), ("amende SNCF", 0), ("amende bus", 0),
        ("Bußgeld", 0), ("multa", 0), ("fine", 0),
        ("PV parking", 0), ("flash radar", 0), ("verbalisation", 0),
        ("FPS", 0), ("forfait post-stationnement", 0),
        ("amende routière", 0), ("pénalité", 0), ("majoration", 0),
    ],

    # ── education.scolarité (39) — fixe ─────────────────────
    39: [
        ("scolarité", 1), ("frais de scolarité", 1),
        ("inscription", 1), ("université", 1), ("école", 1),
        ("fac", 1), ("CVEC", 1), ("droits d'inscription", 1),
        ("frais d'inscription", 1), ("tuition", 1),
        ("Studiengebühren", 1), ("matrícula", 1),
        ("inscription école", 1), ("frais scolaires", 1),
        ("inscription fac", 1), ("droits universitaires", 1),
        ("frais campus", 1), ("scolarité annuelle", 1),
        ("inscription concours", 1), ("Crous", 1),
        ("contribution étudiante", 1), ("inscription master", 1),
    ],

    # ── education.fournitures (40) — ponctuel ───────────────
    40: [
        ("fournitures", 0), ("cahier", 0), ("stylo", 0),
        ("trousse", 0), ("cartable", 0), ("classeur", 0),
        ("feuilles", 0), ("papeterie", 0), ("copies", 0),
        ("Schulbedarf", 0), ("material escolar", 0),
        ("school supplies", 0), ("rentrée scolaire", 0),
        ("crayons", 0), ("gomme", 0), ("règle", 0), ("compas", 0),
        ("feutres", 0), ("colle", 0), ("ciseaux scolaires", 0),
        ("sac à dos", 0), ("agenda", 0), ("calculatrice", 0),
        ("protège-cahier", 0), ("surligneur", 0),
    ],

    # ── education.formation (41) — MIXED ────────────────────
    41: [
        ("formation", 0), ("cours en ligne", 0), ("workshop", 0),
        ("séminaire", 0), ("conférence", 0), ("masterclass", 0),
        ("stage", 0), ("bootcamp", 0), ("MOOC", 0),
        ("tuto payant", 0), ("certification", 0), ("examen", 0),
        ("Fortbildung", 0), ("formación", 0), ("training", 0),
        ("CPF", 0), ("formation pro", 0), ("cours du soir", 0),
        ("abonnement Udemy", 1), ("abonnement Coursera", 1),
        ("abonnement LinkedIn Learning", 1),
        ("abonnement Skillshare", 1), ("abonnement formation", 1),
        ("abonnement OpenClassrooms", 1), ("abo formation", 1),
    ],

    # ── divers.cadeau offert (42) — ponctuel ────────────────
    42: [
        ("cadeau", 0), ("cadeau anniversaire", 0), ("cadeau noël", 0),
        ("gift", 0), ("Geschenk", 0), ("regalo", 0),
        ("fleurs", 0), ("bouquet", 0), ("present", 0),
        ("cadeau mariage", 0), ("cadeau naissance", 0),
        ("cadeau départ", 0), ("carte cadeau", 0),
        ("cadeau crémaillère", 0), ("cadeau fête des mères", 0),
        ("cadeau fête des pères", 0), ("cadeau Saint-Valentin", 0),
        ("bon cadeau", 0), ("liste de mariage", 0),
        ("cadeau collègue", 0), ("cadeau ami", 0),
        ("surprise", 0), ("cadeau pour", 0), ("offert à", 0),
        ("idée cadeau", 0), ("emballage cadeau", 0),
    ],

    # ── divers.vétérinaire/animaux (43) — ponctuel ──────────
    43: [
        ("vétérinaire", 0), ("véto", 0), ("croquettes", 0),
        ("nourriture animal", 0), ("litière", 0), ("toilettage", 0),
        ("animalerie", 0), ("vaccin animal", 0), ("vaccin chat", 0),
        ("vaccin chien", 0), ("vermifuge", 0), ("anti-puces", 0),
        ("collier chien", 0), ("jouet chat", 0), ("gamelle", 0),
        ("Tierarzt", 0), ("veterinario", 0), ("vet", 0),
        ("nourriture chat", 0), ("nourriture chien", 0),
        ("pâtée", 0), ("laisse", 0), ("harnais", 0),
        ("jardiland animaux", 0), ("truffaut animaux", 0),
        ("maxizoo", 0), ("visite véto", 0), ("consultation véto", 0),
    ],

    # ── divers.tabac/jeux d'argent (44) — ponctuel ──────────
    44: [
        ("tabac", 0), ("cigarettes", 0), ("clopes", 0),
        ("tabac presse", 0), ("loto", 0), ("euromillions", 0),
        ("PMU", 0), ("paris sportifs", 0), ("jeux d'argent", 0),
        ("FDJ", 0), ("grattage", 0), ("buraliste", 0),
        ("Tabak", 0), ("tabaco", 0), ("tobacco", 0),
        ("ticket à gratter", 0), ("pari hippique", 0),
        ("betclic", 0), ("winamax", 0), ("unibet", 0),
        ("parions sport", 0), ("loto foot", 0),
        ("carte à gratter", 0), ("jackpot", 0), ("tirage", 0),
        ("vape", 0), ("e-liquide", 0), ("cigarette électronique", 0),
    ],

    # ── divers.autre (45) — ponctuel ────────────────────────
    45: [
        ("divers", 0), ("autre", 0), ("frais divers", 0),
        ("dépense diverse", 0), ("achat divers", 0),
        ("miscellaneous", 0), ("Sonstiges", 0), ("otros", 0),
        ("frais", 0), ("dépense", 0), ("achat", 0),
        ("commission", 0), ("frais annexes", 0), ("extra", 0),
        ("imprévu", 0), ("dépense imprévue", 0), ("pourboire", 0),
        ("tip", 0), ("Trinkgeld", 0), ("propina", 0),
        ("consigne", 0), ("timbre", 0), ("photocopie", 0),
        ("pressing", 0), ("laverie", 0), ("serrurier", 0),
        ("plombier", 0), ("électricien", 0), ("déménagement", 0),
    ],

    # ═══ INCOME ═══════════════════════════════════════════════

    # ── salaire.salaire net (46) — fixe ─────────────────────
    46: [
        ("salaire", 1), ("paye", 1), ("paie", 1),
        ("fiche de paie", 1), ("virement salaire", 1),
        ("salaire mensuel", 1), ("salaire du mois", 1),
        ("salaire net", 1), ("net à payer", 1),
        ("Gehalt", 1), ("sueldo", 1), ("nómina", 1),
        ("salary", 1), ("wage", 1), ("pay", 1),
        ("bulletin de salaire", 1), ("rémunération", 1),
        ("salaire janvier", 1), ("salaire février", 1),
        ("salaire mars", 1), ("salaire avril", 1),
        ("salaire mai", 1), ("salaire juin", 1),
        ("paye du mois", 1), ("virement paie", 1),
        ("revenus salariés", 1), ("traitement", 1),
        ("solde du mois", 1), ("Monatslohn", 1),
    ],

    # ── salaire.prime (47) — ponctuel ───────────────────────
    47: [
        ("prime", 0), ("bonus", 0), ("gratification", 0),
        ("prime exceptionnelle", 0), ("13e mois", 0),
        ("prime de fin d'année", 0), ("intéressement", 0),
        ("participation", 0), ("prime vacances", 0),
        ("prime de Noël", 0), ("prime d'activité", 0),
        ("prime transport", 0), ("prime ancienneté", 0),
        ("Bonus", 0), ("prima", 0), ("Prämie", 0),
        ("PPV", 0), ("prime de performance", 0),
        ("prime exceptionnelle pouvoir d'achat", 0),
        ("bonus annuel", 0), ("gratification annuelle", 0),
        ("prime objectif", 0), ("commission commerciale", 0),
    ],

    # ── salaire.revenu freelance (48) — MIXED ───────────────
    48: [
        ("mission freelance", 0), ("facture client", 0),
        ("paiement client", 0), ("projet terminé", 0),
        ("prestation", 0), ("honoraires", 0),
        ("facture envoyée", 0), ("règlement facture", 0),
        ("mission ponctuelle", 0), ("prestation unique", 0),
        ("paiement projet", 0), ("facturation", 0),
        ("Freiberufler", 0), ("autónomo", 0), ("freelance work", 0),
        ("micro-entreprise", 0), ("auto-entrepreneur", 0),
        ("client mensuel", 1), ("contrat freelance", 1),
        ("retainer", 1), ("mission récurrente", 1),
        ("client régulier", 1), ("contrat mensuel", 1),
        ("abonnement client", 1), ("mandat mensuel", 1),
    ],

    # ── transfert.virement reçu (49) — ponctuel ─────────────
    49: [
        ("virement reçu", 0), ("transfert reçu", 0),
        ("virement de", 0), ("paiement reçu", 0),
        ("reçu virement", 0), ("argent reçu", 0),
        ("virement entrant", 0), ("crédit compte", 0),
        ("Überweisung erhalten", 0), ("transferencia recibida", 0),
        ("received transfer", 0), ("wire transfer", 0),
        ("virement bancaire reçu", 0), ("paiement reçu de", 0),
        ("reçu de", 0), ("envoi d'argent reçu", 0),
        ("virement instantané reçu", 0), ("paylib reçu", 0),
        ("lydia reçu", 0), ("revolut reçu", 0),
    ],

    # ── transfert.remboursement santé (50) — ponctuel ───────
    50: [
        ("remboursement sécu", 0), ("remboursement mutuelle", 0),
        ("remboursement santé", 0), ("remboursement médecin", 0),
        ("remboursement pharmacie", 0), ("remboursement cpam", 0),
        ("remboursement ameli", 0), ("CPAM", 0), ("ameli", 0),
        ("Krankenkasse Erstattung", 0), ("reembolso médico", 0),
        ("health reimbursement", 0), ("remboursement soins", 0),
        ("remboursement dentaire", 0), ("remboursement ophtalmo", 0),
        ("remboursement kiné", 0), ("remboursement optique", 0),
        ("remboursement lunettes", 0), ("remboursement prothèse", 0),
        ("retour sécu", 0), ("tiers payant", 0),
    ],

    # ── transfert.remboursement ami (51) — ponctuel ─────────
    51: [
        ("remboursement", 0), ("remboursé par", 0),
        ("rendu par", 0), ("m'a payé", 0),
        ("m'a remboursé", 0), ("remboursement ami", 0),
        ("remboursement pote", 0), ("remboursement coloc", 0),
        ("payé en retour", 0), ("dette remboursée", 0),
        ("Rückzahlung", 0), ("reembolso amigo", 0),
        ("friend reimbursement", 0), ("payback", 0),
        ("Thomas m'a payé", 0), ("Marie m'a remboursé", 0),
        ("retour d'argent", 0), ("splitwise", 0), ("tricount", 0),
        ("lydia reçu ami", 0), ("paypal reçu ami", 0),
        ("partage de frais", 0), ("remboursement resto", 0),
    ],

    # ── exceptionnel.vente occasion (52) — ponctuel ─────────
    52: [
        ("vente", 0), ("vendu", 0), ("vente occasion", 0),
        ("vente vinted", 0), ("vente leboncoin", 0),
        ("vendu sur", 0), ("brocante", 0), ("vide-grenier", 0),
        ("revente", 0), ("vente eBay", 0), ("vente marketplace", 0),
        ("Verkauf", 0), ("venta", 0), ("sold", 0),
        ("vendu téléphone", 0), ("vendu meuble", 0),
        ("vendu vêtements", 0), ("vinted", 0), ("leboncoin", 0),
        ("vente garage", 0), ("cash converter", 0),
        ("revente billet", 0), ("revente console", 0),
        ("vendu voiture", 0), ("vente en ligne", 0),
    ],

    # ── exceptionnel.don reçu (53) — ponctuel ───────────────
    53: [
        ("don reçu", 0), ("cadeau reçu", 0), ("cadeau argent", 0),
        ("argent reçu cadeau", 0), ("enveloppe", 0),
        ("don de", 0), ("héritage", 0), ("donation", 0),
        ("Geschenk erhalten", 0), ("regalo recibido", 0),
        ("gift received", 0), ("don anniversaire", 0),
        ("don noël", 0), ("argent anniversaire", 0),
        ("argent noël", 0), ("argent mariage", 0),
        ("legs", 0), ("don familial", 0),
        ("argent grand-parents", 0), ("enveloppe anniversaire", 0),
        ("cagnotte reçue", 0), ("don parrain", 0),
    ],

    # ── exceptionnel.intérêts (54) — fixe (mostly) ──────────
    54: [
        ("intérêts", 1), ("intérêts livret A", 1),
        ("intérêts compte épargne", 1), ("rendement", 1),
        ("rendement assurance vie", 1), ("dividendes", 1),
        ("coupons", 1), ("Zinsen", 1), ("intereses", 1),
        ("interest", 1), ("intérêts LEP", 1), ("intérêts LDD", 1),
        ("intérêts PEL", 1), ("intérêts livret jeune", 1),
        ("revenus de placement", 1), ("revenus financiers", 1),
        ("plus-value", 0), ("gains boursiers", 0),
        ("bénéfice crypto", 0), ("gain investissement", 0),
        ("rendement annuel", 1), ("intérêts trimestriels", 1),
    ],
}

TIME_SUFFIXES: list[str] = [
    "hier", "ce matin", "ce soir", "lundi", "mardi",
    "mercredi", "jeudi", "vendredi", "samedi", "dimanche",
    "la semaine dernière", "le mois dernier", "aujourd'hui",
    "en janvier", "en février", "en mars", "en avril",
    "en mai", "en juin", "en juillet", "en août",
    "en septembre", "en octobre", "en novembre", "en décembre",
]

EXPENSE_PREFIXES: list[str] = [
    "payé", "acheté", "pris", "réglé", "dépensé pour",
    "payer", "achat", "dépense",
]

INCOME_PREFIXES: list[str] = [
    "reçu", "perçu", "touché", "encaissé", "gagné",
]

CONTEXT_SUFFIXES: list[str] = [
    "avec les amis", "pour moi", "en famille", "pour le boulot",
    "du mois", "du week-end", "de la semaine", "pour la maison",
    "en ligne", "en magasin", "sur place", "à emporter",
]


def make_sample(text: str, type_label: int, cat_label: int, rec_label: int) -> dict:
    return {
        "text": text.strip(),
        "type_label": type_label,
        "category_label": cat_label,
        "recurrence_label": rec_label,
    }


CASUAL_WRAPPERS: list[str] = [
    "j'ai {prefix} {text}",
    "{text} rapide",
    "petit {text}",
    "{text} pas cher",
    "{text} en promo",
    "{text} urgent",
]


def augment(text: str, type_label: int, rec: int, rng: random.Random) -> list[tuple[str, int]]:
    """Generate 6-10 augmented variants per base example."""
    variants: list[tuple[str, int]] = []

    variants.append((text.lower(), rec))

    suffix = rng.choice(TIME_SUFFIXES)
    variants.append((f"{text} {suffix}", rec))

    if type_label == 0:
        prefix = rng.choice(EXPENSE_PREFIXES)
    else:
        prefix = rng.choice(INCOME_PREFIXES)
    variants.append((f"{prefix} {text}", rec))

    suffix2 = rng.choice(TIME_SUFFIXES)
    if type_label == 0:
        prefix2 = rng.choice(EXPENSE_PREFIXES)
    else:
        prefix2 = rng.choice(INCOME_PREFIXES)
    variants.append((f"{prefix2} {text} {suffix2}", rec))

    ctx = rng.choice(CONTEXT_SUFFIXES)
    variants.append((f"{text} {ctx}", rec))

    suffix3 = rng.choice(TIME_SUFFIXES)
    variants.append((f"{text.lower()} {suffix3}", rec))

    ctx2 = rng.choice(CONTEXT_SUFFIXES)
    suffix4 = rng.choice(TIME_SUFFIXES)
    variants.append((f"{text} {ctx2} {suffix4}", rec))

    if type_label == 0 and rng.random() < 0.6:
        wrapper = rng.choice(CASUAL_WRAPPERS)
        pref = rng.choice(EXPENSE_PREFIXES)
        variants.append((wrapper.format(prefix=pref, text=text.lower()), rec))

    if rng.random() < 0.5:
        if type_label == 0:
            prefix3 = rng.choice(EXPENSE_PREFIXES)
        else:
            prefix3 = rng.choice(INCOME_PREFIXES)
        ctx3 = rng.choice(CONTEXT_SUFFIXES)
        variants.append((f"{prefix3} {text.lower()} {ctx3}", rec))

    return variants


def generate(seed: int = SEED) -> tuple[list[dict], list[dict]]:
    rng = random.Random(seed)
    all_samples: list[dict] = []

    for cat_idx, entries in DATA.items():
        type_label = 0 if cat_idx < NUM_EXPENSE else 1

        for text, rec in entries:
            all_samples.append(make_sample(text, type_label, cat_idx, rec))

            for aug_text, aug_rec in augment(text, type_label, rec, rng):
                all_samples.append(make_sample(aug_text, type_label, cat_idx, aug_rec))

    rng.shuffle(all_samples)
    split = int(len(all_samples) * 0.85)
    return all_samples[:split], all_samples[split:]


def save_jsonl(data: list[dict], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        for row in data:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")


def main() -> None:
    train, eval_ = generate()

    save_jsonl(train, DATASET_DIR / "train.jsonl")
    save_jsonl(eval_, DATASET_DIR / "eval.jsonl")

    type_counts = [0, 0]
    rec_counts = [0, 0]
    cat_counts: dict[int, int] = {}
    for s in train:
        type_counts[s["type_label"]] += 1
        rec_counts[s["recurrence_label"]] += 1
        cat_counts[s["category_label"]] = cat_counts.get(s["category_label"], 0) + 1

    print(f"Train: {len(train)}  |  Eval: {len(eval_)}")
    print(f"Type distribution (train): expense={type_counts[0]}, income={type_counts[1]}")
    print(f"Recurrence distribution (train): ponctuel={rec_counts[0]}, fixe={rec_counts[1]}")
    print(f"Categories with fewest samples: {sorted(cat_counts.items(), key=lambda x: x[1])[:5]}")
    print(f"Categories with most samples: {sorted(cat_counts.items(), key=lambda x: x[1], reverse=True)[:5]}")


if __name__ == "__main__":
    main()
