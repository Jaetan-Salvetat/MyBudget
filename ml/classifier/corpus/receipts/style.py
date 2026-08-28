"""Transforme un nom de produit en libellé tel qu'une caisse l'imprime.

Observé sur 1 000 tickets FindIt : majuscules sans accent, largeur bornée
(16 à 24 caractères, coupe en plein mot), abréviations de caisse (« PLT »,
« JBN », « 1/2ECR »), contenance collée devant ou derrière (« 4X125G »,
« 75CL »), compteur (« X6 »), marque distributeur (« CRF », « U »), marqueurs
de tête (« * », « 1 », code-barres). Le générateur applique ces déformations
au hasard ; le texte final passe par la même normalisation que l'app.
"""

import random
import re
import unicodedata

from serving.normalize import normalize_receipt_line

ABBREVIATIONS: dict[str, list[str]] = {
    "poulet": ["PLT", "POUL", "POULE"],
    "blanc": ["BLC", "BL"],
    "blanche": ["BLCHE", "BLC"],
    "jambon": ["JBN", "JBON", "JB", "JAMB"],
    "tranches": ["TR", "TRANCH", "T"],
    "tranche": ["TR", "TRANCH"],
    "légumes": ["LEG", "LEGUM", "LEGU"],
    "legumes": ["LEG", "LEGUM"],
    "chocolat": ["CHOC", "CHOCO", "CHOCOL"],
    "noisette": ["NOIS", "NOISET"],
    "noisettes": ["NOIS", "NOISET"],
    "fromage": ["FROM", "FRO", "FROMAG"],
    "saumon": ["SAUM", "SAUMN"],
    "fumé": ["FUM", "FUME"],
    "nature": ["NAT", "NATU", "NATUR"],
    "pomme": ["POM", "POMM"],
    "pommes": ["POM", "POMM"],
    "pommes de terre": ["PDT", "POM.TERRE", "P.DE TERRE"],
    "pomme de terre": ["PDT", "POM.TERRE"],
    "lait": ["LT", "LAIT"],
    "demi-écrémé": ["1/2ECR", "1/2 ECR", "1/2E", "1/2EC"],
    "demi écrémé": ["1/2ECR", "1/2 ECREME"],
    "écrémé": ["ECR", "ECREME", "EC"],
    "entier": ["ENT", "ENTIER"],
    "beurre": ["BEUR", "BEURR", "BR"],
    "crème": ["CREM", "CR", "CRM"],
    "crème fraîche": ["CREM.FRAICH", "CR.FRAICHE", "CRM FRAICH"],
    "sauce": ["SCE", "SAUC"],
    "salade": ["SAL", "SLD", "SLDE", "SALAD"],
    "sandwich": ["SDW", "SAND", "SANDW"],
    "bouteille": ["BTE", "BTL", "BOUT"],
    "boîte": ["BTE", "BOITE"],
    "barquette": ["BQ", "BARQ", "BQT"],
    "sachet": ["SCH", "SACH", "ST"],
    "paquet": ["PQ", "PAQ"],
    "rouleaux": ["RLX", "ROUL"],
    "papier toilette": ["PH", "P.H", "P.HY", "PAP.TOILETTE", "PAP TOIL"],
    "papier hygiénique": ["PH", "P.HYG", "PAP.HYG"],
    "essuie-tout": ["ESS-TT", "ESSUIE TT", "ESS.TOUT"],
    "essuie tout": ["ESS-TT", "ESSUIE TT"],
    "liquide vaisselle": ["LIQ.VSL", "LIQ VAISS", "LIQ.VAISS", "VSL"],
    "vaisselle": ["VSL", "VAISS"],
    "dessert": ["DESS", "DESS."],
    "yaourt": ["YRT", "YAOUR", "YAOU", "YAOURT", "YT"],
    "yaourts": ["YRT", "YAOUR", "YAOURTS"],
    "mousse": ["MOUSS", "MOUS"],
    "biscuit": ["BISC", "BISCUI"],
    "biscuits": ["BISC", "BISCUI"],
    "biscottes": ["BISCOT", "BISCOTT"],
    "confiture": ["CONF", "CONFIT", "CONFITUR"],
    "compote": ["COMP", "COMPOT"],
    "tomate": ["TOM", "TOMAT", "TOMA"],
    "tomates": ["TOM", "TOMAT"],
    "cerise": ["CER", "CERIS"],
    "carotte": ["CAROT", "CAR"],
    "carottes": ["CAROT", "CAR"],
    "champignon": ["CHAMP", "CHAMPI", "CHAMPIG"],
    "champignons": ["CHAMP", "CHAMPI", "CHAMPIG"],
    "haricot": ["HARIC", "HARICO", "HAR"],
    "haricots": ["HARIC", "HARICO", "HAR"],
    "petit": ["PT", "PTIT", "P."],
    "petits": ["PT", "PTITS"],
    "gros": ["GR", "GROS"],
    "moyen": ["MOY", "MOYEN"],
    "extra": ["EXT", "EXTRA"],
    "supérieur": ["SUP", "SUPER"],
    "tradition": ["TRAD", "TRADI"],
    "campagne": ["CAMP", "CAMPAG"],
    "complet": ["CPLT", "COMPL", "CPL"],
    "céréales": ["CEREAL", "CER", "CEREA"],
    "chèvre": ["CHEV", "CHEVR", "CHVRE"],
    "emmental": ["EMM", "EMMENT", "EMMENTA"],
    "râpé": ["RAPE", "RAP"],
    "filet": ["FLT", "FIL", "FILT"],
    "filets": ["FLT", "FIL"],
    "cuisse": ["CUIS", "CUISS"],
    "escalope": ["ESC", "ESCALOP", "ESCAL"],
    "escalopes": ["ESC", "ESCALOP"],
    "dinde": ["DDE", "DINDE"],
    "sans": ["S/", "SS", "S."],
    "avec": ["A/", "AV"],
    "sucre": ["SUCR", "SUC"],
    "pur jus": ["PJ", "P.J.", "PUR JS"],
    "jus": ["JS", "JUS"],
    "orange": ["ORANG", "OR", "ORA"],
    "multifruits": ["MULTIFR", "MLTFRTS", "MULTIFRU"],
    "framboise": ["FRAMB", "FRAMBOIS", "FRAM"],
    "fraise": ["FRSE", "FRAI", "FRAIS"],
    "vanille": ["VANIL", "VANILL", "VAN"],
    "caramel": ["CARA", "CARAM"],
    "citron": ["CIT", "CITR", "CITRO"],
    "poivron": ["PVRON", "POIVR", "POIV"],
    "oignon": ["OIGN", "OIG"],
    "pain de mie": ["PDM", "P.MIE", "PAIN MIE"],
    "brioche": ["BRIOC", "BRIOCH"],
    "croissant": ["CROISS", "CROIS"],
    "madeleine": ["MADEL", "MAD"],
    "cookies": ["COOK", "COOKIE"],
    "bière": ["BIER", "BIERE", "BLE"],
    "rouge": ["RGE", "RG", "ROUG"],
    "rosé": ["ROS", "RSE", "ROSE"],
    "bordeaux": ["BDX", "BORD"],
    "vin de pays": ["VDP"],
    "eau de source": ["EAU SCE", "EAU SOURCE", "EAU SRCE"],
    "minérale": ["MIN", "MINER"],
    "gazeuse": ["GAZ", "GAZEUS"],
    "dentifrice": ["DENT", "DENTIFRI", "DENTIF"],
    "shampooing": ["SHP", "SH", "SHAMP", "SHAMPO"],
    "shampoing": ["SHP", "SH", "SHAMP"],
    "déodorant": ["DEO", "DEOD"],
    "douche": ["DCHE", "DCH", "DOUCH"],
    "gel douche": ["GD", "GEL DCHE", "G.DOUCHE"],
    "savon": ["SAV", "SAVON"],
    "lingettes": ["LING", "LINGET", "LINGETT"],
    "couches": ["CCHE", "COUCH"],
    "mouchoirs": ["MOUCH", "MOUCHOIR"],
    "serviettes": ["SERV", "SERVIET"],
    "lessive": ["LESS", "LESSIV"],
    "adoucissant": ["ADOUC", "ADOUCI"],
    "nettoyant": ["NETT", "NETTOY"],
    "désodorisant": ["DESOD", "DESODO"],
    "éponge": ["EPONG", "EPG"],
    "sacs poubelle": ["SAC POUB", "SACS POUB", "SAC POUBEL"],
    "aluminium": ["ALU", "ALUM"],
    "congélation": ["CONGEL", "CONGELAT"],
    "surgelé": ["SURG", "SURGEL"],
    "végétal": ["VEG", "VEGET"],
    "léger": ["LEG", "LEGER"],
    "matière grasse": ["MG", "M.G."],
    "chaussettes": ["CHAUSS", "CHAUSSET", "SOCQ"],
    "pantalon": ["PANT", "PANTAL"],
    "tee-shirt": ["TS", "T-SHIRT", "TEE"],
    "t-shirt": ["TS", "TEE", "TSHIRT"],
    "chemise": ["CHEM", "CHEMIS"],
    "chaussures": ["CHAUSS", "CHSSRES"],
    "peinture": ["PEINT", "PEINT.", "P."],
    "cartouche": ["CART", "CARTOUCH"],
    "bougie": ["BGIE", "BOUG"],
    "verre": ["VR", "VERRE"],
    "assiette": ["ASS", "ASSIET"],
    "coussin": ["COUSS", "CSSN"],
    "croquettes": ["CROQ", "CROQU"],
    "litière": ["LITIER", "LIT"],
    "cahier": ["CAH", "CAHIER"],
    "enveloppes": ["ENV", "ENVELOP"],
    "cachets": ["CP", "CPR", "COMP"],
    "comprimés": ["CPR", "CP", "COMP"],
    "magazine": ["MAG", "MAGAZ"],
    "menu": ["MENU", "MU", "MN"],
    "formule": ["FORM", "FORMULE"],
    "expresso": ["EXPRESS", "EXP", "EXPRESSO"],
    "café": ["CAFE", "CAF"],
}

BRAND_TOKENS = ["CRF", "U", "AUCHAN", "LP", "NETTO", "BIEN VU", "ECO+", "RDF", "MDD",
                "P.PRIX", "1ER PRIX", "TOP BUDGET", "CASINO", "MONOPRIX", "BIO", "CARF"]
LEADING_MARKERS = ["*", "* ", "1 ", "2 ", "1x ", "H ", "4 ", "6 ", "*1/2 "]
QUANTITY_UNITS = {"g": "G", "gr": "G", "kg": "KG", "l": "L", "cl": "CL", "ml": "ML"}
MIN_WIDTH = 16
MAX_WIDTH = 26
VOWELS = "AEIOUY"

_QUANTITY = re.compile(r"(\d+(?:[.,]\d+)?)\s*(x\s*(\d+(?:[.,]\d+)?)\s*)?(kg|g|gr|cl|ml|l)\b", re.IGNORECASE)
_SPACES = re.compile(r"\s+")


def strip_accents(text: str) -> str:
    decomposed = unicodedata.normalize("NFD", text)
    return "".join(c for c in decomposed if unicodedata.category(c) != "Mn")


def _abbreviate(text: str, rng: random.Random, probability: float) -> str:
    lowered = text.lower()
    for phrase, forms in sorted(ABBREVIATIONS.items(), key=lambda item: -len(item[0])):
        if phrase in lowered and rng.random() < probability:
            pattern = re.compile(r"\b" + re.escape(phrase) + r"\b", re.IGNORECASE)
            text = pattern.sub(rng.choice(forms), text, count=1)
            lowered = text.lower()
    return text


def _drop_vowels(word: str, rng: random.Random) -> str:
    if len(word) < 6:
        return word
    kept = word[0] + "".join(c for c in word[1:] if c not in VOWELS or rng.random() < 0.3)
    return kept if len(kept) >= 3 else word


def _truncate(text: str, rng: random.Random) -> str:
    width = rng.randint(MIN_WIDTH, MAX_WIDTH)
    if len(text) <= width:
        return text
    cut = text[:width]
    if rng.random() < 0.4:
        cut = cut.rsplit(" ", 1)[0]
    return cut.rstrip(" .-/")


def format_quantity(quantity: str | None, rng: random.Random) -> str:
    """« 4 x 125 g » → « 4X125G », « 1 L » → « 1L », « 75 cl » → « 75CL »."""
    if not quantity:
        return ""
    match = _QUANTITY.search(quantity)
    if not match:
        return ""
    amount, _, count, unit = match.groups()
    amount = amount.replace(".", ",") if rng.random() < 0.3 else amount
    token = f"{amount}{QUANTITY_UNITS[unit.lower()]}"
    if count:
        token = f"{amount}X{count}{QUANTITY_UNITS[unit.lower()]}"
    return token


def receipt_line(
    name: str,
    rng: random.Random,
    brand: str | None = None,
    quantity: str | None = None,
    abbreviation_rate: float = 0.5,
) -> str:
    """Un libellé imprimé plausible pour ce produit, déjà normalisé pour le modèle."""
    text = strip_accents(name)
    text = _abbreviate(text, rng, abbreviation_rate).upper()
    text = _SPACES.sub(" ", text).strip()
    if brand and rng.random() < 0.5:
        brand_token = strip_accents(brand).upper().split(",")[0].strip()
        if brand_token and brand_token not in text:
            text = f"{brand_token} {text}" if rng.random() < 0.5 else f"{text} {brand_token}"
    elif rng.random() < 0.15:
        token = rng.choice(BRAND_TOKENS)
        text = f"{text} {token}" if rng.random() < 0.7 else f"{token} {text}"
    if rng.random() < 0.15:
        text = " ".join(_drop_vowels(word, rng) for word in text.split())
    if rng.random() < 0.35:
        text = text.replace(" ", ".", 1) if rng.random() < 0.5 else text.replace(" ", ".")
    text = _truncate(text, rng)
    quantity_token = format_quantity(quantity, rng)
    if quantity_token and rng.random() < 0.7:
        text = f"{quantity_token} {text}" if rng.random() < 0.6 else f"{text} {quantity_token}"
    elif rng.random() < 0.2:
        text = f"{text} X{rng.choice([2, 4, 6, 8, 10, 12])}"
    if rng.random() < 0.4:
        text = rng.choice(LEADING_MARKERS) + text
    return normalize_receipt_line(text)
