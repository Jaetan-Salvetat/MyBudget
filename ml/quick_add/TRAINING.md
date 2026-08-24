# Entraîner le modèle quick-add

Guide de bout en bout : de la moisson des connaissances au modèle déployé dans
l'app. À suivre tel quel pour chaque nouvelle version.

```
assets/categories.json                     ← source de vérité des 80 classes
        │
        ▼
knowledge/  ──►  dataset/entities.jsonl    ← ~28 600 entités du monde réel
        │
        ▼
generate_dataset.py  ──►  dataset/train.jsonl + eval.jsonl
        │
        ▼
train.py  ──►  output/best/                ← poids PyTorch
        │
        ├──►  eval_world.py                ← mémorisation vs généralisation
        ├──►  test_model.py                ← non-régression
        │
        ▼
export_onnx.py  ──►  output/model.onnx  ──►  tool/publish_model.sh
```

## 0. Prérequis

```bash
cd ml/quick_add
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
uv run python generate_dataset.py
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
uv run python train.py
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
uv run python eval_world.py    # connaissance monde, 294 cas écrits à la main
uv run python test_model.py    # non-régression sur eval_corpus.json, 157 cas
```

`eval_world.py` sépare deux questions que la moyenne confond :

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
| `test_model.py`, niveau `app` | ≥ 95 % |
| type (dépense/revenu) | 100 % |
| ECE | ≤ 5 % |

## 5. Exporter et déployer

```bash
uv run python export_onnx.py                    # → output/model.onnx (int8)
uv run python test_onnx.py                      # l'artefact livré, pas les poids
cd ../.. && ./tool/publish_model.sh             # asset versionné + release + lock
```

`test_onnx.py` rejoue les deux corpus à travers le graphe quantifié et compare
ses décisions à celles du modèle PyTorch. Un écart de quelques cas sur 451 est
le bruit normal de l'int8 ; un effondrement signale une quantification ratée, et
c'est la seule occasion de le voir avant les utilisateurs.

`publish_model.sh` régénère le tokenizer binaire, dépose
`assets/models/model_v<N+1>.onnx`, crée la release GitHub et réécrit
`tool/model.lock`. Le nom de l'asset est lu dans le manifeste par
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
5. ajouter des cas dans `eval_world.json` — `test_world_corpus_covers_every_active_class`
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
Après ajout : `python -m knowledge.build`, `python generate_dataset.py`,
`python train.py`.

## 8. Pistes non explorées

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

## 9. Journal

| Version | Données | `eval_world` | `eval_corpus` |
|---|---|---|---|
| 75 classes (2026-08-21) | 2 172 exemples écrits à la main, augmentation ×8 | 20 % sur des marques hors corpus | 97 % (labels réalignés) |
| 80 classes, itération 1 (2026-08-23) | 28 668 entités, 124 175 exemples, 5 epochs | **93 %** — couverture 98 %, mémorisation 94 %, type 100 %, récurrence 90 %, ECE 3,5 % | catégorie 97 %, récurrence 93 % |
| 80 classes, itération 2 (2026-08-24) | + récurrence déduite de la formulation, marques manquantes, mots de boulangerie | **96 %** — couverture 100 %, type 99 %, récurrence 95 %, ECE 3,5 %, **100 % de justesse sur les 80 % les plus confiants** | catégorie **99 %**, type 100 %, récurrence 98 % |

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
