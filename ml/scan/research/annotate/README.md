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
| open_prices | 3 119/4 350 | photos de contributeurs, 2024-2026, 347 enseignes |
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

**2 827 tickets d'entraînement, 68 678 lignes** — open_prices 2 241,
T1-train 417, synthetic 97, T2-train 69, mixed 3. **435 tickets d'évaluation,
10 448 lignes** — T1-test 415, photos_pixel 20. Avec `roles_only`,
l'entraînement monte à **3 775 tickets, 95 070 lignes**.

Répartition à l'entraînement : header 17 344, item 17 079, footer 11 348,
tax 3 273, noise 3 284, total 2 857, store 2 689, date_line 2 467, payment
2 374, item_label 2 214, summary 1 639, subtotal 896, discount 712,
change 502.

`open_prices` a multiplié le jeu par 4,8 et corrigé le déséquilibre qui
inquiétait : `discount` passe de 186 à 712 occurrences.

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

## Le format sur disque

Un fichier JSON par ticket, écrit et relu par `record.py` seul :

```json
{"image": "10.jpg",
 "provenance": {"model": "…", "prompt": "<empreinte>", "date": "…"},
 "lines":  [{"words": [{"text": "PAIN", "box": [x, y, x, y], "confidence": 1.0}]}],
 "annotation": {"lines": [{"role": "item", "amount": 2.50}], "store": "…", "date": "…"}}
```

L'entrée `i` décrit la ligne `i` : rien n'indexe, c'est le rang qui lie les
deux séquences. Ne sont **pas** stockés les champs qui se déduisent — le
texte d'une ligne (la jointure de ses mots), l'index d'une entrée (son rang)
et le verdict du filtre. Ce dernier se recalcule au chargement, en 0,15 s
pour tout le corpus : le stocker le laisserait mentir dès qu'une règle bouge,
et décider de la composition du corpus en cherchant un mot dans une phrase
française n'aurait survécu à aucune reformulation.

La provenance, elle, ne se déduit de rien. Elle dit quel modèle et quelle
version du prompt ont produit l'annotation, et c'est ce qui rend `--stale`
possible. Les tickets migrés depuis l'ancien format portent `prompt: null` :
le prompt de l'époque n'était noté nulle part, donc ils comptent tous comme
périmés — c'est la seule lecture honnête.

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
OPENROUTER_API_KEY=... uv run python -m annotate.run --stale <d>   # ré-annoter le périmé
uv run python -m annotate.audit t1train                           # confronter au golden
```

Faire évoluer un garde-fou ne coûte rien et ne demande aucune commande : le
filtre étant rejoué au chargement, un `validate.py` modifié change le corpus
au prochain `load()`.

`--stale` ne rappelle le modèle que sur les tickets dont la provenance ne
correspond pas au modèle et au prompt courants. Sans lui, un fichier déjà
présent n'est jamais retouché.

## Ce que vaut la vérité externe d'Open Prices (mesuré le 2026-08-26)

Chaque ticket Open Prices porte un total saisi par un contributeur, sans OCR
dans la boucle. Confronté à ce que le flow lit, sur les 700 tickets acceptés
qui en ont un : **668 coïncident (95,4 %)**.

Les 32 écarts ne sont pas 32 erreurs de lecture. Quatre ont été ouverts et
regardés à l'image, et **les quatre donnent tort au contributeur** :

| ticket | lu | déclaré | ce que le ticket imprime |
|---|---|---|---|
| op_0112909 | 4,00 | 16,45 | `Sous-Total 16.45` puis `Total 4.00€` après remise |
| op_0044869 | 11,72 | 20,22 | `MONTANT DU 11,72` ; 20,22 est l'espèce tendue |
| op_0062015 | 11,08 | 7,51 | `Total 11,08€` ; 7,51 est le prix d'un article |
| op_0037815 | 13,19 | 16,16 | `TOTAL A PAYER 13,19` ; 16,16 est le total avant remises |

**Ce total déclaré est donc un signal bruité, pas un golden.** Il désigne
tantôt le sous-total, tantôt l'espèce tendue, tantôt un article isolé. Il ne
peut pas servir de vérité d'évaluation ; il sert de **crible** — un désaccord
vaut la peine d'être ouvert, et l'ouvrir instruit dans les deux sens.

## Pourquoi pas le Batch API (mesuré le 2026-08-26)

Le Batch API d'OpenRouter facture moitié prix sous 24 h. Il est inutilisable
ici, pour deux raisons empilées :

1. **Vertex Gemini refuse les images en lot.** Le lot échoue à la validation :
   « Vertex Gemini does not support image inputs in batch because its
   serializer has no image URL map; use the sync API. » Ce n'est pas une
   limite du batch — `openai/gpt-5-mini:batch` et
   `anthropic/claude-haiku-4.5:batch` acceptent la même image.
2. **Le lot n'accepte que des URL publiques**, jamais de base64. Seul
   `open_prices` en a ; les autres corpus sont locaux.

Et l'enjeu est faible : une annotation coûte **0,0025 $** mesurée sur des
tickets réels (≈ 2 300 jetons d'entrée, 550 de sortie). Le lot aurait
économisé ~5 $ sur les 4 350 tickets d'`open_prices`, contre 24 h d'attente
au lieu d'une heure et un annotateur différent du reste du corpus.
