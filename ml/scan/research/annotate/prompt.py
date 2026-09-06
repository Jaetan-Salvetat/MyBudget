"""Le prompt d'annotation envoyé au modèle.

Il reçoit la photo et les lignes physiques telles que le pipeline les
reconstruit — pas le texte du ticket. C'est délibéré : l'annotation doit
porter sur l'entrée réelle du classifieur, y compris quand le clustering a
fusionné deux lignes du ticket.

Ce module porte le contrat dans les deux sens : ce qu'on demande au modèle,
et comment se lit sa réponse. Le modèle répond des entrées *indexées* ;
`positional` vérifie que ces index forment bien une bijection sur les lignes
et rend la séquence dans l'ordre, index retiré. Tout le reste du code ne
connaît que cette forme-là.
"""

from __future__ import annotations

import hashlib

from annotate.schema import ROLE_DESCRIPTIONS

FINGERPRINT_LENGTH = 12

INSTRUCTIONS = """Tu annotes un ticket de caisse pour entraîner un modèle.

On te donne la photo du ticket et les lignes telles qu'un OCR les a
reconstruites, numérotées. Ces lignes peuvent être abîmées, fusionnées ou
mal découpées : tu annotes ce que tu vois dans la liste, pas un ticket idéal.

Pour CHAQUE ligne numérotée, donne son rôle parmi :
{roles}

Pour les lignes dont le rôle porte un montant (item, discount, subtotal,
total, tax, payment, change), donne aussi `amount` : le montant décimal
qui compte sur cette ligne, positif, tel qu'il est IMPRIMÉ sur le ticket.
Pour `discount`, donne la valeur absolue de la remise. N'invente jamais un
montant qui n'est pas sur la ligne — si tu ne le lis pas, mets null.

L'OCR fusionne parfois deux lignes du ticket en une seule : si une ligne
`item` porte AUSSI sa remise (« PAIN 2,50 -0,50 »), donne `discount` sur
cette même ligne, en valeur absolue. Sinon omets le champ.

Si une ligne `item` a son libellé sur une autre ligne, donne `label_index`
: le numéro de cette ligne. Sinon omets le champ.

Pour chaque ligne `item`, donne aussi `name` : les mots qui NOMMENT le
produit, pris sur cette ligne — ou sur la ligne `label_index` quand le
libellé est ailleurs.

RECOPIE-LES EXACTEMENT tels que l'OCR les a rendus, même abîmés
(« 120GENV » reste « 120GENV »). Ne corrige rien, ne complète rien, ne
réordonne rien, ne change pas la casse. Ce sont des mots CONSÉCUTIFS de la
ligne, et rien d'autre : cette valeur sert à retrouver leur position, une
correction la rendrait introuvable. Si aucun mot de la ligne ne nomme le
produit, mets null.

N'appartiennent PAS au nom : le prix, un prix unitaire, une quantité, un
code article ou de rayon (« 583877 », « SANDW 6015 »), une pesée
(« 0,335kg*4,35€/kg »), un code TVA isolé en fin de ligne.

Quand le nombre d'unités est imprimé (« 3 X 1,33 », « 2x », un « 1 » en tête
de ligne), donne-le dans `quantity` — jamais dans `name`. Sinon omets le
champ.

Quand le conditionnement est imprimé (« 250G », « 1L », « 33CL », « 6X100G »,
« 1/2 », « 1KG »), donne-le dans `size` — jamais dans `name`. Le nom est le
produit, son format est un champ : « *230G WASA FIBRES » donne `name`
« WASA FIBRES » et `size` « 230G » ; « BAGUETTE 250G » donne `name`
« BAGUETTE » et `size` « 250G ». Recopie le conditionnement tel qu'il est
imprimé, sans l'astérisque ni le code qui le précède. Sinon omets le champ.

Un POURCENTAGE n'est pas un conditionnement : il décrit le produit et reste
dans le nom (« CHOC NOIR 74% », « EMMENTAL 29% TRANCHES », « CREME 30%MG »).

Règles importantes :
- `store` est la ligne qui porte le NOM de l'enseigne (celui du logo), une
  seule par ticket ; un slogan (« Burger Restaurant »), une adresse ou une
  raison sociale sont des `header`. Si le nom de l'enseigne n'apparaît sur
  aucune ligne, n'annote aucun `store` ;
- `date_line` est la ligne qui porte la date de l'achat, une seule par
  ticket, même si elle porte aussi l'heure ou un numéro de caisse ;
- une ligne « TOTAL REMISE », « Total remise » ou « cumul des avantages »
  est un `summary`, jamais un `total` ;
- le `total` est le montant que le client paie réellement ;
- un article dont le prix est imprimé deux fois (ligne code-barres ET ligne
  libellé) ne compte qu'UNE fois : la ligne qui ne compte pas est `noise` ;
- tout ce qui suit le total et les moyens de paiement est `footer`.

Réponds UNIQUEMENT avec un objet JSON :
{{"lines": [{{"index": 0, "role": "header", "amount": null}},
            {{"index": 4, "role": "item", "amount": 2.5, "name": "PAIN CEREALES",
              "quantity": 1, "size": "400G"}}, ...],
  "store": "<enseigne lisible ou null>",
  "date": "<AAAA-MM-JJ ou null>"}}
Une entrée par ligne numérotée, dans l'ordre, sans en omettre aucune."""


def instructions() -> str:
    roles = "\n".join(f"- {role} : {text}" for role, text in ROLE_DESCRIPTIONS.items())
    return INSTRUCTIONS.format(roles=roles)


def fingerprint() -> str:
    """L'empreinte de ce qu'on demande au modèle. Toucher au prompt la change,
    donc périme les annotations produites par l'ancien."""
    digest = hashlib.sha256(instructions().encode()).hexdigest()
    return digest[:FINGERPRINT_LENGTH]


def positional(annotation: dict, line_count: int) -> list[dict] | None:
    """Les entrées dans l'ordre des lignes, index retiré — ou None si le
    modèle n'a pas rendu une entrée par ligne, exactement une fois."""
    entries = annotation.get("lines")
    if not isinstance(entries, list) or len(entries) != line_count:
        return None
    ordered: list[dict | None] = [None] * line_count
    for entry in entries:
        index = entry.get("index")
        if not isinstance(index, int) or not 0 <= index < line_count:
            return None
        if ordered[index] is not None:
            return None
        ordered[index] = {
            key: value for key, value in entry.items() if key != "index"
        }
    return [entry for entry in ordered if entry is not None]


def numbered_lines(lines) -> str:
    return "\n".join(f"{index}: {line.text}" for index, line in enumerate(lines))
