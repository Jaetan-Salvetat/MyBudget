"""Commerces locaux : « Boulangerie Martin », « Joe's Barbershop ».

Ce que l'utilisateur tape le plus souvent n'est pas une enseigne nationale mais
le commerce de sa rue. Aucune base ne les liste tous ; en revanche leur nom
suit presque toujours le motif « mot d'activité + nom propre ». Ce module
apprend le motif au modèle plutôt que les noms.
"""

import random
from typing import Iterator

from knowledge.entities import TIER_TAIL, Entity
from taxonomy import ONE_TIME

SOURCE = "patterns"
SEED = 42
VARIANTS_PER_HEAD = 14

FR_SURNAMES = [
    "Martin", "Bernard", "Dubois", "Durand", "Petit", "Moreau", "Lefebvre", "Girard",
    "Roux", "Fournier", "Morel", "Andre", "Mercier", "Blanc", "Guerin", "Boyer",
    "Garnier", "Chevalier", "Francois", "Legrand", "Gauthier", "Perrin", "Robin",
    "Clement", "Morin", "Nicolas", "Henry", "Rousseau", "Vincent", "Muller",
]

FR_PLACES = [
    "du Centre", "de la Gare", "du Marche", "de la Poste", "des Halles", "du Port",
    "de la Mairie", "de l'Eglise", "du Chateau", "de la Plage", "Saint-Michel",
    "Victor Hugo", "Jean Jaures", "de la Republique", "du Vieux Port", "des Lilas",
    "du Moulin", "de la Fontaine", "des Ecoles", "du Pont",
]

EN_SURNAMES = [
    "Smith", "Jones", "Taylor", "Brown", "Wilson", "Evans", "Thomas", "Roberts",
    "Johnson", "Walker", "Wright", "Green", "Hall", "Wood", "Harris", "Clarke",
    "Joe", "Tony", "Sam", "Ellie", "Maggie", "Danny",
]

EN_PLACES = [
    "on the Corner", "High Street", "Station Road", "Market Square", "Church Street",
    "Riverside", "Old Town", "Park Lane", "Kings Road", "Bridge Street",
]

FR_HEADS: dict[str, list[str]] = {
    "alimentation.pain_patisserie": ["Boulangerie", "Patisserie", "Boulangerie-Patisserie"],
    "alimentation.courses": ["Epicerie", "Boucherie", "Charcuterie", "Poissonnerie", "Fromagerie", "Cave", "Primeur", "Superette", "Supermarche", "Marche"],
    "restauration.restaurant": ["Restaurant", "Brasserie", "Bistrot", "Auberge", "Creperie", "Pizzeria", "Chez"],
    "restauration.fast_food": ["Snack", "Kebab", "Friterie", "Food truck", "Tacos"],
    "restauration.bar": ["Bar", "Cafe-bar", "Pub", "Taverne"],
    "restauration.cafe": ["Cafe", "Salon de the", "Torrefaction"],
    "transport.entretien_vehicule": ["Garage", "Carrosserie", "Station de lavage", "Controle technique"],
    "transport.carburant": ["Station", "Station-service"],
    "sante_beaute.coiffeur": ["Salon de coiffure", "Coiffure", "Barbier"],
    "sante_beaute.esthetique": ["Institut de beaute", "Institut", "Spa", "Onglerie"],
    "sante_beaute.pharmacie": ["Pharmacie"],
    "sante_beaute.optique": ["Optique", "Opticien"],
    "sante_beaute.dentaire": ["Cabinet dentaire", "Dentiste", "Orthodontie"],
    "sante_beaute.soins_medicaux": ["Cabinet medical", "Docteur", "Dr", "Laboratoire", "Kinesitherapie", "Osteopathie"],
    "logement.bricolage_jardin": ["Plomberie", "Electricite", "Menuiserie", "Peinture", "Maconnerie", "Jardinerie", "Pepinieres"],
    "logement.services": ["Serrurerie", "Ramonage", "Entretien chaudiere", "Services a domicile"],
    "logement.demenagement": ["Demenagements", "Demenagement", "Garde-meubles"],
    "transport.achat_vehicule": ["Concession", "Automobiles", "Motos", "Cycles"],
    "loisirs.loisirs_creatifs": ["Mercerie", "Atelier creatif", "Loisirs creatifs"],
    "divers.animaux": ["Clinique veterinaire", "Cabinet veterinaire", "Toilettage", "Animalerie"],
    "famille_education.garde_enfant": ["Creche", "Micro-creche", "Halte-garderie"],
    "voyage.sejour": ["Hotel", "Auberge", "Camping", "Gite"],
    "divers.services": ["Pressing", "Laverie", "Cordonnerie", "Retouches", "Cles minute"],
    "divers.autre": ["Photographe"],
    "loisirs.sport": ["Salle de sport", "Club de", "Tennis club", "Dojo"],
    "loisirs.livre_presse": ["Librairie", "Maison de la presse", "Tabac-presse"],
    "shopping.mobilier_deco": ["Ameublement", "Deco"],
}

EN_HEADS: dict[str, list[str]] = {
    "alimentation.pain_patisserie": ["Bakery"],
    "alimentation.courses": ["Butchers", "Grocery", "Deli", "Fishmonger", "Corner Shop"],
    "restauration.restaurant": ["Restaurant", "Kitchen", "Grill", "Pizzeria", "Diner"],
    "restauration.fast_food": ["Takeaway", "Chip Shop", "Burger Bar", "Kebab House"],
    "restauration.bar": ["Pub", "Bar", "Tavern", "Arms"],
    "restauration.cafe": ["Cafe", "Coffee House", "Coffee Shop", "Tea Room"],
    "transport.entretien_vehicule": ["Garage", "Motors", "Auto Repair", "Tyres"],
    "sante_beaute.coiffeur": ["Barbershop", "Hair Salon", "Barbers", "Hairdressers"],
    "sante_beaute.esthetique": ["Beauty Salon", "Nail Bar", "Spa"],
    "sante_beaute.pharmacie": ["Pharmacy", "Chemist"],
    "sante_beaute.optique": ["Opticians"],
    "sante_beaute.dentaire": ["Dental Practice", "Dental Care"],
    "sante_beaute.soins_medicaux": ["Medical Centre", "Surgery", "Clinic"],
    "logement.bricolage_jardin": ["Plumbing", "Electrical", "Builders", "Joinery", "Roofing", "Garden Centre"],
    "logement.demenagement": ["Removals", "Storage"],
    "logement.services": ["Cleaning Services", "Locksmith"],
    "divers.animaux": ["Veterinary Clinic", "Vets", "Pet Grooming", "Pet Shop"],
    "voyage.sejour": ["Hotel", "Inn", "Guest House", "Bed and Breakfast"],
    "divers.services": ["Dry Cleaners", "Launderette", "Shoe Repair"],
    "loisirs.sport": ["Gym", "Fitness Club", "Sports Club"],
    "loisirs.livre_presse": ["Bookshop", "Newsagents"],
}


def _french_variants(head: str, rng: random.Random) -> list[str]:
    if head == "Chez":
        return [f"Chez {rng.choice(FR_SURNAMES)}" for _ in range(VARIANTS_PER_HEAD)]
    out: list[str] = [head]
    for _ in range(VARIANTS_PER_HEAD // 2):
        out.append(f"{head} {rng.choice(FR_SURNAMES)}")
    for _ in range(VARIANTS_PER_HEAD - len(out)):
        out.append(f"{head} {rng.choice(FR_PLACES)}")
    return out


def _english_variants(head: str, rng: random.Random) -> list[str]:
    out: list[str] = [head]
    for _ in range(VARIANTS_PER_HEAD // 2):
        out.append(f"{rng.choice(EN_SURNAMES)}'s {head}")
    for _ in range(VARIANTS_PER_HEAD - len(out)):
        out.append(f"{head} {rng.choice(EN_PLACES)}")
    return out


def iter_entities(seed: int = SEED) -> Iterator[Entity]:
    rng = random.Random(seed)
    for heads, build in ((FR_HEADS, _french_variants), (EN_HEADS, _english_variants)):
        for slug, words in heads.items():
            for head in words:
                for name in dict.fromkeys(build(head, rng)):
                    yield Entity(
                        name=name,
                        slug=slug,
                        source=SOURCE,
                        tier=TIER_TAIL,
                        recurrence=ONE_TIME,
                    )
