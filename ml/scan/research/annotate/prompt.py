"""Le prompt d'annotation envoyé au modèle.

Il reçoit la photo et les lignes physiques telles que le pipeline les
reconstruit — pas le texte du ticket. C'est délibéré : l'annotation doit
porter sur l'entrée réelle du classifieur, y compris quand le clustering a
fusionné deux lignes du ticket.
"""

from __future__ import annotations

from annotate.schema import ROLE_DESCRIPTIONS

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
{{"lines": [{{"index": 0, "role": "header", "amount": null, "discount": null}}, ...],
  "store": "<enseigne lisible ou null>",
  "date": "<AAAA-MM-JJ ou null>"}}
Une entrée par ligne numérotée, dans l'ordre, sans en omettre aucune."""


def instructions() -> str:
    roles = "\n".join(f"- {role} : {text}" for role, text in ROLE_DESCRIPTIONS.items())
    return INSTRUCTIONS.format(roles=roles)


def numbered_lines(lines) -> str:
    return "\n".join(f"{index}: {line.text}" for index, line in enumerate(lines))
