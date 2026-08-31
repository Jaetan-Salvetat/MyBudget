"""Ce qu'un utilisateur décrit sans jamais nommer de marchand.

`lexicon.py` apprend au modèle que des **noms** portent une classe — « courses »,
« baguette », « coiffeur ». Rien ne lui apprenait qu'un **groupe verbal** en
porte une aussi. C'est le trou que `evaluation/hard.py` a rendu visible : l'axe
`phrase_libre` plafonne à 60,5 % quand les autres tiennent 85 à 93 %, et la
moitié de ses cas n'a aucune entité à lire — « il a fallu remplacer le
pare-brise » ne contient ni enseigne ni nom de rayon, seulement une action.

Les clauses sont écrites **déjà conjuguées**, comme la saisie arrive, et non à
l'infinitif : « j'ai fait le plein » et non « faire le plein ». Le générateur ne
leur applique donc que ce qui se colle à une phrase — un repère de temps, un
montant, une queue — jamais les préfixes nominaux ni les enveloppes de
`FRENCH_WRAPPERS`, qui rendraient « petit j'ai fait le plein ».

Une réserve à garder en tête : ces clauses ont été écrites après avoir constaté
l'échec de l'axe `phrase_libre`. Elles ne reprennent aucune de ses phrases —
`test_verb_phrases_never_copy_the_hard_corpus` l'interdit — mais elles visent la
même capacité, et la valeur de cet axe comme mesure aveugle en est réduite
d'autant. Le jour où il se met à progresser franchement, il faudra lui écrire un
lot de phrases neuves pour le vérifier.
"""

VERB_SOURCE = "verbes"

VERB_PHRASES: dict[str, list[str]] = {
    "alimentation.supermarche": [
        "j'ai rempli le frigo", "on a refait les placards", "j'ai pris de quoi tenir la semaine",
        "on a ramené deux sacs pleins", "j'ai racheté du produit ménager",
        "on s'est réapprovisionnés",
    ],
    "alimentation.boulangerie": [
        "je suis passé prendre du pain", "j'ai pris deux baguettes en chemin",
        "on a ramené des viennoiseries", "j'ai commandé la galette",
    ],
    "alimentation.marche": [
        "j'ai fait le tour des étals", "on a pris des légumes chez le producteur",
        "j'ai rempli le panier au marché",
    ],
    "alimentation.epicerie": [
        "je me suis arrêté chez le boucher", "on a pris du fromage à la coupe",
        "j'ai commandé une caisse de vin",
    ],
    "restauration.restaurant": [
        "on a dîné dehors", "on s'est fait un déjeuner à trois",
        "j'ai réglé l'addition pour tout le monde", "on a mangé en terrasse",
        "on a réservé une table pour samedi",
    ],
    "restauration.fast_food": [
        "j'ai avalé un truc rapide entre deux",
        "on a pris à emporter en rentrant", "j'ai mangé debout à midi",
    ],
    "restauration.bar": [
        "on a bu un coup après le travail", "on s'est retrouvés pour l'apéro",
        "j'ai payé la tournée",
    ],
    "restauration.cafe": [
        "je me suis arrêté boire un café", "on a pris un thé en discutant",
    ],
    "restauration.livraison": [
        "on s'est fait livrer ce soir", "j'ai commandé à emporter à la maison",
    ],
    "transport.essence": [
        "j'ai rempli le réservoir à ras bord", "je me suis arrêté à la pompe",
        "j'ai remis du carburant avant l'autoroute",
    ],
    "transport.entretien_vehicule": [
        "j'ai déposé la voiture au garage", "on a fait faire la vidange",
        "il a fallu changer les pneus", "la révision est passée",
    ],
    "transport.transport_commun": [
        "j'ai rechargé ma carte", "j'ai pris un carnet au guichet",
        "j'ai renouvelé mon pass",
    ],
    "transport.taxi_vtc": [
        "j'ai pris une course jusqu'à la gare", "on est rentrés en voiture avec chauffeur",
    ],
    "transport.parking": [
        "je me suis garé en souterrain", "j'ai payé l'horodateur",
    ],
    "transport.peage": [
        "j'ai payé au péage", "on a pris l'autoroute jusqu'en bas",
    ],
    "logement.travaux": [
        "il a fallu réparer la fuite", "on a refait la peinture de la chambre",
        "j'ai appelé quelqu'un pour la chaudière", "on a changé le joint de la douche",
        "j'ai racheté de quoi bricoler",
    ],
    "logement.loyer": [
        "j'ai viré le loyer au propriétaire", "le loyer est parti ce matin",
    ],
    "logement.energie": [
        "la facture d'électricité est tombée", "j'ai réglé le gaz du trimestre",
    ],
    "logement.eau": [
        "j'ai payé la facture d'eau", "le relevé d'eau est arrivé",
    ],
    "logement.charges": [
        "j'ai réglé les charges du trimestre", "l'appel de charges est passé",
    ],
    "sante_beaute.medecin": [
        "je suis allé consulter", "j'ai vu le spécialiste ce matin",
        "j'ai réglé la séance", "j'avais rendez-vous pour un contrôle",
    ],
    "sante_beaute.pharmacie": [
        "je suis passé chercher mon traitement", "j'ai récupéré la boîte à la pharmacie",
    ],
    "sante_beaute.coiffeur": [
        "je me suis fait couper les cheveux", "j'ai pris rendez-vous pour une couleur",
    ],
    "sante_beaute.esthetique": [
        "je me suis fait faire les ongles", "j'ai pris un soin du visage",
    ],
    "loisirs.cinema_sortie": [
        "on est allés voir un film", "j'ai réservé deux places pour le spectacle",
        "on a passé la soirée dehors",
    ],
    "loisirs.sport": [
        "j'ai repris l'entraînement", "j'ai payé mon inscription au club",
        "je me suis équipé pour courir",
    ],
    "loisirs.livre_presse": [
        "je me suis acheté de quoi lire", "j'ai renouvelé mon abonnement au quotidien",
    ],
    "loisirs.jeux_video": [
        "je me suis pris le jeu qui vient de sortir", "j'ai rechargé mon compte de jeu",
    ],
    "loisirs.streaming": [
        "j'ai repris un abonnement pour regarder des séries",
    ],
    "loisirs.musique": [
        "j'ai repris l'abonnement pour écouter de la musique",
    ],
    "shopping.vetements": [
        "je me suis racheté des affaires", "on a habillé les enfants pour la rentrée",
        "j'ai craqué sur une veste", "il me fallait des chaussures neuves",
    ],
    "shopping.electronique": [
        "j'ai remplacé mon téléphone", "il a fallu racheter un chargeur",
        "je me suis équipé d'un nouvel écran",
    ],
    "shopping.mobilier_deco": [
        "on a meublé le salon", "j'ai accroché de quoi décorer l'entrée",
        "on a changé les rideaux",
    ],
    "famille_education.garde_enfant": [
        "on a fait garder les petits", "la nounou est passée cette semaine",
    ],
    "famille_education.activites_enfants": [
        "j'ai inscrit le petit à son activité", "on a payé le stage des vacances",
    ],
    "famille_education.fournitures": [
        "j'ai racheté de quoi écrire", "on a préparé les affaires de classe",
    ],
    "famille_education.formation": [
        "je me suis inscrit à une formation", "j'ai payé le module en ligne",
    ],
    "famille_education.cantine": [
        "j'ai réglé les repas de l'école", "la cantine a été prélevée",
    ],
    "famille_education.scolarite": [
        "j'ai payé les frais d'inscription de l'année",
    ],
    "voyage.hebergement": [
        "on a réservé où dormir", "j'ai payé les nuits sur place",
    ],
    "voyage.transport_longue_distance": [
        "j'ai pris les billets pour descendre", "on a réservé le vol",
    ],
    "voyage.location_vehicule": [
        "on a pris une voiture pour la semaine", "j'ai loué un utilitaire pour déménager",
    ],
    "voyage.activite_visite": [
        "on a payé l'entrée du site", "j'ai réservé la visite guidée",
    ],
    "finance.retrait_dab": [
        "j'ai retiré du liquide", "je suis passé au distributeur",
    ],
    "finance.amende": [
        "j'ai reçu une contravention", "il a fallu payer le procès-verbal",
    ],
    "finance.impots_taxes": [
        "j'ai réglé ce que je devais au fisc", "le prélèvement des impôts est passé",
    ],
    "finance.credit_pret": [
        "l'échéance du prêt est partie", "j'ai remboursé une mensualité",
    ],
    "finance.epargne_investissement": [
        "j'ai mis de côté ce mois-ci", "j'ai alimenté mon épargne",
    ],
    "finance.frais_bancaires": [
        "la banque m'a prélevé ses frais",
    ],
    "divers.animaux": [
        "j'ai emmené le chat se faire soigner", "j'ai racheté à manger pour le chien",
    ],
    "divers.cadeau_offert": [
        "j'ai trouvé quelque chose à offrir", "on a participé au cadeau commun",
    ],
    "divers.tabac_jeux": [
        "je me suis pris un paquet", "j'ai tenté ma chance au tabac",
    ],
    "divers.don": [
        "j'ai fait un don", "j'ai soutenu une association",
    ],
    "salaire.salaire_net": [
        "ma paie est arrivée", "j'ai été payé ce mois-ci",
    ],
    "salaire.prime": [
        "j'ai touché une prime", "le bonus est tombé",
    ],
    "salaire.freelance": [
        "mon client a réglé la facture", "j'ai été payé pour la mission",
    ],
    "transfert.virement_recu": [
        "on m'a envoyé de l'argent", "j'ai reçu un virement de la famille",
    ],
    "transfert.remboursement_ami": [
        "on m'a rendu ce que j'avais avancé", "il m'a remboursé sa part",
    ],
    "transfert.remboursement_sante": [
        "j'ai été remboursé de mes soins", "la complémentaire a versé sa part",
    ],
    "exceptionnel.vente_occasion": [
        "j'ai vendu un truc dont je ne me servais plus", "j'ai revendu du matériel",
    ],
}
