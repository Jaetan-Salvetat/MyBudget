# Entraîner le classifieur

Un seul modèle sert le quick-add **et** le scan : chacun lui apporte son corpus
et consomme le même ONNX. Guide de bout en bout, à suivre tel quel pour chaque
nouvelle version.

```
assets/categories.json                          ← source de vérité des 80 classes
        │
        ▼
knowledge/  ──►  dataset/entities.jsonl         ← ~28 600 entités du monde réel
        │
        ├──►  corpus/quick_add/build.py  ──►  dataset/train.jsonl + eval.jsonl
        └──►  corpus/receipts/build.py   ──►  dataset/receipts_*.jsonl
        │
        ▼
training/train.py  ──►  output/best/            ← poids PyTorch, les deux corpus
        │
        ├──►  evaluation/world.py               ← mémorisation vs généralisation
        ├──►  evaluation/quick_add.py           ← non-régression quick-add
        ├──►  evaluation/receipts.py            ← libellés de tickets réels
        │
        ▼
training/export_onnx.py  ──►  output/model.onnx  ──►  tool/models/publish.sh
```

`serving/` porte le contrat d'entrée/sortie du modèle : tout module qui y vit a
son miroir exact dans `ml/scan/pipeline/lib/src/categorize.dart`, vérifié par
la fixture de parité.

## 0. Prérequis

```bash
cd ml/classifier
uv sync                 # environnement Python
uv run python -m pytest # 30 tests, < 3 s, aucun accès réseau
```

Compter ~4 Go de RAM, 2 Go de disque pour les checkpoints, et une connexion
pour la première moisson (les sources sont ensuite en cache).

## 1. Moissonner la connaissance

```bash
uv run python -m knowledge.build
```

Écrit `dataset/entities.jsonl` : un nom, une classe, ses alias, son niveau de
notoriété. Les téléchargements atterrissent dans `dataset/cache/` et sont
réutilisés ; `refresh=True` sur un module force le retéléchargement.

| Source | Licence | Ce qu'elle apporte | Volume |
|---|---|---|---|
| `sources/services.py` | écrite à la main | abonnements, opérateurs, assureurs, administrations, commerce en ligne | ~1 300 |
| `sources/lexicon.py` | écrite à la main | vocabulaire courant FR/EN des 79 classes actives | ~1 700 |
| `sources/nsi.py` | BSD-3 | enseignes physiques mondiales (Name Suggestion Index) | ~11 500 |
| `sources/wikidata.py` | CC0 | compagnies aériennes, banques, assureurs, opérateurs, éditeurs de jeux, presse | ~9 400 |
| `sources/openfoodfacts.py` | ODbL | marques et noms de produits alimentaires et cosmétiques FR/EN | ~3 300 |
| `sources/patterns.py` | générée | commerces locaux (« Boulangerie Martin », « Smith's Barbershop ») | ~1 700 |

Le moissonnage ne redescend jamais sur un nom déjà connu d'une source plus
fiable : `SOURCE_PRIORITY` dans `knowledge/build.py` fixe l'ordre
`services > lexicon > nsi > wikidata > openfoodfacts ≈ patterns`.

**À lire dans la sortie :**

- `Conflits arbitrés` — deux sources ont donné deux classes au même nom. Une
  centaine est normale (une station-service qui vend aussi de l'épicerie). Un
  pic sur une paire inattendue signale une erreur de correspondance ;
- `Moins fournies` — une classe sous 10 entités sera portée par l'amplification
  du générateur, pas par de la vraie connaissance. C'est le premier endroit où
  ajouter du vocabulaire.

Les noms en écriture non latine sont écartés : un utilisateur FR/EN ne les
tapera pas, et ils consommeraient de la capacité pour rien.

**Relire un échantillon avant d'entraîner — c'est la porte de qualité :**

```bash
uv run python -m knowledge.audit 60
```

Le tirage est déterministe. Au-delà de deux erreurs de correspondance sur
soixante, corriger la source avant d'aller plus loin : un dataset à 10 %
d'erreurs plafonne le modèle à 90 %, quel que soit l'entraînement.

## 2. Générer le dataset

```bash
uv run python -m corpus.quick_add.build
```

Deux invariants portent la valeur de l'évaluation, tous deux sous test :

- **la coupe train/eval se fait par entité.** Un nom présent à l'entraînement
  ne peut pas apparaître à l'évaluation. Sans cela on mesure la mémoire ;
- **chaque classe a un budget borné** (`CLASS_SAMPLE_CAP`, `CLASS_SAMPLE_FLOOR`).
  Les 4 800 compagnies aériennes de Wikidata écraseraient sinon les dix
  libellés de pension alimentaire.

Chaque entité produit d'abord son **nom nu** — la forme la plus tapée — puis
des variantes : préfixes (« payé », « paid for »), suffixes temporels,
contextes, et un montant dans 15 % des cas. En production le montant est retiré
du texte par `PriceParserService` avant la classification ; l'entraînement
reflète cela.

Ordre de grandeur attendu : ~124 000 exemples d'entraînement, ~8 300
d'évaluation, entre 780 et 6 000 exemples par classe.

## 3. Entraîner

```bash
uv run python -m training.train
```

| Réglage | Valeur | Pourquoi |
|---|---|---|
| backbone | `jhu-clsp/mmBERT-small` | multilingue, 384 dim, 22 couches |
| batch | 32 | |
| epochs | 5 | la mémorisation des noms demande plusieurs passages |
| learning rate | 5e-5, cosine, warmup 6 % | plus haut que pour un fine-tuning classique : le modèle doit apprendre des faits, pas seulement une frontière |
| padding | dynamique, au plus long du lot | la saisie médiane fait quelques tokens ; bourrer à 64 multipliait le calcul par dix |
| échantillonnage | `LengthGroupedSampler` | rend au padding dynamique le gain qu'un mélange uniforme lui reprend |
| sélection | `category_f1` macro | l'accuracy récompenserait le déséquilibre des classes |

Environ 2 h sur Apple Silicon (MPS) pour ~19 400 pas. `save_total_limit=1` borne
les checkpoints de reprise ; le meilleur est copié dans `output/best/`.

Un entraînement interrompu se reprend avec
`trainer.train(resume_from_checkpoint=True)` — les `checkpoint-*` de `output/`
sont là pour ça et peuvent être supprimés une fois `output/best/` écrit.

## 4. Évaluer

```bash
uv run python -m evaluation.world    # connaissance monde, 294 cas écrits à la main
uv run python -m evaluation.quick_add    # non-régression sur evaluation/data/quick_add.json, 157 cas
```

`evaluation/world.py` sépare deux questions que la moyenne confond :

- **mémorisation** — les cas dont l'entité est dans `entities.jsonl`. Une erreur
  ici veut dire que l'entraînement ne retient pas ce qu'on lui donne : ajouter
  des données n'y changera rien, il faut plus d'epochs ou un LR plus haut ;
- **généralisation** — les cas dont l'entité est absente. Une erreur ici est un
  trou de connaissance : il faut moissonner ou écrire davantage.

La précision en production vaut `couverture × mémorisation + (1 − couverture) ×
généralisation`. Le rapport affiche aussi la calibration (ECE) et la précision
sur les 70/80/90 % de prédictions les plus confiantes — c'est ce qui décide du
seuil au-delà duquel l'app propose des suggestions plutôt qu'une réponse.

**Seuils d'acceptation avant publication :**

| Mesure | Cible |
|---|---|
| mémorisation | ≥ 97 % |
| généralisation | ≥ 80 % |
| `evaluation/quick_add.py`, niveau `app` | ≥ 95 % |
| type (dépense/revenu) | 100 % |
| ECE | ≤ 5 % |

## 5. Exporter et déployer

```bash
uv run python -m training.export_onnx                    # → output/model.onnx (int8)
uv run python -m evaluation.onnx                      # l'artefact livré, pas les poids
cd ../.. && ./tool/models/publish.sh             # asset versionné + release + lock
```

`evaluation/onnx.py` rejoue les deux corpus à travers le graphe quantifié et compare
ses décisions à celles du modèle PyTorch. Un écart de quelques cas sur 451 est
le bruit normal de l'int8 ; un effondrement signale une quantification ratée, et
c'est la seule occasion de le voir avant les utilisateurs.

`tool/models/publish.sh` régénère le tokenizer binaire, dépose
`assets/models/model_v<N+1>.onnx`, crée la release GitHub et réécrit
`tool/models/lock.env`. Le nom de l'asset est lu dans le manifeste par
`QuickAddModelRunner` : **incrémenter la version est obligatoire**, sinon les
installations existantes continuent de tourner sur le modèle extrait en cache.

## 6. Faire évoluer la taxonomie

L'ordre des slugs dans `assets/categories.json` est le contrat avec le modèle.
Insérer une classe au milieu décale toutes les suivantes.

> Un modèle à 75 classes servi derrière une liste de 80 labels a déjà produit
> `salaire 2500 → divers.cadeau_offert` : chaque index au-delà du point
> d'insertion était décalé de cinq. L'évaluation tombait à 48 % alors que le
> modèle, réaligné, était à 97 %. **Toute modification de la taxonomie impose un
> réentraînement complet avant publication.**

Checklist :

1. éditer `assets/categories.json`, bumper `version` ;
2. `dart run tool/generate_taxonomy_labels.dart` ;
3. ajuster `CategoryTaxonomyService.expectedVersion` ;
4. couvrir la nouvelle classe dans `knowledge/sources/lexicon.py` — le test
   `test_every_active_slug_has_hand_written_vocabulary` échoue sinon ;
5. ajouter des cas dans `evaluation/data/world.json` — `test_world_corpus_covers_every_active_class`
   échoue sinon ;
6. relancer la chaîne complète, puis republier.

Une classe dépréciée (`deprecated` + `alias_of`) garde son index et sa sortie
dans le modèle : `taxonomy.canonical()` redirige, aucune entité ne la vise.

## 7. Ajouter de la connaissance

| Ce qu'on veut apprendre | Où l'écrire |
|---|---|
| une marque, un abonnement, un service | `knowledge/sources/services.py` |
| un mot courant, un synonyme, de l'argot | `knowledge/sources/lexicon.py` |
| une famille entière d'enseignes physiques | `knowledge/mapping_nsi.py` |
| une classe entière d'entités Wikidata | `CLASS_TO_SLUG` dans `knowledge/sources/wikidata.py` |
| un nom que deux sources classent différemment | `OVERRIDES` dans `knowledge/build.py` |
| un motif de commerce local | `knowledge/sources/patterns.py` |

Les alias se séparent par une barre verticale : `"Disney+|Disney Plus|disney"`.
Après ajout : `python -m knowledge.build`, `python -m corpus.quick_add.build`,
`python train.py`.

## 8. Le même modèle pour le scan : libellés de ticket

Le scan local (`ml/scan`) sort une enseigne et des libellés tels qu'une
caisse les imprime — `*160G BLC PLT 4TR.F`, `CRF-CITY LA ROCHELLE`. Mesuré
sur les 1 000 tickets FindIt étiquetés à la main (`corpus/receipts/labels.py`,
5 005 articles, T1-test = 2 531 jamais vus), le modèle quick-add seul y est
aveugle : 8 % strict en majuscules, 20 % après normalisation. Deux raisons :
il n'a jamais vu de majuscules sans accent ni d'abréviations de caisse, et il
ne connaît presque aucun produit (« jus de pomme bio » → fast-food).

Ce que les corpus « style ticket » ajoutent, sans changer l'architecture ni l'ONNX :

```bash
uv run python -m receipts.fetch_off                 # Open Food/Beauty Facts FR → dataset/cache/*.parquet
uv run python -m receipts.generate_receipt_dataset  # → dataset/receipts_train.jsonl (+ eval)
uv run python -m training.train                              # train.jsonl + receipts_train.jsonl
uv run python -m evaluation.receipts --cascade        # T1-test, strict / famille / ticket
uv run python -m serving.parity_fixture   # parité Dart de la normalisation
```

- `serving/normalize.py` : ce que l'app applique avant le modèle (retrait
  des marqueurs, contenances, compteurs, codes ; minuscules). Miroir Dart
  dans `ml/scan/pipeline/lib/src/categorize.dart`, parité vérifiée sur les
  3 845 lignes des golden ;
- `corpus/receipts/style.py` : déforme un nom de produit comme une caisse
  (abréviations `PLT`/`JBN`/`1/2ECR`, troncature 16-26 caractères,
  contenance `4X125G`, marque distributeur `CRF`/`U`, voyelles supprimées) ;
- `corpus/receipts/lexicon.py` : ~1 900 libellés écrits à la main pour ce que les
  sources ouvertes ne couvrent pas (vêtements, bricolage, pharmacie, plats,
  carburant, péage…), les abréviations d'enseigne (`CRF CITY`, `ITM`) et
  200 villes pour les en-têtes ;
- `corpus/receipts/build.py` : OFF/OBF (12 000 produits les plus
  scannés), lexique, en-têtes d'enseigne (entités physiques + ville +
  raison sociale), et les libellés réels de T1-train avec leur vérité —
  **jamais T1-test**. Plafond de 12 000 lignes par classe : sans lui,
  l'alimentaire tire tout libellé inconnu vers « supermarché » et le
  quick-add régresse (mesuré : `eval_world` 96 → 94 %, revenu à 96 % avec le
  plafond et un rejeu de 50 000 lignes) ;
- `serving/cascade.py` : la décision de l'app. La taxonomie est une
  taxonomie de marchands, donc **classe du ticket = enseigne** (si lue à
  P ≥ 0,9, sinon vote des articles pondéré par la confiance) et **article =
  classe du ticket**, sauf famille distincte (vêtement, animalerie,
  pharmacie, jouet…) à P ≥ 0,8 dans une enseigne alimentaire. Seuils
  balayés sur T1-train : un seuil enseigne élevé rend la main au vote des
  articles dès que l'en-tête est incertain, et le vote est devenu fiable ;
- `training/finetune.py` : boucle rapide (40 min) qui poursuit `output/best`
  sur le corpus ticket + rejeu du corpus général, vers `output/receipts` —
  jamais dans `output/best`. `CLASSIFIER_MODEL=output/receipts` fait tourner
  `evaluation/world.py` et `evaluation/quick_add.py` sur ce modèle.

Mesures sur T1-test (articles, vérité manuelle) :

| Modèle | Article seul (strict / famille) | Cascade, enseigne lue | Cascade, enseigne masquée |
|---|---|---|---|
| `output/best` (quick-add livré) | 20 % / 38 % | 40 % / 65 % — ticket 63 % | 35 % / 54 % — ticket 46 % |
| + fine-tune corpus ticket v1 (60 % supermarché, seuils 0,5/0,6) | 65 % / 88 % | 86 % / 93 % — ticket 87 % | 70 % / 89 % — ticket 81 % |
| + fine-tune corpus ticket v2 (plafond par classe, rejeu 50 k, seuils 0,9/0,8) | 65 % / 87 % | 83 % / 93 % — ticket 88 % | 75 % / 92 % — ticket 85 % |
| **`training/train.py` complet, 5 epochs, deux corpus (`output/full_receipts`)** | 67 % / 89 % | **85 % / 93 % — ticket 88 %** | 75 % / 92 % — ticket 86 % |

« Famille » confond supermarché/épicerie/marché et
restaurant/fast-food/café/bar : ces frontières sont des conventions
d'enseigne, pas des faits. Le strict en enseigne lue tombe avec v2 sur une seule
bascule intra-famille (« Carrefour market AYTRE » → épicerie, 522 articles :
la base d'entités classe Carrefour Market en supérette). Les erreurs de
famille restantes sont des enseignes inconnues (cantines, petits
restaurants) dont les plats — `pain`, `tartiflette` — ressemblent à des
produits.

Le modèle complet repasse les seuils de la section 4 : `eval_world` 96 %,
ECE 3,4 %, 99 % de justesse sur les 80 % les plus confiants, `evaluation/quick_add.py`
niveau `app` 100 % — le scan et le quick-add partagent le même ONNX. Il
n'est **pas publié** : `output/best` reste le modèle livré tant que la
décision n'est pas prise.

## 9. Pistes non explorées

- **Adaptation MLM du backbone.** 98,3 M des 131 M de paramètres sont dans la
  table d'embeddings, là où vit la connaissance lexicale — et le fine-tuning
  supervisé n'y touche presque pas. Une passe de masked language modeling sur
  le corpus d'entités avant le fine-tuning est le levier théorique le plus
  direct, pour environ une heure de calcul supplémentaire.
- **Élagage du vocabulaire.** 256 000 tokens pour deux langues cibles : le
  réduire à ~64 000 ferait passer l'asset de 140 Mo à ~50 Mo et densifierait
  les embeddings restants.
- **Gazetteer embarqué.** Une table nom → classe (2-5 Mo) devant le modèle
  mettrait les enseignes connues à ~100 % sans dépendre de la mémorisation,
  régénérée par le même pipeline à chaque release.
- **Calibration par température** sur un jeu tenu à part, pour que le seuil de
  confiance de l'app veuille dire quelque chose.

## 10. Journal

| Version | Données | `world` | `quick_add` |
|---|---|---|---|
| 75 classes (2026-08-21) | 2 172 exemples écrits à la main, augmentation ×8 | 20 % sur des marques hors corpus | 97 % (labels réalignés) |
| 80 classes, itération 1 (2026-08-23) | 28 668 entités, 124 175 exemples, 5 epochs | **93 %** — couverture 98 %, mémorisation 94 %, type 100 %, récurrence 90 %, ECE 3,5 % | catégorie 97 %, récurrence 93 % |
| 80 classes, itération 2 (2026-08-24) | + récurrence déduite de la formulation, marques manquantes, mots de boulangerie | **96 %** — couverture 100 %, type 99 %, récurrence 95 %, ECE 3,5 %, **100 % de justesse sur les 80 % les plus confiants** | catégorie **99 %**, type 100 %, récurrence 98 % |

| 80 classes + corpus ticket (2026-08-25, `output/full_receipts`, non publié) | + 40 539 libellés style ticket (OFF, lexique, T1-train, en-têtes), plafond 12 000/classe | **96 %** — ECE 3,4 %, 99 % sur les 80 % les plus confiants | catégorie 100 % (`app`), hard 88 % |

Export int8 vérifié : mêmes scores que les poids PyTorch, 447 décisions
identiques sur 451.

Ce que l'itération 1 a montré :

- **la couverture est le verrou levé.** 98 % des cas d'`eval_world` trouvent leur
  entité dans la base moissonnée, contre une poignée avant. La connaissance
  monde n'est plus le facteur limitant ;
- **la calibration tient** : 98 % de justesse sur les 70 à 90 % de prédictions
  les plus confiantes, ECE à 3,5 %. Un seuil sépare proprement ce que le modèle
  sait de ce qu'il devine ;
- **la récurrence avait régressé** parce qu'elle était déduite de la classe et
  non de la formulation : « abonnement salle de sport » restait ponctuel, les
  salles de sport étant majoritairement des achats uniques dans la base. La
  règle de marqueurs de l'itération 2 l'a ramenée de 84 % à 96 % sur le niveau
  `medium` ;
- **ce qui reste faux est surtout de la frontière de taxonomie** — Greggs entre
  boulangerie et fast-food, le forfait ski entre sport et visite, JD Sports
  entre vêtements et sport. Aucune donnée supplémentaire ne tranchera : c'est la
  taxonomie qu'il faudrait préciser.
