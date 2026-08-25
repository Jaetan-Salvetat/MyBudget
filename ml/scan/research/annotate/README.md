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
| T1-train | 412/414 (**99,5 %**) |
| T1-test | 413/413 (**100 %**) |

Les deux seuls écarts sont des tickets de cantine où « Droit d'entrée +6,64 »
et « Participation −6,64 » sont annotés alors que le golden les ignore :
effet net nul, lecture défendable, pas une hallucination.

## Taux d'acceptation par corpus

1239 tickets annotés, **968 acceptés (78 %)**.

| Corpus | Acceptés | Nature |
|---|---|---|
| FindIt T1-train | 414/500 (83 %) | scans à plat, OCR fiable |
| FindIt T1-test | 413/500 (83 %) | idem, réservé à l'évaluation |
| synthetic | 93/121 (77 %) | tickets générés |
| selection_web | 24/42 (57 %) | scans web, tickets US inclus |
| photos_pixel | 18/71 (25 %) | photos téléphone, papier froissé |
| mixed | 6/11 | tickets et factures web |

Les rejets des photos réelles ne sont pas des erreurs d'annotation : l'OCR
lit `1,05` là où le ticket imprime `1,85`, ou ne lit rien. Ces tickets sont
inexploitables pour une supervision par checksum — c'est un **biais de
sélection assumé**, et la raison pour laquelle `photos_pixel` sert de jeu
d'évaluation, jamais d'entraînement.

## Le corpus

**537 tickets d'entraînement, 12 177 lignes** — T1-train 414, synthetic 93,
selection_web 24, mixed 6. **431 tickets d'évaluation, 10 245 lignes** —
T1-test 413, photos_pixel 18.

Répartition des rôles à l'entraînement : header 3462, footer 2926, item 2852,
total 546, item_label 498, payment 498, tax 421, noise 361, discount 176,
subtotal 174, summary 136, change 127.

`item_label` et `discount` sont les deux rôles que l'ancien schéma ne savait
pas exprimer ; `discount` reste le plus rare, à surveiller à l'entraînement.

## La barre à battre

`bench.line_roles --held-out` mesure le classifieur actuel sur le jeu
d'évaluation, rôles ramenés à ses 5 classes :

Sur 431 tickets, 3 814 lignes porteuses de prix :

| exactitude | `item` | `discount` | `total` | `payment` | `ignore` |
|---|---|---|---|---|---|
| 93,9 % | 99,5 % | **61,4 %** | **81,7 %** | 88,1 % | 91,6 % |

Deux remises sur cinq sont manquées — dont 13 prises pour des articles, ce
qui fausse la somme dans le mauvais sens. Et 35 lignes non contributives
sont classées `item` : exactement le défaut vu sur un ticket Maxi Zoo réel.

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
