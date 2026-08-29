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
                    ▲
        Open Prices ┘  ← libellés de caisse réels, vérité par code-barres
        │
        ▼
training/train.py  ──►  output/best/            ← poids PyTorch, les deux corpus
        │
        ├──►  evaluation/world.py               ← mémorisation vs généralisation
        ├──►  evaluation/quick_add.py           ← non-régression quick-add
        ├──►  evaluation/receipts.py            ← libellés de tickets réels
        │
        ▼
training/export_onnx.py  ──►  output/best/model.onnx  ──►  publish.sh
```

`serving/` porte le contrat d'entrée/sortie du modèle : `normalize.py` a son
miroir exact dans `ml/scan/pipeline/lib/src/normalize.dart`, vérifié par la
fixture de parité. Il n'y a rien d'autre à y mettre — depuis que chaque article
se classe seul, l'app n'a plus de décision à porter après le modèle (§8).

## 0. Prérequis

```bash
cd ml/classifier
uv sync                 # environnement Python
uv run python -m pytest # 30 tests, < 3 s, aucun accès réseau
```

Compter ~4 Go de RAM, 2 Go de disque pour les checkpoints, et une connexion
pour la première moisson (les sources sont ensuite en cache).

Le corpus déjà construit et son cache de moisson se récupèrent sans refaire
les étapes 1 et 2 :

```bash
./tool/ml_data/fetch.sh classifier    # dataset/*.jsonl + dataset/cache/
```

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
- les lignes préfixées `alias` sont des **noms disputés par deux entités**. Un
  alias ne peut désigner qu'une classe : le nom canonique l'emporte toujours sur
  l'alias, sinon la source la plus fiable, et à égalité personne. Sans cet
  arbitrage « McDonald's » — alias de « McDonald's PlayPlace » — sortait du
  corpus étiqueté *activités enfants* **et** *fast-food*, et le modèle
  apprenait une contradiction ;
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

**La tournure est française, le monde ne l'est pas.** L'app ne sert que des
utilisateurs francophones : tout le budget de phrase va au français. Les noms
d'entités, eux, restent internationaux — un utilisateur français tape Netflix,
Ikea et Zalando, et la base moissonnée est à dominante US/GB. C'est la langue
de la formulation qui est monolingue, jamais celle des entités.

Le corpus générait auparavant une variante sur deux en anglais. À budget de
formes identique, l'abandon de l'anglais double la quantité de français sans
ajouter une ligne : 124 332 exemples, tous français, contre ~62 000 avant.

Chaque entité produit d'abord son **nom nu** — la forme la plus tapée — puis
des variantes : préfixes (« payé », « j'ai claqué »), suffixes temporels,
contextes, et un montant dans 15 % des cas. En production le montant est retiré
du texte par `PriceParserService` avant la classification ; l'entraînement
reflète cela.

**Le corpus est écrit dans la forme exacte que l'app envoie au modèle.** Chaque
libellé passe par `normalize_query` : minuscules, accents repliés, ponctuation
décollée. « Father & Son », « father &son » et « FATHER&SON » sont la même
chaîne avant d'atteindre le tokenizer, et le modèle ne dépense pas une once de
capacité à retenir cette équivalence. Le port Dart (`normalizeQuery`, dans
`ml/scan/pipeline`) est appliqué par `QuickAddClassifierService` avant le
tokenizer et par `normalizeReceiptLine` pour le scan ; la parité est vérifiée
sur 3 022 noms d'entités et 3 845 libellés golden par
`ml/scan/pipeline/test/normalization_test.dart`.

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
| bruit de frappe | 30 % des exemples, une faute (deux dans un quart des cas) | voir plus bas |

**La faute de frappe est ajoutée au moment où le lot part dans le modèle, jamais
écrite dans le corpus.** Générer `aamazon` dans `train.jsonl` ferait apprendre
`aamazon` en plus d'`amazon` : une entrée de dictionnaire de plus, l'inverse de
ce qu'on cherche. Corrompre dans le collateur donne une faute différente à
chaque epoch — le modèle ne voit jamais deux fois la même et n'a rien à en
retenir sinon que le bruit ne compte pas. `training/corruption.py` ne porte que
les fautes qui survivent à la normalisation — lettre doublée, omise, touche
AZERTY voisine, insertion, transposition, phonétique, mot coupé
(« carre four »), espace perdu (« carrefourcity ») : la casse, les accents et la
ponctuation sont déjà traités en amont, les faire apprendre serait payer deux
fois. L'évaluation lit le texte propre (`get_eval_dataloader` retire le bruit).

**Le modèle apprend tous les cas, la mesure garde quand même sa réserve** :
plutôt que d'écarter une faute de l'entraînement, `evaluation/robustness.py`
rejoue le même mécanisme avec d'autres instances — AZERTY à l'entraînement,
QWERTY à la mesure ; digrammes de consonnes (« farmacie ») à l'entraînement,
voyelles (« oto », « wazo ») à la mesure ; lettre doublée à l'entraînement,
triplée à la mesure. Un modèle qui a compris que le bruit ne compte pas tient
sur les trois ; un modèle qui a appris nos règles s'effondre. Le test
`test_evaluation_operators_are_held_out_from_training` empêche les deux jeux de
se rejoindre par accident.

Environ 2 h sur Apple Silicon (MPS) pour ~19 400 pas. `save_total_limit=1` borne
les checkpoints de reprise ; le meilleur est copié dans `output/best/`.

Un entraînement interrompu se reprend avec
`trainer.train(resume_from_checkpoint=True)` — les `checkpoint-*` de `output/`
sont là pour ça et peuvent être supprimés une fois `output/best/` écrit.

## 4. Évaluer

```bash
uv run python -m evaluation.world           # mémorisation, 166 cas écrits à la main
uv run python -m evaluation.generalization  # entités jamais vues, 8 307 exemples
uv run python -m evaluation.quick_add       # non-régression, 153 cas
uv run python -m evaluation.robustness      # ce que coûte une faute de frappe
uv run python -m evaluation.build_typos     # régénère le corpus des fautes réelles
```

**Sans `evaluation/generalization.py`, la grille ment.** `world.py` affiche
`couverture de la base : 100%` : chacun de ses cas a son entité dans
`entities.jsonl`, sa ligne « Généralisation » porte sur un cas. Le 96 % qu'il
annonce vaut pour les noms de la base, pas pour ce qu'un utilisateur tape. Le
seul corpus où la question se pose est `dataset/eval.jsonl`, dont la coupe est
faite par entité : mesuré à **66,3 %** sur le modèle livré, contre les 96 %
affichés par `world.py`. Un modèle qui passe `world` sans passer
`generalization` n'a fait que mémoriser.

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

`evaluation/robustness.py` répond à la seule question que les trois autres ne
posent pas : ce qui reste quand l'utilisateur écrit mal. Chaque opérateur est
appliqué au texte brut, puis le même texte passe par `normalize_query` — l'écart
entre les deux colonnes est ce que la règle déterministe rend, et que le modèle
n'a pas à apprendre. Les opérateurs d'évaluation sont tenus à l'écart de ceux de
l'entraînement : mesurer un modèle avec le bruit qu'on lui a servi ne mesure que
sa mémoire.

Relevé sur le modèle v11 (livré avant ce chantier, ni normalisation à
l'inférence ni bruit à l'entraînement), 2 000 entités jamais vues du corpus
canonique :

| Opérateur | brut | normalisé |
|---|---|---|
| (aucun) | 70,3 % | 70,3 % |
| **majuscules** | **33,1 %** | 70,3 % |
| accents ajoutés | 46,5 % | 70,3 % |
| accents retirés | 70,3 % | 70,3 % |
| ponctuation collée | 59,6 % | 64,1 % |
| *jamais vu à l'entraînement* | | |
| phonétique | 53,1 % | 52,4 % |
| lettre triplée | 47,0 % | 47,0 % |
| touche qwerty | 44,8 % | 44,8 % |
| mot coupé | 41,3 % | 41,3 % |
| *vu à l'entraînement* | | |
| espace perdu | 54,7 % | 54,7 % |
| doublement | 47,9 % | 47,9 % |
| insertion | 45,5 % | 45,5 % |
| omission | 44,5 % | 44,5 % |
| transposition | 43,7 % | 43,7 % |
| touche voisine | 42,2 % | 42,2 % |

Le coût n'était pas là où on le croyait : les accents ne coûtaient que
2 points, les majuscules en coûtaient 37. Une saisie en capitales était
quasiment illisible pour le modèle, et une règle déterministe la répare
entièrement. Ce que la normalisation ne peut pas rendre — la lettre qui ripe,
l'espace perdu — coûte encore 15 à 29 points, et c'est là, et seulement là, que
le modèle a quelque chose à apprendre.

Le même rapport se termine par les **fautes réelles** : 68 cas écrits à la main
(`evaluation/data/typos.json`, régénérés par `evaluation.build_typos`) où un
francophone se trompe pour de bon sur un nom que la base connaît —
« farmacie », « carrefourcity », « decatlhon », « boulan gerie ». Chaque cas
porte sa forme correcte à côté, et la mesure est **la chute entre les deux** :
la justesse absolue dépendrait de la connaissance, la chute ne dépend que de la
robustesse. La classe vient de `dataset/entities.jsonl`, jamais d'un jugement
écrit à la main, sans quoi la vérité du corpus d'évaluation divergerait de celle
de l'entraînement.

Deux des six axes — casse et ponctuation collée — doivent afficher **zéro
chute** : `normalize_query` les efface avant le modèle, et un test le vérifie
sur chaque cas. Les quatre autres (frappe, phonétique, agglutination, mot
coupé) sont ce que le modèle doit comprendre seul.

**Seuils d'acceptation avant publication :**

| Mesure | Où | Cible |
|---|---|---|
| mémorisation | `world.py` | ≥ 97 % |
| **entités jamais vues, catégorie stricte** | `generalization.py` | **> 66,3 %**, la valeur du modèle livré |
| entités jamais vues, à la famille près | `generalization.py` | > 68,7 % |
| justesse sur les 50 % plus confiants | `generalization.py` | ≥ 93 % |
| niveau `app` | `quick_add.py` | ≥ 95 % |
| type (dépense/revenu) | `world.py` | 100 % |
| ECE | `world.py` | ≤ 5 % |
| une faute de frappe | `robustness.py` | chute < 10 points sous le propre |
| casse et accents | `robustness.py` | égal au propre, à 1 point près |

La ligne qui décide est celle des entités jamais vues : c'est la seule qui
mesure ce que le modèle fera d'un nom qu'un utilisateur invente ou d'une
enseigne que la moisson n'a pas vue.

## 5. Exporter et déployer

```bash
uv run python -m training.export_onnx                    # → output/best/model.onnx (int8)
uv run python -m evaluation.onnx                      # l'artefact livré, pas les poids
cd ../.. && ./tool/models/publish.sh             # asset versionné + release + lock
```

`evaluation/onnx.py` rejoue les deux corpus à travers le graphe quantifié et compare
ses décisions à celles du modèle PyTorch. Un écart de quelques cas sur 451 est
le bruit normal de l'int8 ; un effondrement signale une quantification ratée, et
c'est la seule occasion de le voir avant les utilisateurs.

L'export atterrit toujours à côté des poids qu'il encode (`MODEL_DIR`), et
`registry.env` ne publie que `output/best/model.onnx`. Livrer un autre run se
fait en en faisant `output/best` — il n'y a pas de chemin d'export à choisir.
`publish.sh` publie **tout, sans paramètre** : on ne réentraîne qu'un modèle à
la fois, les cinq autres se reportent seuls sous la nouvelle version. Il affiche
pour chacun sa source, sa date et `INCHANGE` quand le sha ne bouge pas.

| Situation | Ce que fait `publish.sh` |
|---|---|
| source déclarée absente | `exit 65` — refaire l'export, ou `--carry-over <id>` |
| source présente, octets identiques | `INCHANGE` affiché, report sous la nouvelle version |
| **aucun** modèle n'a bougé | `exit 68` — une version ne se bumpe pas pour rien |

C'est le dernier cas qui compte : **v11 et v12 sont parties byte-identiques à
v10 sur les six modèles**. Une release ne se justifie que par au moins un modèle
qui change — le nom de l'asset est ce que l'app lit pour choisir son modèle et ce
sur quoi le cache ONNX s'indexe, le bumper pour rien fait ré-extraire 142 Mo chez
chaque utilisateur sans changer une seule décision.

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
| un surnom que les gens tapent (« macdo », « carrouf », « décat ») | alias dans `knowledge/sources/services.py` |
| un mot courant, un synonyme, de l'argot | `knowledge/sources/lexicon.py` |
| une famille entière d'enseignes physiques | `knowledge/mapping_nsi.py` |
| une classe entière d'entités Wikidata | `CLASS_TO_SLUG` dans `knowledge/sources/wikidata.py` |
| un nom que deux sources classent différemment | `OVERRIDES` dans `knowledge/build.py` |
| un motif de commerce local | `knowledge/sources/patterns.py` |

Les alias se séparent par une barre verticale : `"Disney+|Disney Plus|disney"`.
Après ajout : `python -m knowledge.build`, `python -m corpus.quick_add.build`,
`python train.py`.

## 8. Le même modèle pour le scan : libellés de ticket

Le scan local (`ml/scan`) sort des libellés tels qu'une caisse les imprime —
`*160G BLC PLT 4TR.F`, `AUC BIOD LAIT SOL ENT BT 1L`. **Chaque article se
classe seul** : le modèle lit un libellé normalisé et rend une catégorie, celle
de l'article, sans rien savoir du ticket où il a été lu.

### Ce que la cascade cachait

Jusqu'au 2026-08-29, la classe d'un article était celle de son enseigne : la
taxonomie étant une taxonomie de marchands, cela paraissait juste. Trois
mesures ont clos la question.

- La cascade affichait **88,8 % strict / 93,0 % famille** sur T1-test. Le
  corpus l'expliquait à lui seul : 63 % des tickets FindIt sont alimentaires
  et leur en-tête suffit à les trancher. Découpé, l'enseigne lue tenait 98,1 %
  sur l'alimentaire et **77,8 % ailleurs** ; le vote des articles, 66,0 %.
  Moyenné sur les 27 classes de ticket plutôt que sur les tickets : **76,7 %**.
- Tout reposait sur la lecture de l'en-tête, que le modèle rate : **58,6 %
  strict / 69,2 % famille** sur les 266 en-têtes réels étiquetés à la main. Un
  en-tête faux rend faux tous les articles du ticket.
- La vérité elle-même était une recopie de l'enseigne — **4 871 des 5 005
  articles, 97,3 %**. Elle rendait le corpus contradictoire : **10,7 % des
  lignes d'entraînement** portaient un libellé classé de deux ou trois façons
  (`banane` restaurant / épicerie / supermarché, `baguette` boulangerie /
  épicerie / supermarché). Un modèle n'en tire que la classe majoritaire.

`serving/cascade.py` et sa décision côté Dart ont été retirés ;
`ml/scan/pipeline/lib/src/categorize.dart` ne fait plus que classer chaque
libellé. `STORE_LABELS` survit comme diagnostic de lecture d'en-tête
(`evaluation/receipts.py --stores`), et ne décide plus d'aucune catégorie.

### Où la vérité d'article vient chercher son échelle

**Open Prices** (ODbL, projet Open Food Facts) est le corpus qui manquait. Son
champ `product_name` n'est pas le nom canonique du produit : c'est **le libellé
tel qu'il est imprimé**, recopié par le contributeur qui photographie son
ticket, son étiquette de rayon ou son historique de carte de fidélité. La
preuve tient dans les doublons — 25 400 codes-barres y portent de deux à
trente-neuf écritures, et ce sont des écritures de caisse :

```
3560071009175  446ML LENTILLES BIO CRF / LENTILLES BIO CRF / LENTILLES
3183280012837  LA BALEINE BICARBONATE 800G / SALINS BICARBONATE BTE
3372463000017  BISQUE DE HOMARD 1/2 410G / BISQUE DE HOMARD 12410G
```

Abréviations, troncatures, marques distributeur (`AUC`, `CRF`, `PAT`),
contenances collées, fautes de saisie : la morphologie que `style.py`
fabriquait à la main, en vrai et par dizaines de milliers.

La vérité vient du **produit** : le code-barres donne les catégories Open Food
Facts. `corpus/receipts/categories.py` les traduit dans notre taxonomie, et
`knowledge/sources/openfoodfacts.py` lit la même règle — deux règles feraient
apprendre au modèle que `baguette` est boulangerie quand elle vient du
quick-add et supermarché quand elle vient d'un ticket, ce qui était le cas sur
4,9 % des textes communs aux deux corpus.

Volume : **114 297 libellés français distincts** portent une vérité, dont
95 373 d'étiquettes de rayon, 10 026 d'historiques RGPD, 5 986 d'imports
enseigne, 4 036 de tickets photographiés. Après jointure et normalisation :
**134 344 lignes, 85 209 libellés sans ambiguïté**.

**La limite est nette et il faut la connaître :** 98 % des libellés viennent de
`shop=supermarket` (97 785) et `shop=convenience` (16 202) — jardinerie 382,
pharmacie 378, bricolage 255, librairie 77. Open Prices règle la moitié
alimentaire et **ne dit rien** de la moitié où le modèle se plante :
restaurant, travaux, vêtements, mobilier. Un plat du jour et une planche de
contreplaqué n'ont pas de code-barres.

### La chaîne

```bash
uv run python -m corpus.receipts.fetch_off      # produits FR + table code-barres → catégories
uv run python -m evaluation.build_receipts      # vérité d'article de T1-train/T1-test
uv run python -m corpus.receipts.build          # → dataset/receipts_*.jsonl
uv run python -m training.train                 # train.jsonl + receipts_train.jsonl
uv run python -m evaluation.receipts            # T1-test, article seul
uv run python -m serving.parity_fixture         # parité Dart de la normalisation
```

`fetch_off.py` ne télécharge plus les 8 Go du dump : DuckDB ne lit à distance
que les colonnes demandées. Hugging Face coupe les lectures anonymes trop
longues en 429, d'où les reprises à attente doublante ; le fichier n'est publié
qu'une fois complet, sans quoi un parquet tronqué passerait pour du cache et le
corpus se construirait sur un dixième de la base sans que rien ne le signale.

Les autres sources n'ont pas bougé : `corpus/receipts/lexicon.py` (~1 900
libellés écrits à la main pour ce qu'Open Food Facts ne couvre pas),
`corpus/receipts/style.py` (déformation de caisse, encore utile là où il n'y a
pas de libellé réel), les en-têtes d'enseigne, et les libellés de T1-train.

### Trois invariants, tous sous test

- **La vérité d'un article ne regarde jamais l'enseigne** (`truth.py`) :
  surcharge écrite à la main, puis répertoire Open Prices. Un article que ni
  l'une ni l'autre ne classe sort du corpus — mieux vaut une ligne de moins
  qu'une ligne fausse.
- **Aucun libellé ne porte deux classes** (`build.drop_contradictions`). Le
  lexique range `asperges` au marché et Open Food Facts au supermarché ;
  `shampooing` est de l'entretien de voiture d'un côté, un produit de rayon de
  l'autre. Trancher au cas par cas serait écrire une règle par libellé.
  Mesuré : 177 libellés retirés sur 50 204.
- **Aucune écriture de T1-test n'entre à l'entraînement**
  (`build.held_out_texts`), golden T1-train compris : `banane` et `baguette`
  existent des deux côtés, et les apprendre ferait mesurer la mémoire.

Vérifié après reconstruction : 0 contradiction, 0 fuite.

### Ce que ça coûte à la mesure

La vérité d'article ne couvre pas tout le golden : **1 077 articles sur 5 005**
(T1-test 548 sur 2 531). Le reste sort du corpus d'évaluation faute de vérité —
il n'y est pas remplacé par la classe du magasin. Conséquence à garder en tête :
`restauration.restaurant` compte désormais **zéro** article mesuré, alors que
c'était la première confusion du modèle. **La mesure est devenue juste, elle
n'est pas devenue complète.** Fermer ce trou demande une vérité d'article pour
les ~3 000 libellés non alimentaires du golden, qu'aucune base publique ne
donne : c'est de l'annotation, filtrée comme celle du tagger de rôles.

Relevé du modèle livré (v13) contre cette nouvelle vérité, article seul :

| Variante | T1-train | T1-test |
|---|---|---|
| brut | 53,1 % / 68,2 % | 46,7 % / 59,3 % |
| minuscules | 59,4 % / 91,5 % | 49,3 % / 82,3 % |
| **normalisé** (ce que l'app envoie) | 46,7 % / 91,3 % | **40,0 % / 83,2 %** |

Le strict s'effondre parce que la vérité distingue maintenant supermarché,
épicerie et boulangerie là où l'ancienne recopiait l'enseigne : le modèle livré
a appris à tout ranger au supermarché. C'est la mesure d'un modèle entraîné sur
l'ancienne vérité, pas celle du corpus refait.

## 9. Pistes non explorées

- **Adaptation MLM du backbone.** 98,3 M des 131 M de paramètres sont dans la
  table d'embeddings, là où vit la connaissance lexicale — et le fine-tuning
  supervisé n'y touche presque pas. Une passe de masked language modeling sur
  le corpus d'entités avant le fine-tuning est le levier théorique le plus
  direct, pour environ une heure de calcul supplémentaire.
- **Gazetteer embarqué, avec appariement flou.** Une table nom → classe
  (2-5 Mo) devant le modèle mettrait les enseignes connues à ~100 % sans
  dépendre de la mémorisation, et une distance d'édition y traiterait
  `aamazon` → Amazon — ce que le modèle fait structurellement mal, `amazon`
  tenant en un token quand `aamazon` part en trois morceaux sans rapport.
  `store_gazetteer` fait déjà ça côté scan pour les enseignes sorties de l'OCR.
- **Vérité d'article pour le non-alimentaire.** Open Prices couvre le rayon
  courses et rien d'autre : plat de restaurant, quincaillerie, vêtement,
  mobilier n'ont pas de code-barres, et ce sont les classes où le modèle se
  trompe. Les ~3 000 libellés concernés du golden demandent une annotation,
  filtrée comme celle du tagger de rôles. C'est le premier poste à ouvrir : la
  mesure de §8 est juste mais aveugle sur ces classes.
- **Normalisation en amont du tokenizer** pour le quick-add : accents, casse,
  espaces autour de la ponctuation. `father &son` = `father & son` ne se
  règle pas dans le modèle. `serving/normalize.py` le fait pour le scan, le
  quick-add n'a pas d'équivalent.
- **Calibration par température** sur un jeu tenu à part, pour que le seuil de
  confiance de l'app veuille dire quelque chose.

### Pistes fermées par la mesure (2026-08-28)

- **Changer de backbone.** Banc d'essai à recette identique, 1 epoch, jugé sur
  les entités jamais vues : mmBERT-small 65,2 %, mmBERT-base 67,6 %,
  EuroBERT-210m 53,6 %. La capacité vaut **+2,4 points pour 2,8× l'encodeur et
  +148 Mo d'asset**, quand les données en valent +4,8 gratuitement (65,2 % à
  1 epoch → 70,0 % à 5 epochs avec le corpus ticket). Rejouer le banc :
  `uv run python -m training.bakeoff <repo> [<repo>…]`.
- **Élagage du vocabulaire.** Les 256 000 tokens ne sont pas du gras : mesurée
  sur 4 000 noms d'entités, la fragmentation de mmBERT est la meilleure de tous
  les candidats — 3,11 tokens par nom et 40,9 % des noms en ≤2 tokens, contre
  3,83 / 22,1 % pour EuroBERT, 4,14 / 17,8 % pour ModernBERT, 4,27 / 17,9 % pour
  CamemBERTv2. C'est ce vocabulaire qui fait survivre les noms de marque
  entiers, et c'est l'écart de tokenisation qui explique la chute d'EuroBERT.
  Le réduire aux 32 827 tokens que voit le corpus dégraderait exactement le cas
  qui échoue.
- **Calibration par température** sur un jeu tenu à part, pour que le seuil de
  confiance de l'app veuille dire quelque chose.

## 10. Journal

| Version | Données | `world` | `quick_add` |
|---|---|---|---|
| 75 classes (2026-08-21) | 2 172 exemples écrits à la main, augmentation ×8 | 20 % sur des marques hors corpus | 97 % (labels réalignés) |
| 80 classes, itération 1 (2026-08-23) | 28 668 entités, 124 175 exemples, 5 epochs | **93 %** — couverture 98 %, mémorisation 94 %, type 100 %, récurrence 90 %, ECE 3,5 % | catégorie 97 %, récurrence 93 % |
| 80 classes, itération 2 (2026-08-24) | + récurrence déduite de la formulation, marques manquantes, mots de boulangerie | **96 %** — couverture 100 %, type 99 %, récurrence 95 %, ECE 3,5 %, **100 % de justesse sur les 80 % les plus confiants** | catégorie **99 %**, type 100 %, récurrence 98 % |

| 80 classes + corpus ticket (2026-08-25, `output/full_receipts`, non publié) | + 40 539 libellés style ticket (OFF, lexique, T1-train, en-têtes), plafond 12 000/classe | **96 %** — ECE 3,4 %, 99 % sur les 80 % les plus confiants | catégorie 100 % (`app`), hard 88 % |

| 80 classes, vérité d'article (2026-08-29, `output/item_truth`, non publié) | corpus ticket refait : 50 216 lignes dont 85 209 libellés de caisse réels d'Open Prices, vérité par code-barres et non par enseigne ; 0 contradiction, 0 fuite T1-test | à mesurer | à mesurer |

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
