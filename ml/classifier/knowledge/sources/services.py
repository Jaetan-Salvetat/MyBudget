"""Services, abonnements et enseignes en ligne des marchés FR / EN.

Le Name Suggestion Index ne connaît que les lieux physiques : il ignore les
abonnements, les opérateurs, les assureurs, les administrations et le commerce
en ligne, qui sont pourtant la moitié de ce qu'un utilisateur tape. Cette liste
comble ce trou. Les alias sont séparés par une barre verticale ; un nom préfixé
par « ~ » est un abonnement, même quand sa classe ne l'est pas en général — une
salle de sport se paie tous les mois, une paire de baskets non.
"""

from typing import Iterator

from knowledge.entities import TIER_HEAD, Entity
from taxonomy import ONE_TIME, RECURRING

SOURCE = "services"

RECURRING_MARK = "~"

RECURRING_SLUGS: frozenset[str] = frozenset(
    {
        "salaire.salaire_net",
        "salaire.retraite",
        "aide_allocation.allocation_familiale",
        "aide_allocation.chomage",
        "aide_allocation.aide_logement",
        "aide_allocation.bourse",
        "exceptionnel.loyer_percu",
        "famille_education.pension_alimentaire",
        "famille_education.cantine",
        "famille_education.garde_enfant",
        "loisirs.streaming",
        "loisirs.musique",
        "numerique.logiciel_service",
        "numerique.ia",
        "numerique.hebergement_domaine",
        "numerique.stockage_cloud",
        "numerique.telecom",
        "logement.loyer",
        "logement.charges",
        "logement.energie",
        "logement.eau",
        "logement.assurance_habitation",
        "transport.assurance_auto",
        "sante_beaute.mutuelle",
        "finance.credit_pret",
        "finance.charges_pro",
    }
)

SERVICES: dict[str, list[str]] = {
    "loisirs.streaming": [
        "Netflix", "Disney+|Disney Plus|disney plus", "Prime Video|Amazon Prime Video",
        "Amazon Prime", "Max|HBO Max", "Apple TV+|Apple TV Plus", "Paramount+|Paramount Plus",
        "Peacock", "Hulu", "Canal+|Canal Plus|myCanal", "OCS", "Crunchyroll", "ADN|Anime Digital Network",
        "Wakanim", "Molotov", "Pluto TV", "Rakuten TV", "BritBox", "Now TV", "Sky Go",
        "Sky", "Discovery+|Discovery Plus", "Universal+", "Arte", "Netflix abonnement", "Twitch",
        "YouTube Premium", "Shadow", "Salto", "Filmo TV", "Tubi", "Starz", "Showtime",
    ],
    "loisirs.musique": [
        "Spotify", "Deezer", "Apple Music", "YouTube Music", "Amazon Music", "Tidal",
        "Qobuz", "SoundCloud", "Bandcamp", "Napster", "Pandora", "Audiomack", "Spotify Premium",
        "Beatport", "Sonos Radio",
    ],
    "loisirs.livre_presse": [
        "Fnac", "Kindle", "~Kindle Unlimited", "~Audible", "Kobo", "~Scribd", "~Storytel", "~Blinkist",
        "Le Monde", "Le Figaro", "Libération", "Mediapart", "L'Équipe", "Les Échos",
        "Le Parisien", "Ouest-France", "Télérama", "Courrier International", "Le Canard enchaîné",
        "The Guardian", "The Times", "The New York Times|NYT", "Financial Times", "The Economist",
        "Washington Post", "Wired", "National Geographic", "Cafeyn", "ePresse", "Substack",
        "Medium", "~Bookbeat", "~abonnement presse",
    ],
    "loisirs.jeux_video": [
        "Steam", "Epic Games|Epic Games Store", "~PlayStation Plus|PS Plus", "PlayStation Store",
        "~Xbox Game Pass|Game Pass", "~Xbox Live", "Nintendo eShop", "~Nintendo Switch Online",
        "Battle.net|Blizzard", "GOG", "~EA Play", "Ubisoft Connect|Uplay", "Riot Games",
        "Roblox", "Fortnite", "League of Legends", "Genshin Impact", "Minecraft", "Valorant",
        "Rocket League", "Humble Bundle", "itch.io", "GeForce Now", "Nvidia GeForce Now",
        "Micromania", "Game", "Steam wallet", "~GeForce Now abonnement",
    ],
    "loisirs.sport": [
        "~Basic-Fit|Basic Fit", "~Fitness Park", "~Neoness", "~Keepcool|Keep Cool", "~L'Orange bleue",
        "~On Air Fitness", "~Vita Liberté", "~Gymlib", "~ClassPass", "~Strava", "~Peloton",
        "~Freeletics", "~PureGym", "~The Gym Group", "~David Lloyd", "~Anytime Fitness",
        "~Planet Fitness", "~Equinox", "~Crunch Fitness", "~abonnement salle de sport",
        "~licence club", "~cotisation club", "Decathlon|Décathlon|Décat|Decat|Decath",
        "Intersport", "Go Sport", "Foot Locker",
    ],
    "loisirs.sorties": [
        "UGC", "Pathé|Pathé Gaumont", "CGR", "Kinepolis", "Mégarama", "MK2",
        "Cineworld", "Odeon", "Vue Cinemas", "AMC", "Regal", "Ticketmaster", "Fnac Spectacles",
        "France Billet", "Dice", "Eventbrite", "Shotgun", "Billetreduc", "See Tickets",
        "Disneyland Paris", "Parc Astérix", "Puy du Fou", "Futuroscope", "Walibi", "Nigloland",
        "GetYourGuide", "Viator", "Tiqets", "Musement", "Klook", "Tripadvisor",
        "Louvre", "Château de Versailles", "Tour Eiffel", "Legoland", "Universal Studios",
        "Alton Towers", "Thorpe Park", "entrée musée", "visite guidée", "excursion",
        "museum ticket", "guided tour", "attraction ticket",
    ],
    "numerique.logiciel_service": [
        "Google", "Microsoft", "Adobe|Adobe Creative Cloud", "Photoshop", "Lightroom", "Microsoft 365|Office 365|Office",
        "Google Workspace|G Suite", "Notion", "Figma", "Canva", "Slack", "Zoom", "Trello",
        "Asana", "Jira", "Atlassian", "Linear", "Miro", "Airtable", "Todoist", "Evernote",
        "1Password", "Dashlane", "Bitwarden", "LastPass", "NordVPN", "ExpressVPN", "Surfshark",
        "ProtonVPN", "Proton|Proton Mail", "Grammarly", "DeepL", "LinkedIn Premium", "Zapier",
        "Shopify", "Squarespace", "Wix", "WordPress", "Mailchimp", "Brevo", "Sendinblue",
        "QuickBooks", "Xero", "Sage", "Pennylane", "Indy", "Freebe", "Salesforce", "HubSpot",
        "Sketch", "Affinity", "JetBrains", "GitHub", "GitLab", "Setapp", "CleanMyMac",
        "Apple One", "Antivirus|Norton|McAfee|Avast|Bitdefender|Kaspersky", "Malwarebytes",
        "TeamViewer", "Dropbox Sign", "DocuSign", "Calendly", "Typeform", "Webflow",
        "Adobe Acrobat", "Autodesk", "AutoCAD", "Ableton", "FL Studio", "Logic Pro", "Final Cut Pro",
        "DaVinci Resolve", "Capcut", "Duolingo", "Babbel",
    ],
    "numerique.ia": [
        "ChatGPT|ChatGPT Plus|OpenAI", "Claude|Claude Pro|Anthropic", "Gemini|Google Gemini",
        "Copilot|GitHub Copilot|Microsoft Copilot", "Midjourney", "Perplexity|Perplexity Pro",
        "Mistral AI|Le Chat", "Cursor", "Runway", "ElevenLabs", "Suno", "Udio", "Stability AI",
        "Leonardo AI", "Hugging Face", "Replicate", "Together AI", "Groq", "DeepSeek",
        "Llama", "Grok", "Notebook LM", "Jasper", "Copy.ai", "Synthesia", "HeyGen",
        "abonnement IA", "crédits API", "API OpenAI", "API Anthropic", "tokens API",
    ],
    "numerique.hebergement_domaine": [
        "OVH|OVHcloud", "Gandi", "Ionos|1&1 Ionos", "Hostinger", "Namecheap", "GoDaddy",
        "Bluehost", "SiteGround", "Hetzner", "Scaleway", "DigitalOcean", "Vultr", "Linode",
        "Netlify", "Vercel", "Render", "Fly.io", "Railway", "Heroku", "Cloudflare",
        "Infomaniak", "o2switch", "PlanetHoster", "LWS", "Amen", "Nom de domaine|nom de domaine",
        "AWS|Amazon Web Services", "Azure|Microsoft Azure", "Google Cloud|GCP", "Supabase",
        "PlanetScale", "MongoDB Atlas", "Firebase", "renouvellement domaine", "certificat SSL",
    ],
    "numerique.stockage_cloud": [
        "Dropbox", "Google One", "Google Drive", "iCloud|iCloud+|iCloud Plus", "OneDrive",
        "Mega", "pCloud", "Box", "Backblaze", "Sync.com", "kDrive", "Proton Drive",
        "Tresorit", "Nextcloud", "Amazon Photos", "Koofr", "stockage cloud", "cloud storage",
    ],
    "numerique.telecom": [
        "Orange", "SFR", "Bouygues Telecom", "Free|Free Mobile", "Sosh", "RED by SFR|RED",
        "B&You|Bouygues B&You", "Prixtel", "NRJ Mobile", "La Poste Mobile", "Lebara",
        "Lycamobile", "Syma", "Coriolis", "Auchan Telecom", "Cdiscount Mobile", "YouPrice",
        "Vodafone", "EE", "O2", "Three", "BT", "Virgin Media", "TalkTalk", "Plusnet",
        "Giffgaff", "Tesco Mobile", "Verizon", "AT&T", "T-Mobile", "Mint Mobile", "Xfinity",
        "Comcast", "Spectrum", "Cox", "Rogers", "Bell", "Telus", "Starlink", "Proximus",
        "Swisscom", "Salt", "Sunrise", "forfait mobile", "box internet", "fibre", "mobile plan",
        "broadband", "phone bill", "facture téléphone",
    ],
    "logement.energie": [
        "EDF", "Engie", "Eni", "Vattenfall", "Ekwateur", "Mint Énergie",
        "Ohm Énergie", "Wekiwi", "Alterna", "Plüm Énergie", "Ilek", "Enercoop", "Alpiq",
        "Enedis", "GRDF", "Octopus Energy", "British Gas", "E.ON", "OVO Energy", "EDF Energy",
        "Scottish Power", "SSE", "Bulb", "Shell Energy", "Utilita", "ConEd", "PG&E",
        "Duke Energy", "National Grid", "facture électricité", "facture gaz", "electricity bill",
        "gas bill", "energy bill",
    ],
    "logement.eau": [
        "Veolia", "Suez", "Saur", "Eau de Paris", "SEDIF", "Thames Water", "Severn Trent",
        "Anglian Water", "United Utilities", "Yorkshire Water", "Southern Water", "Wessex Water",
        "Scottish Water", "facture d'eau", "water bill", "water rates",
    ],
    "logement.charges": [
        "Foncia", "Citya", "Nexity", "Immo de France", "Sergic", "Loiselet & Daigremont",
        "syndic", "charges de copropriété", "appel de fonds", "service charge", "ground rent",
        "council tax", "taxe d'ordures ménagères",
    ],
    "logement.loyer": [
        "Century 21", "Orpi", "Laforêt", "Guy Hoquet", "Stéphane Plaza Immobilier",
        "Foncia location", "Action Logement", "CROUS logement", "Studapart", "Lokaviz",
        "loyer appartement", "loyer studio", "rent", "monthly rent", "quittance de loyer",
    ],
    "finance.frais_bancaires": [
        "Revolut", "N26", "BoursoBank|Boursorama", "Fortuneo", "Hello bank!|Hello bank",
        "Monabanq", "Nickel", "Lydia", "Sumeria", "Wise|TransferWise", "Qonto", "Shine",
        "Bunq", "Monzo", "Starling Bank", "Chime", "Cash App", "Venmo", "PayPal", "SumUp",
        "Curve", "Vivid", "Trade Republic carte", "Western Union", "MoneyGram", "Remitly",
        "frais bancaires", "cotisation carte", "agios", "commission d'intervention",
        "bank fees", "overdraft fee", "account fee", "monthly account fee",
    ],
    "finance.epargne_investissement": [
        "Trade Republic", "Degiro", "eToro", "Robinhood", "Coinbase", "Binance", "Kraken",
        "Bitpanda", "Bitstamp", "Yomoni", "Nalo", "Ramify", "Linxea", "Goodvest", "Cashbee",
        "Vanguard", "BlackRock", "Amundi", "Interactive Brokers", "Saxo", "Freetrade",
        "Livret A", "LDDS", "PEA", "assurance vie", "PER", "plan épargne", "épargne mensuelle",
        "versement PEA", "savings transfer", "investment", "ISA", "pension contribution",
    ],
    "finance.credit_pret": [
        "Cofidis", "Cetelem", "Sofinco", "Younited", "Younited Credit", "Oney", "Klarna",
        "Alma", "Floa", "Franfinance", "Cofinoga", "CAFPI", "Meilleurtaux", "Pretto",
        "mensualité crédit", "remboursement prêt", "crédit conso", "prêt étudiant",
        "prêt immobilier", "échéance prêt", "loan repayment", "mortgage payment", "car loan",
        "student loan",
    ],
    "finance.impots_taxes": [
        "impots.gouv|impots.gouv.fr", "DGFiP", "Trésor Public", "URSSAF", "taxe foncière",
        "taxe d'habitation", "prélèvement à la source", "impôt sur le revenu", "TVA",
        "cotisation foncière", "CFE", "redevance télé", "HMRC", "IRS", "income tax",
        "council tax", "self assessment", "property tax", "sales tax", "national insurance",
    ],
    "finance.amende": [
        "ANTAI", "amendes.gouv|amendes.gouv.fr", "PV stationnement", "contravention",
        "amende SNCF", "amende RATP", "radar", "forfait post-stationnement", "FPS",
        "DVLA fine", "parking fine", "speeding ticket", "penalty charge notice", "late fee",
    ],
    "logement.assurance_habitation": [
        "AXA", "MAIF", "MACIF", "MAAF", "Matmut", "Groupama", "Allianz", "GMF", "Generali",
        "Swiss Life", "Aviva", "MMA", "Pacifica", "Luko", "Lemonade", "Lovys", "Leocare",
        "Direct Assurance", "L'olivier", "Admiral", "Direct Line", "Hiscox", "Homeserve",
        "assurance habitation", "assurance logement", "multirisque habitation",
        "home insurance", "contents insurance", "renters insurance", "assurance appartement",
    ],
    "transport.assurance_auto": [
        "assurance auto", "assurance voiture", "assurance véhicule", "assurance moto",
        "assurance scooter", "carte verte", "AXA auto", "MAIF auto", "MACIF auto",
        "Matmut auto", "Groupama auto", "Allianz auto", "GMF auto", "Direct Assurance auto",
        "L'olivier auto", "car insurance", "motor insurance", "vehicle insurance",
        "assurance tous risques", "assurance au tiers",
    ],
    "sante_beaute.mutuelle": [
        "Harmonie Mutuelle", "MGEN", "Malakoff Humanis", "Alan", "April", "Mutuelle Générale",
        "Apivia", "Aésio", "Mercer", "Henner", "Cegema", "Swiss Life santé", "AXA santé",
        "MAIF santé", "mutuelle", "complémentaire santé", "cotisation mutuelle",
        "health insurance", "dental insurance", "Bupa", "Vitality", "Aetna", "Cigna",
    ],
    "transport.carburant": [
        "Total|TotalEnergies", "Total Access", "Shell", "BP", "Esso", "Esso Express",
        "Avia", "Texaco", "Gulf", "Q8", "Agip", "Intermarché station", "Leclerc station",
        "Carrefour station", "Ionity", "Tesla Supercharger", "Allego", "Fastned",
    ],
    "transport.taxi_vtc": [
        "Uber", "Bolt", "Heetch", "FreeNow", "Marcel", "G7", "Taxis Bleus", "Lyft",
        "Careem", "Ola", "Grab", "Caocao", "Blacklane", "course VTC", "course taxi",
        "ride", "cab", "taxi ride",
    ],
    "transport.transport_commun": [
        "RATP", "Navigo", "Transilien", "Île-de-France Mobilités", "TCL", "TAN", "RTM",
        "Tisséo", "Ilévia", "TBM", "Astuce", "Divia", "STAR", "TAG", "Citura",
        "TfL|Transport for London", "Oyster", "National Rail card", "MTA", "BVG", "Lime",
        "Tier", "Dott", "Voi", "Bird", "Vélib'|Velib", "Bicloo", "V'Lille", "Cityscoot",
        "abonnement transport", "monthly travelcard", "bus pass", "metro card",
    ],
    "transport.peage": [
        "Vinci Autoroutes", "APRR", "Sanef", "Escota", "Cofiroute", "AREA", "Ulys",
        "Bip&Go", "Fulli", "télépéage", "badge télépéage", "Dartford Crossing", "E-ZPass",
        "toll", "road toll", "vignette",
    ],
    "transport.parking": [
        "Indigo", "Effia", "Q-Park", "SAEMES", "Onepark", "Yespark", "Zenpark", "Parkings",
        "PayByPhone", "Flowbird", "JustPark", "SpotHero", "NCP", "horodateur",
        "abonnement parking", "place de parking", "car park", "parking meter",
    ],
    "restauration.livraison": [
        "Uber Eats|UberEats|Uber Eat", "Deliveroo", "Just Eat|JustEat", "Frichti", "Wolt", "Glovo", "Getir",
        "Gorillas", "Flink", "Cajoo", "Grubhub", "DoorDash", "Postmates", "Seamless",
        "Too Good To Go", "Nestor", "Sushi Shop livraison", "commande livraison",
        "food delivery", "takeaway delivery",
    ],
    # Les surnoms que les francais tapent : « macdo » et « carrouf » sont plus
    # frequents que la raison sociale, et aucune source ouverte ne les porte.
    "restauration.fast_food": [
        "McDonald's|McDo|Mcdo|Macdo|Mac Do|Mac Donald", "Burger King|BK",
        "O'Tacos|Otacos|O tacos", "Domino's Pizza|Domino's|Dominos",
        "Five Guys", "Sushi Shop", "Del Arte", "Pizza Hut",
    ],
    "restauration.bar": [
        "Wetherspoons|JD Wetherspoon|Spoons", "The Red Lion", "The Crown", "The King's Arms",
        "The White Hart", "The Royal Oak", "BrewDog", "Au Bureau", "Le Zinc",
    ],
    "restauration.restaurant": [
        "Swile", "Edenred", "Ticket Restaurant", "Sodexo Pass", "Up Déjeuner", "Bimpli",
        "TheFork", "OpenTable", "Michelin", "titre restaurant", "carte resto",
        "restaurant ticket", "meal voucher",
    ],
    "alimentation.courses": [
        "E.Leclerc|Leclerc|Centre E.Leclerc|Leclerc Drive|Hyper Leclerc",
        "Carrefour|Carrouf|Carrefour Hyper|Hyper Carrefour",
        "Monoprix", "Franprix", "Amazon Fresh", "Ocado", "Ocado Retail", "La Ruche qui dit Oui", "HelloFresh",
        "Quitoque", "Jow", "Thrive Market", "Instacart", "Drive Leclerc", "Carrefour Drive",
        "Auchan Drive", "Courses en ligne", "click and collect courses", "online groceries",
    ],
    "shopping.vetements": [
        "Zalando|Zalando commande", "Air Force 1", "Air Jordan", "ASOS", "Shein", "Temu", "Boohoo", "Pretty Little Thing", "Vestiaire",
        "Sarenza", "Spartoo", "La Redoute", "Veepee", "Showroomprivé", "Brandalley",
        "Farfetch", "Zalando Privé", "Nike", "Adidas", "Puma", "New Balance", "Vinted achat",
    ],
    "shopping.electronique": [
        "Amazon", "Apple", "Air Max|Nike Air Max", "Cdiscount", "Rakuten", "Fnac.com", "Back Market", "Materiel.net",
        "Rue du Commerce", "Grosbill", "Top Achat", "Newegg", "Currys", "Apple Store",
        "Samsung", "AliExpress", "Wish", "Banggood", "Ebuyer", "Amazon.fr", "amazon.co.uk",
    ],
    "shopping.mobilier_deco": [
        "Wayfair", "Made.com", "Westwing", "Maisons du Monde", "AM.PM", "Vente-unique",
        "Alinéa", "Habitat", "Etsy", "Temu déco", "Home24", "The Range", "Dunelm",
    ],
    "exceptionnel.vente_occasion": [
        "Leboncoin", "Vinted", "eBay", "Vestiaire Collective", "Depop", "Poshmark",
        "Facebook Marketplace", "Craigslist", "Gumtree", "Momox", "Rakuten occasion",
        "Cash Converters", "Back Market vente", "Recommerce", "Vide dressing",
        "Etsy vente", "Marketplace", "vente en ligne",
    ],
    "sante_beaute.soins_medicaux": [
        "Doctolib", "Maiia", "Qare", "Livi", "Zocdoc", "Babylon", "KRY", "Medadom",
        "consultation en ligne", "téléconsultation", "cabinet médical", "GP appointment",
        "private consultation",
    ],
    "sante_beaute.pharmacie": [
        "Boots pharmacie|Boots the Chemist", "Doctipharma", "1001Pharmacies", "Pharma GDD", "Newpharma", "Doliprane", "Efferalgan",
        "Dafalgan", "Advil", "Nurofen", "Spasfon", "Smecta", "Strepsils", "Voltarène",
        "Imodium", "Gaviscon", "Maalox", "Paracétamol", "Ibuprofène", "Aspirine",
        "paracetamol", "ibuprofen", "prescription", "ordonnance", "vitamine D", "magnésium",
        "Calmosine", "Humex", "Actifed", "Rhinadvil", "Fervex",
    ],
    "sante_beaute.esthetique": [
        "Nail bar", "institut de beauté", "manucure", "épilation", "soin visage", "massage",
        "spa", "beauty salon", "nail salon", "waxing", "Body Minute", "Yves Rocher institut",
        "Esthetic Center", "Guinot institut", "Wecasa beauté", "Treatwell", "Planity",
    ],
    "sante_beaute.cosmetiques": [
        "Nocibé", "Marionnaud", "Yves Rocher", "Kiko|Kiko Milano", "Rituals", "Lush", "The Body Shop",
        "Glossier", "Typology", "Aime", "Sephora", "Douglas", "Beauty Success", "Feelunique",
        "Look Fantastic", "L'Occitane", "Nuxe", "Caudalie", "La Roche-Posay", "Vichy", "Bioderma",
        "Avène", "Clarins", "Lancôme", "Dior parfum", "Chanel parfum", "Guerlain", "Maybelline",
        "L'Oréal Paris", "NYX", "MAC Cosmetics|MAC", "Benefit", "Fenty Beauty", "Charlotte Tilbury",
        "Adopt|Adopt parfums", "Parfumerie", "Nocibé.fr", "Sephora.fr", "Beauté Privée",
    ],
    "sante_beaute.optique": [
        "Krys", "Alain Afflelou|Afflelou", "Optical Center", "Générale d'Optique", "Optic 2000",
        "Atol", "Grand Optical", "Lunettes pour tous", "Jimmy Fairly", "Le Petit Lunetier",
        "Lissac", "Vision Plus", "Ecouter Voir", "Specsavers", "Vision Express", "Boots Opticians",
        "Warby Parker", "Lentilles Moins Chères", "Vision Direct", "Sensee", "Ophtalmic",
        "lentilles de contact", "lunettes de vue", "verres progressifs", "monture",
    ],
    "sante_beaute.dentaire": [
        "Dentego", "Dentexia", "Dentalign", "Dr Smile|DrSmile", "Invisalign", "Alignerz",
        "Bupa Dental", "MyDentist", "cabinet dentaire", "orthodontiste", "détartrage",
        "couronne dentaire", "implant dentaire", "appareil dentaire", "dentiste",
    ],
    "famille_education.formation": [
        "Udemy", "Coursera", "OpenClassrooms", "edX", "Skillshare", "MasterClass",
        "LinkedIn Learning", "Le Wagon", "DataCamp", "Codecademy", "Pluralsight",
        "Rosetta Stone", "Busuu", "Elephorm", "Studi", "CNED", "Cegos", "Docebo",
        "Udacity", "Khan Academy", "formation en ligne", "cours du soir", "online course",
        "bootcamp", "certification", "permis de conduire", "code de la route", "Ornikar",
        "En Voiture Simone", "Lepermislibre",
    ],
    "famille_education.garde_enfant": [
        "Yoopies", "Kinougarde", "Babysits", "Care.com", "Babilou", "People&Baby",
        "La Maison Bleue", "Les Petits Chaperons Rouges", "nounou", "assistante maternelle",
        "crèche", "baby-sitter", "babysitter", "childminder", "nursery", "after school club",
    ],
    "famille_education.cantine": [
        "Sodexo", "Elior", "Compass", "Turboself", "Izly", "Crous",
        "restaurant universitaire|resto u|restau u",
        "cantine scolaire", "self", "school meals", "school dinner money", "lunch card",
    ],
    "famille_education.scolarite": [
        "Sciences Po", "HEC", "Epitech", "Epita", "École 42", "Ionis", "ESSEC", "EDHEC",
        "Sorbonne", "université", "frais de scolarité", "inscription université", "CVEC",
        "tuition fees", "school fees", "enrolment fee", "student registration",
    ],
    "voyage.transport_longue_distance": [
        "SNCF", "SNCF Connect", "TGV", "TGV INOUI", "Ouigo", "Intercités", "Trainline",
        "Eurostar", "Thalys", "Renfe", "Trenitalia", "Deutsche Bahn", "Omio", "Kiwi.com",
        "Skyscanner", "Kayak", "Flixbus", "BlaBlaCar", "BlaBlaCar Bus", "BlaBlaBus",
        "Air France", "Ryanair", "easyJet", "Transavia", "Vueling", "Lufthansa",
        "British Airways", "KLM", "Wizz Air", "Emirates", "Qatar Airways", "Turkish Airlines",
        "Delta", "United Airlines", "American Airlines", "Southwest", "Amtrak",
        "National Express", "Megabus", "Corsair", "French Bee", "Volotea", "billet d'avion",
        "billet de train", "flight ticket", "train ticket",
    ],
    "voyage.sejour": [
        "Booking.com|Booking", "Airbnb", "Hotels.com", "Expedia", "Trivago", "Vrbo",
        "Abritel", "Hostelworld", "Accor", "Ibis", "Novotel", "Mercure", "Sofitel",
        "Pullman", "Marriott", "Hilton", "Best Western", "Premier Inn", "Travelodge",
        "Center Parcs", "Pierre & Vacances", "Belambra", "Club Med", "Huttopia",
        "Camping Sandaya", "Gîtes de France", "Logis Hôtels", "B&B Hôtels", "nuit d'hôtel",
        "hotel night", "hostel", "camping",
    ],
    "voyage.location_vehicule": [
        "Hertz", "Avis", "Europcar", "Sixt", "Enterprise", "Budget", "Rent A Car", "ADA",
        "Ucar", "Getaround", "Turo", "Roadstr", "location voiture", "location utilitaire",
        "car hire", "van rental", "rental car",
    ],
    "divers.tabac_paris": [
        "FDJ|Française des Jeux", "Loto", "EuroMillions", "Amigo", "Keno", "Parions Sport",
        "PMU", "ZEturf", "Betclic", "Winamax", "Unibet", "Bwin", "Bet365", "Ladbrokes",
        "William Hill", "Paddy Power", "Coral", "Zebet", "Vape shop", "e-liquide",
        "cigarettes", "tabac", "clopes", "paquet de clopes", "cigarette pack", "vape juice",
        "lottery ticket", "scratch card", "sports bet",
    ],
    "divers.don": [
        "Croix-Rouge|Croix Rouge française", "Restos du Cœur", "Secours Populaire",
        "Secours Catholique", "UNICEF", "WWF", "Médecins Sans Frontières|MSF",
        "Médecins du Monde", "Greenpeace", "Amnesty International", "Téléthon", "SPA",
        "Fondation Abbé Pierre", "Institut Pasteur", "GoFundMe", "Tipeee", "Patreon",
        "Ko-fi", "Wikipédia don", "Oxfam", "Cancer Research UK", "British Red Cross",
        "don mensuel", "donation", "charity donation", "parrainage",
    ],
    "divers.animaux": [
        "Purina", "Royal Canin", "Whiskas", "Felix", "Pedigree", "Ultima", "Sheba",
        "Hill's", "Virbac", "Zooplus", "Wanimo", "Maxi Zoo", "Jardiland", "Truffaut",
        "Animalis", "Bitiba", "Petco", "PetSmart", "Pets at Home", "assurance animaux",
        "toilettage chien", "pension pour chat", "pet insurance", "vet bill",
    ],
    "divers.services": [
        "La Poste|Colissimo|Chronopost", "Mondial Relay", "Relais Colis", "UPS", "DHL",
        "FedEx", "Point Relais", "5àsec|5 à sec", "Sequoia Pressing", "Mister Minit",
        "Photomaton", "Cordonnerie", "Pressing", "Laverie", "Wash'n Dry", "Speed Queen laverie",
        "Timpson", "Johnsons Cleaners", "Post Office", "Royal Mail", "Evri", "DPD", "Yodel",
    ],
    "divers.autre": [
        "Pompes funèbres", "PFG", "Roc Eclerc", "frais de notaire hors logement",
    ],
    "logement.services": [
        "~O2 Care Services|O2", "~Shiva", "~Wecasa ménage", "Yoojo", "~Helpling", "~Batmaid",
        "~Domicile Clean", "~Axeo Services", "~Centre Services", "~Maison et Services",
        "~Viasanté", "~Chaudière contrat entretien", "Proxiserve", "~Savelys", "~Cham",
        "~Verisure", "~Securitas Home", "~Homiris", "~Nexecur", "Serrurier", "Ramoneur",
        "Dératisation", "Rentokil", "femme de ménage", "aide ménagère", "jardinier", "Molly Maid",
        "Fantastic Services", "TaskRabbit", "Handy", "Lulu dans ma rue",
    ],
    "logement.demenagement": [
        "Demeco", "Les Gentlemen du Déménagement", "Hiflow", "Lugg", "AnyVan", "Demenager Facile",
        "Movinga", "Nextories", "Homebox", "Shurgard", "Annexx", "Une Pièce en Plus", "Costockage",
        "Locabox", "Big Yellow", "Safestore", "frais d'agence", "honoraires de notaire",
        "dépôt de garantie", "état des lieux", "location camion déménagement", "garde-meubles",
    ],
    "transport.achat_vehicule": [
        "Aramisauto", "Autohero", "Spoticar", "La Centrale", "AutoScout24", "Autosphere",
        "Carvana", "Cazoo", "Cinch", "Tesla achat", "Renault concession", "Peugeot concession",
        "Citroën concession", "Dacia concession", "Toyota concession", "Cowboy", "VanMoof",
        "Moustache Bikes", "Angell", "Xiaomi trottinette", "Ninebot", "Decathlon vélo électrique",
        "achat voiture", "achat moto", "achat scooter", "vélo électrique", "trottinette électrique",
        "apport voiture", "reprise véhicule",
    ],
    "loisirs.loisirs_creatifs": [
        "Rougier & Plé|Rougier et Plé", "Cultura loisirs créatifs", "Zôdio", "Mondial Tissus",
        "Toto Tissus", "Bergère de France", "Phildar", "Le Géant des Beaux-Arts", "Boesner",
        "Créa", "Pébéo", "Hobbycraft", "The Works", "Jackson's Art", "Cass Art", "Michaels",
        "Joann", "Etsy fournitures créatives", "Creavea", "Perles & Co", "Rascol", "Tissus.net",
        "Wool and the Gang", "Faber-Castell", "Winsor & Newton", "Copic", "Posca",
    ],
    "finance.charges_pro": [
        "~URSSAF", "~Urssaf auto-entrepreneur", "~CFE", "~Indy", "~Shine", "~Qonto", "~Pennylane",
        "~Freebe", "~Abby", "~Tiime", "Legalstart", "Legalplace", "Captain Contrat",
        "expert-comptable", "cabinet comptable", "~WeWork", "~Wojo", "~Regus", "~Spaces",
        "~Morning coworking", "~Hiscox", "~RC pro", "~Alan pro", "~Swile employeur",
        "cotisations sociales", "SIE impôt société", "TVA à payer", "frais professionnels",
        "~Companies House", "HMRC self assessment", "~Xero", "~FreeAgent",
    ],
    "aide_allocation.aide_sociale": [
        "RSA", "prime d'activité", "AAH", "ASS", "APA", "PCH", "CCAS", "MDPH", "pension d'invalidité",
        "allocation adulte handicapé", "revenu de solidarité active", "aide sociale départementale",
        "Universal Credit", "PIP", "Disability Living Allowance", "Jobseeker's Allowance",
        "aide exceptionnelle CAF", "chèque énergie", "aide alimentaire", "secours du CCAS",
    ],
    "transfert.remboursement_achat": [
        "remboursement Amazon", "remboursement Zalando", "remboursement SNCF", "remboursement Vinted",
        "remboursement Fnac", "remboursement Cdiscount", "remboursement Booking", "remboursement Airbnb",
        "remboursement Ryanair", "remboursement easyJet", "remboursement Uber", "remboursement Deliveroo",
        "avoir", "retour colis remboursé", "commande annulée", "geste commercial", "trop-perçu marchand",
        "PayPal remboursement", "Klarna remboursement", "Alma remboursement",
    ],
    "transfert.pension_alimentaire": [
        "pension alimentaire reçue", "ARIPA", "CAF pension alimentaire", "contribution à l'entretien reçue",
        "pension de l'ex", "pension du père", "pension de la mère", "child maintenance received",
        "CMS payment",
    ],
    "exceptionnel.autre_revenu": [
        "iGraal", "Poulpeo", "Widilo", "Joko", "eBuyClub", "Lydia parrainage", "prime de parrainage",
        "prime de bienvenue Boursorama", "prime Fortuneo", "cashback carte", "gain FDJ", "gain Loto",
        "gain paris sportifs", "Betclic gains", "Winamax retrait", "Quidco", "TopCashback",
        "Nectar points", "gains de jeu", "lot gagné", "prime référendum salarié",
    ],
    "divers.cadeau_offert": [
        "Interflora", "Bergamotte", "Aquarelle", "Wonderbox", "Smartbox", "Vente-privée cadeau",
        "carte cadeau", "chèque cadeau", "bon cadeau", "gift card", "birthday present",
        "cadeau de Noël", "cadeau anniversaire", "wedding gift",
    ],
    "aide_allocation.allocation_familiale": [
        "CAF", "Caisse d'Allocations Familiales", "MSA", "allocations familiales",
        "prime de naissance", "complément familial", "child benefit", "family allowance",
    ],
    "aide_allocation.chomage": [
        "France Travail", "Pôle emploi", "ARE", "allocation chômage", "indemnités chômage",
        "Jobcentre", "Universal Credit", "jobseeker's allowance", "unemployment benefit",
    ],
    "aide_allocation.aide_logement": [
        "APL", "aide au logement", "ALS", "ALF", "CAF logement", "housing benefit",
        "housing allowance", "Action Logement aide",
    ],
    "aide_allocation.bourse": [
        "bourse CROUS", "bourse étudiante", "bourse au mérite", "AGEPI", "student grant",
        "scholarship", "student finance", "maintenance loan",
    ],
    "transfert.remboursement_sante": [
        "Ameli", "CPAM", "Sécurité sociale", "Assurance Maladie", "remboursement mutuelle",
        "remboursement sécu", "tiers payant", "NHS refund", "health insurance refund",
        "medical reimbursement",
    ],
    "transfert.remboursement_impots": [
        "remboursement impôts", "trop-perçu impôts", "crédit d'impôt", "restitution DGFiP",
        "tax refund", "tax rebate", "HMRC refund",
    ],
    "transfert.remboursement_ami": [
        "remboursement Lydia", "remboursement PayPal", "Tricount", "Splitwise",
        "remboursement pote", "remboursement resto", "money back from friend",
        "paid me back", "split bill refund",
    ],
    "salaire.freelance": [
        "Malt", "Comet", "Upwork", "Fiverr", "Freelance.com", "StaffMe", "Crème de la Crème",
        "facture client", "mission freelance", "honoraires", "acompte client",
        "client invoice", "freelance payment", "contract work",
    ],
    "exceptionnel.interets": [
        "intérêts Livret A", "intérêts épargne", "dividendes", "coupons obligations",
        "plus-value", "cashback", "staking rewards", "savings interest", "dividend payment",
        "interest payment",
    ],
    "exceptionnel.loyer_percu": [
        "loyer perçu", "loyer locataire", "revenus locatifs", "Airbnb revenus",
        "rental income", "tenant rent", "letting income",
    ],
    "salaire.retraite": [
        "CNAV", "Agirc-Arrco", "CARSAT", "pension de retraite", "retraite complémentaire",
        "state pension", "pension payment", "retirement income",
    ],
}


def _split(raw: str) -> tuple[str, list[str], bool]:
    recurring = raw.startswith(RECURRING_MARK)
    parts = [part.strip() for part in raw.lstrip(RECURRING_MARK).split("|") if part.strip()]
    return parts[0], parts[1:], recurring


def iter_entities() -> Iterator[Entity]:
    for slug, raw_names in SERVICES.items():
        default = RECURRING if slug in RECURRING_SLUGS else ONE_TIME
        for raw in raw_names:
            name, aliases, forced = _split(raw)
            yield Entity(
                name=name,
                slug=slug,
                source=SOURCE,
                aliases=aliases,
                tier=TIER_HEAD,
                recurrence=RECURRING if forced else default,
            )
