import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/ui/settings/models/help_topic.dart';

const List<HelpChapter> helpChapters = [
  HelpChapter(
    label: 'Démarrer',
    topics: [
      HelpTopic(
        title: 'Le Reste ce mois',
        summary: 'Le grand chiffre de l\'Accueil',
        icon: Symbols.savings_rounded,
        paragraphs: [
          'C\'est ce qu\'il te reste pour finir le mois : tes revenus du mois, moins tes dépenses, moins les mensualités de tes emprunts.',
          'Il se recalcule à chaque ajout, sans attendre la fin du mois. Touche-le pour ouvrir les Stats et voir d\'où il vient.',
        ],
      ),
      HelpTopic(
        title: 'Ajouter en une phrase',
        summary: 'Écris la dépense, l\'app la range',
        icon: Symbols.bolt_rounded,
        paragraphs: [
          'Dans le champ de l\'Accueil, écris la dépense comme tu la dirais : « courses carrefour 42 », « netflix 15,99 tous les mois », « salaire 2100 ».',
          'Le montant, la catégorie, la date et la récurrence apparaissent au-dessus du champ avant l\'envoi. Tout se corrige d\'un tap, à commencer par la catégorie quand elle est marquée incertaine.',
          'Rien n\'est enregistré tant que tu n\'as pas envoyé.',
          'Si tu préfères les formulaires, coupe « Saisie en langage naturel » dans les réglages : le champ laisse place à un bouton « Ajouter une dépense ».',
        ],
        action: HelpAction(
          label: 'Choisir le moteur d\'analyse',
          destination: HelpDestination.quickAddEngine,
        ),
      ),
      HelpTopic(
        title: 'Scanner un ticket',
        summary: 'Une photo, lue ligne par ligne',
        icon: Symbols.photo_camera_rounded,
        paragraphs: [
          'L\'icône appareil photo, à gauche du champ de saisie. Prends le ticket en photo ou choisis une image déjà dans ta galerie.',
          'L\'app lit l\'enseigne, la date, le total et chaque article, puis te montre sa lecture. Tu changes une catégorie, tu retires une ligne en trop, et tu valides.',
          'Rien n\'entre dans tes comptes avant que tu confirmes.',
        ],
      ),
      HelpTopic(
        title: 'Le journal',
        summary: 'Tes mouvements, jour par jour',
        icon: Symbols.receipt_long_rounded,
        paragraphs: [
          'Sous le chiffre, tes mouvements du plus récent au plus ancien, groupés par journée puis par période.',
          'La barre colorée sous chaque journée montre la répartition par catégorie : d\'un coup d\'œil, tu vois où l\'argent est parti.',
          'Touche une ligne pour l\'ouvrir, la modifier ou la supprimer. Touche le titre d\'une période pour la replier.',
        ],
      ),
    ],
  ),
  HelpChapter(
    label: 'Aller plus loin',
    topics: [
      HelpTopic(
        title: 'Ponctuel, mensuel, annuel',
        summary: 'Ce qui revient tout seul',
        icon: Symbols.event_repeat_rounded,
        paragraphs: [
          'Une dépense est ponctuelle par défaut. Passe-la en mensuel ou en annuel et elle se reporte d\'elle-même sur les mois suivants : loyer, abonnements, assurances.',
          'Une dépense récurrente n\'est jamais à ressaisir. Elle pèse sur le Reste de chaque mois tant que tu ne l\'arrêtes pas.',
        ],
      ),
      HelpTopic(
        title: 'Modifier ou arrêter une récurrence',
        summary: 'À partir de quel mois ?',
        icon: Symbols.edit_calendar_rounded,
        paragraphs: [
          'Changer le montant d\'une dépense récurrente pose une question : « Appliquer dès ce mois-ci ». Active-la si la hausse est déjà passée, laisse-la éteinte si elle prend effet le mois prochain.',
          'Même logique à la suppression, avec « Retirer aussi le mois en cours ». Éteint, le mois en cours garde son échéance et la règle s\'arrête après. Allumé, le mois en cours la perd aussi.',
          'Les mois déjà passés ne bougent jamais.',
        ],
      ),
      HelpTopic(
        title: 'Comptes et virements',
        summary: 'Plusieurs comptes, l\'argent qui circule',
        icon: Symbols.account_balance_rounded,
        paragraphs: [
          'L\'onglet Comptes liste tes comptes et le solde de chacun pour le mois affiché. Ouvre-en un pour voir sa composition : revenus, dépenses, mensualités, virements.',
          'Un virement déplace de l\'argent d\'un compte vers un autre sans compter comme une dépense. Il s\'ajoute depuis la fiche d\'un compte et peut être ponctuel ou mensuel, comme le reste.',
        ],
      ),
      HelpTopic(
        title: 'Emprunts',
        summary: 'Mensualités, intérêts, anticipé',
        icon: Symbols.account_balance_wallet_rounded,
        paragraphs: [
          'Troisième onglet de Transactions. Saisis le capital, la durée, le taux et l\'assurance : l\'app construit le tableau d\'amortissement, calcule la mensualité et suit le capital restant dû.',
          'La mensualité est retirée du Reste ce mois automatiquement, sans dépense à créer à côté.',
          'Un remboursement anticipé se déclare depuis la fiche du prêt. L\'échéancier et le coût total sont recalculés, indemnités comprises.',
        ],
      ),
      HelpTopic(
        title: 'Stats',
        summary: 'Ce que ton budget fait sur la durée',
        icon: Symbols.bar_chart_rounded,
        paragraphs: [
          'Les Stats partent toujours du mois en cours et remontent le temps. Le sélecteur en haut choisit jusqu\'où : 6 ou 12 mois. Elles ne suivent pas le mois affiché dans Transactions et Comptes.',
          'Flux mensuels : ce qui est entré et ce qui est sorti chaque mois, et ce que tu mets de côté en moyenne sur la période. Touche un mois pour ouvrir ses dépenses.',
          'Part incompressible : la part de tes revenus déjà engagée par tes charges qui reviennent, et ce qu\'il te reste à vivre une fois qu\'elles sont payées.',
          'Ce qui a bougé : les postes qui montent ou qui baissent, comparés à la période précédente de même durée.',
          'Répartition : où part l\'argent ce mois-ci. Touche une catégorie pour n\'afficher que ses dépenses dans l\'onglet Transactions.',
        ],
      ),
      HelpTopic(
        title: 'Retrouver une ligne',
        summary: 'Recherche, filtres, tri',
        icon: Symbols.filter_list_rounded,
        paragraphs: [
          'Dans Transactions, la recherche retrouve une ligne par son nom.',
          'Les filtres la restreignent par type, catégorie, montant, compte ou bénéficiaire. Les pastilles sous la barre rappellent ce qui est actif ; touche-les pour l\'enlever.',
          'Les dépenses se groupent par jour ou par semaine et se trient par date, par montant ou par nom.',
        ],
      ),
    ],
  ),
  HelpChapter(
    label: 'Réglages et confidentialité',
    topics: [
      HelpTopic(
        title: 'Tes données restent chez toi',
        summary: '100 % sur ton téléphone',
        icon: Symbols.lock_rounded,
        paragraphs: [
          'MyBudget ne se connecte à aucune banque et n\'a pas de compte utilisateur. Tout est stocké sur ton téléphone, et le moteur d\'analyse par défaut tourne sur l\'appareil, hors ligne.',
          'La seule exception est le moteur « Clé personnelle » : si tu l\'actives, ta saisie part chez le service dont tu fournis la clé. L\'app te le demande explicitement avant de basculer.',
        ],
      ),
      HelpTopic(
        title: 'Catégories',
        summary: 'Renommer, recolorier, revenir en arrière',
        icon: Symbols.category_rounded,
        paragraphs: [
          'Les catégories sont fournies avec l\'app. Tu peux renommer chacune, changer son icône et sa couleur, ou la remettre telle qu\'elle était.',
          'La couleur choisie se retrouve partout : jauge du journal, répartition des Stats, pastille de chaque ligne.',
        ],
        action: HelpAction(
          label: 'Gérer les catégories',
          destination: HelpDestination.categories,
        ),
      ),
      HelpTopic(
        title: 'Bénéficiaires',
        summary: 'À qui va cette dépense',
        icon: Symbols.people_rounded,
        paragraphs: [
          'Un bénéficiaire marque la personne derrière un mouvement : un prêt à un proche, une part de courses, un remboursement attendu.',
          'Il devient ensuite un filtre et un regroupement dans Transactions.',
        ],
        action: HelpAction(
          label: 'Gérer les bénéficiaires',
          destination: HelpDestination.beneficiaries,
        ),
      ),
      HelpTopic(
        title: 'Sauvegarder et restaurer',
        summary: 'Export, import, suppression',
        icon: Symbols.upload_file_rounded,
        paragraphs: [
          'Comme rien n\'est sur un serveur, l\'export est ta sauvegarde : un fichier contenant tout ton budget, que tu ranges où tu veux.',
          'L\'import te montre ce que le fichier contient avant de remplacer quoi que ce soit.',
          'Les deux sont dans Paramètres, section Données, avec la suppression définitive de tes données.',
        ],
      ),
      HelpTopic(
        title: 'Apparence',
        summary: 'Clair, sombre, ou comme le système',
        icon: Symbols.brightness_6_rounded,
        paragraphs: [
          'Trois réglages : Automatique suit ton téléphone, Clair et Sombre s\'y tiennent quelle que soit l\'heure.',
        ],
        action: HelpAction(
          label: 'Choisir le thème',
          destination: HelpDestination.theme,
        ),
      ),
      HelpTopic(
        title: 'Mises à jour',
        summary: 'Sans passer par un store',
        icon: Symbols.system_update_rounded,
        paragraphs: [
          'L\'app vérifie elle-même s\'il existe une version plus récente et te propose de l\'installer.',
          'Quand une mise à jour est prête, une pastille apparaît sur « Version » dans les Paramètres et les nouveautés sont listées avant l\'installation.',
        ],
        action: HelpAction(
          label: 'Vérifier les mises à jour',
          destination: HelpDestination.update,
        ),
      ),
    ],
  ),
];
