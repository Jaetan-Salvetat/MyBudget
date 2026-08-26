# Corpus annoté du scan — rôles de ligne

Base d'entraînement du futur classifieur de lignes. Elle remplace la
supervision précédente, qui prenait les décisions des règles (`extract()`)
pour vérité et ne pouvait donc rien apprendre qu'elles ne savaient déjà.

## Pourquoi

`line_clf_v3` était entraîné sur T1-train seul (FindIt, Carrefour 2017), avec
les règles comme oracle sur les 77 % de tickets qu'elles validaient. Trois
plafonds : il imitait les règles, ne voyait qu'une enseigne, et n'étiquetait
que les lignes porteuses de prix — donc ne pouvait pas rattacher un libellé
imprimé sur la ligne au-dessus de son prix.

## Comment

```
photo → OCR local (Apple Vision, page remise droite) → lignes physiques
      → annotation par modèle (photo + lignes numérotées) → filtre → corpus
```

Le modèle reçoit la **photo** et les **lignes telles que le pipeline les
reconstruit**, numérotées. Il annote ces lignes-là, pas un ticket idéal :
l'annotation porte sur l'entrée réelle du classifieur, y compris quand le
clustering a fusionné deux lignes du ticket.

## Le filtre

Deux contrôles indépendants, dans `validate.py` :

1. **aucun montant inventé** — chaque montant annoté doit être lisible dans
   les mots de sa ligne, avec le lecteur de prix du pipeline (les prix
   soudés par l'OCR et ceux dont le séparateur manque comptent comme
   lisibles) ;
2. **le ticket porte sa preuve** — Σ(articles − remises) retombe sur le
   total, ou sur le sous-total hors taxe, au demi-centime.

Se tromper de rôle décale la somme : une annotation fausse ne franchit
quasiment jamais le second contrôle.

## Ce que le filtre vaut, mesuré

Sur T1-train, une vérité indépendante existe (golden FindIt). Confrontation
des annotations acceptées, via `annotate.audit` :

| Split | Exactes |
|---|---|
| T1-train | 415/417 (**99,5 %**) |
| T1-test | 414/415 (**99,8 %**) |

Les deux seuls écarts sont des tickets de cantine où « Droit d'entrée +6,64 »
et « Participation −6,64 » sont annotés alors que le golden les ignore :
effet net nul, lecture défendable, pas une hallucination.

## Contenu du corpus

Le corpus est **exclusivement français**, et ne garde que les tickets dont
l'annotation est prouvée par le filtre. Une passe de nettoyage (2026-08-26) a
retiré 166 entrées : les 41 tickets US de `selection_web`, un ticket suisse et
quatre modèles de facture de `mixed`, deux photos qui n'étaient pas des
tickets, et les 118 annotations qu'aucun checksum ne validait — ni total, ni
article, ni somme retombant sur la référence. Ces dernières n'apprenaient
rien : le filtre les écartait déjà au chargement. Le seul ticket FR de
`selection_web` (Wikimedia, crêperie La Rochelle) a rejoint `mixed`.

| Corpus | Retenus | Nature |
|---|---|---|
| FindIt T1-train | 472/500 | scans à plat, OCR fiable |
| FindIt T1-test | 471/500 | idem, réservé à l'évaluation |
| synthetic | 102/121 | tickets générés |
| FindIt T2-train | 79/100 | scans à plat, second lot |
| photos_pixel | 50/71 | photos téléphone, papier froissé |
| mixed | 3/12 | tickets web |

Les `Retenus` incluent les tickets écartés pour un montant illisible sur sa
ligne : le checksum protège les montants, pas l'étiquetage, et leurs rôles
restent exploitables pour le tagger (`load(roles_only=True)`).

Les rejets des photos réelles ne sont pas des erreurs d'annotation : l'OCR
lit `1,05` là où le ticket imprime `1,85`, ou ne lit rien. Ces tickets sont
inexploitables pour une supervision par checksum — c'est un **biais de
sélection assumé**, et la raison pour laquelle `photos_pixel` sert de jeu
d'évaluation, jamais d'entraînement.

## Le corpus

**586 tickets d'entraînement, 13 444 lignes** — T1-train 417, synthetic 97,
T2-train 69, mixed 3. **435 tickets d'évaluation, 10 448 lignes** —
T1-test 415, photos_pixel 20. Avec `roles_only`, l'entraînement monte à
**656 tickets, 15 592 lignes**.

Répartition à l'entraînement : item 3136, header 3047, footer 2938, store 620,
total 591, date_line 576, payment 556, item_label 546, tax 460, noise 341,
discount 186, subtotal 153, change 148, summary 146.

`store`, `date_line` et `item_label` sont les rôles que l'ancien schéma ne
savait pas exprimer, et ils portent les trois postes d'erreur les plus chers.
`discount` reste le plus rare, à surveiller à l'entraînement.

## Ce que le corpus a donné

Le tagger entraîné dessus (`line_classifier/train_roles.py`), sur le jeu
d'évaluation :

| `item` | `total` | `date_line` | `store` | `payment` | `item_label` | `discount` |
|---|---|---|---|---|---|---|
| 98,5 % | 96,4 % | 95,0 % | 93,0 % | 92,1 % | 82,7 % | 76,6 % |

Branché sur l'enseigne, la date et les libellés faibles, il fait passer les
tickets parfaits de 51,0 % à 69,0 % sur T1-test (`bench.vision_local`).

## Séparation

`dataset.load()` rend le jeu d'entraînement, `load(held_out=True)` le jeu
d'évaluation. Sont réservés à l'évaluation, définitivement :

- **`photos_pixel`** — le seul terrain réaliste (téléphone, froissé, penché) ;
- **`T1-test`** — porte une vérité golden indépendante.

## Le schéma

12 rôles (`schema.py`). Seuls `item` et `discount` contribuent à la somme,
`total` et `subtotal` sont les références du checksum ; tout le reste est
explicitement non contributif — c'est ce que le modèle doit apprendre à
écarter, et c'est précisément ce que le schéma à 5 classes ne pouvait pas
exprimer.

Une ligne `item` porte `discount` quand l'OCR a fusionné l'article et sa
remise, et `label_index` quand son libellé est sur une autre ligne.

## Commandes

```bash
OPENROUTER_API_KEY=... uv run python -m annotate.run <dossier>...  # annoter
uv run python -m annotate.revalidate                              # rejouer le filtre
uv run python -m annotate.audit t1train                           # confronter au golden
```

`revalidate` rejoue le filtre sur les annotations déjà obtenues, sans
rappeler le modèle : faire évoluer un garde-fou ne coûte rien.
