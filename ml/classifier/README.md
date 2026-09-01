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
        ├──►  evaluation/hard.py                ← les cas durs des deux entrées, par axe
        │
        ▼
training/export_onnx.py  ──►  output/best/model.onnx  ──►  publish.sh
```

`serving/` porte le contrat d'entrée/sortie du modèle : `normalize.py` a son
miroir exact dans `ml/scan/pipeline/lib/src/normalize.dart`, vérifié par la
fixture de parité, et `contract.py` tient l'ordre des classes. Il n'y a rien
d'autre à y mettre — depuis que chaque article se classe seul, l'app n'a plus
de décision à porter après le modèle (§8).

### L'ordre des classes est un contrat, et il s'est cassé en silence

**`assets/categories.json` est la seule source de vérité, mais quatre artefacts
en dépendent par leur position, pas par leur nom :** les poids entraînés
(`num_categories` sorties), l'ONNX publié, `dataset/*.jsonl` où chaque exemple
range sa classe dans un entier, et `QuickAddLabels.categories` côté Dart qui
retraduit l'argmax. Insérer une classe décale tout ce qui la suit dans les
quatre.

Le 31 août, `finance.assurance_autre` a été insérée à l'index 46 et
`famille_education.enfant` à l'index 56. Rien n'a levé d'erreur : l'argmax
restait valide, seule sa traduction mentait. `evaluation/hard.py` est passé de
**87,9 % à 59,7 %** sans qu'un seul poids bouge, l'axe `revenu` à 2,5 % — les
seize classes de revenus sont toutes au-delà de l'index 56, donc toutes
décalées de deux. Le diagnostic se lit dans la forme des erreurs, jamais dans
la moyenne : `voyage.hebergement` répondait systématiquement
`famille_education.enfant`, sa voisine deux crans plus tôt.

Le corpus portait la même dérive et sans bruit : `receipts_train.jsonl`
enseignait `voyage.activite_visite` là où il voulait dire `divers.animaux`.
Réentraîner sur un corpus périmé aurait produit un modèle correctement aligné
sur des classes fausses.

Une dérive muette ne s'attrape que par une vérification de forme, donc il y en
a une à chaque frontière :

| Où | Ce qui est vérifié | Quand ça mord |
|---|---|---|
| `BudgetClassifier.__init__` | `num_categories` contre la taxonomie | tout chargement de poids, entraînement comme évaluation |
| `read_jsonl` | le repère `*.labels.json` écrit par les générateurs | à l'ouverture de tout corpus d'entraînement |
| `tests/test_model_contract.py` | l'ONNX publié dans `assets/models/` | à chaque `pytest` |
| `tests/test_model_contract.py` | `QuickAddLabels.categories` contre la taxonomie | à chaque `pytest` |
| `QuickAddClassifierService.classify` | le nombre de classes rendu par l'ONNX | à l'exécution, dans l'app |

Le garde-fou Dart existait déjà et c'est le seul qui a tenu : l'app levait une
exception au lieu de proposer une mauvaise catégorie. Côté Python il n'y avait
rien, et c'est ce qui a laissé mesurer et publier trois artefacts périmés.

**Ce que ça impose.** Ajouter une classe à `assets/categories.json` n'est jamais
une modification isolée : il faut rejouer `knowledge.build`, les deux
générateurs de corpus, l'entraînement et l'export. Tant que ce n'est pas fait,
`pytest` reste rouge sur `test_model_contract`, et c'est voulu.

## 0. Prérequis

```bash
cd ml/classifier
uv sync                 # environnement Python
uv run python -m pytest # 174 tests, < 20 s, aucun accès réseau
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

**La grammaire avant le vocabulaire.** Les sept formes ci-dessus ne produisent
que du syntagme décoré. Mesuré sur le corpus qu'elles rendaient : médiane
**4 mots**, p90 7, et **5 % seulement** des exemples atteignaient 8 mots — quand
l'utilisateur, lui, en tape 8 de médiane. Sur 124 000 exemples, pas une phrase à
verbe conjugué en dehors des 47 préfixes figés. L'axe `phrase_libre` de
`evaluation/hard.py` le payait 60,5 %, contre 83 % ailleurs.

C'est aussi ce qui interdit d'apprendre l'argot. « zinc » vaut bar, café ou
avion ; « mazout » fioul ou gazole ; « baille » eau ou bateau. Ce qui tranche,
ce sont les mots autour — et un syntagme de quatre mots n'a pas la place de les
porter. Moissonner du vocabulaire familier dans un corpus de cette forme
importerait l'ambiguïté sans sa résolution, et `drop_contradictions`
supprimerait justement les termes polysémiques.

`FRENCH_EXPENSE_SENTENCES` et `FRENCH_INCOME_SENTENCES` portent donc 42 cadres à
verbe, complétés dans 45 % des cas par une queue de phrase (`FRENCH_TAILS`) qui
allonge sans rien dire de la classe — exactement ce que le modèle doit apprendre
à ignorer. L'entité y arrive toujours après un verbe ou une préposition : c'est
la seule position lisible pour une enseigne comme pour un nom commun, sans rien
savoir de son genre. Un tirage sur trois passe par un cadre.

| | avant | après |
|---|---|---|
| exemples d'entraînement | 124 345 | **172 426** |
| longueur médiane | 4 mots | 4 mots |
| p90 / max | 7 / 15 | **10 / 23** |
| exemples de 8 mots ou plus | 5,0 % | **18,3 %** |

La médiane ne bouge pas, et c'est voulu : deux tirages sur trois restent du
syntagme court, parce que c'est ce que les gens tapent le plus. Ce qui change
est la queue de distribution, là où il n'y avait rien.

Ordre de grandeur attendu : ~172 000 exemples d'entraînement, ~10 700
d'évaluation, entre 850 et 9 000 exemples par classe.

**Une limite connue de la coupe :** elle se fait par entité, jamais par texte,
et deux entités différentes peuvent produire la même surface décorée
(« abonnement musique », « abo vol »). 3,4 % des textes d'évaluation existent
aussi côté entraînement pour cette raison — c'était 4,2 % avant l'ajout des
cadres. Le nom, lui, ne traverse jamais
(`test_split_never_lets_a_name_cross_sides`).

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
uv run python -m evaluation.hard            # les cas durs des deux entrées, par axe
```

### Le corpus dur, et pourquoi les autres mentaient

`world.py` annonce 95 %, `quick_add.py` 98 %, et l'app ne rend visiblement pas
ça. Les deux corpus expliquaient l'écart à eux seuls : écrits à la main dans le
vocabulaire de `corpus/quick_add/build.py` — les mêmes préfixes, les mêmes
suffixes, les mêmes contextes — ils mesuraient le gabarit du générateur. Côté
scan c'est pire et plus simple : **805 des 1 077 articles de `receipts.json`
sont `alimentation.supermarche`**, 17 classes sur 79 sont représentées, la
restauration en compte **zéro**. Répondre « supermarché » à tout y valait déjà
75 %.

`evaluation/hard.py` lit deux corpus écrits contre ces deux dérives :

| Corpus | Cas | Ce qu'il tient |
|---|---|---|
| `data/hard_quick_add.json` | 827 | 81 classes sur 81, **au moins 10 cas chacune**, aucune au-dessus de 6 %, 13 axes |
| `data/hard_receipts.json` | 159 | 22 classes, dont les 62 que le golden ne mesure sur aucun article |

### Une moyenne d'axe ne dit pas si le modèle est bon

La cible est « plus de 95 % de succès sur tout type de dépense et d'entrée ».
Elle porte sur **chaque classe**, et le corpus ne savait pas la lire : à 373
cas pour 81 classes, vingt classes en portaient deux ou moins. Une classe à
deux cas ne rend que 0, 50 ou 100 % — `aide_allocation.chomage`,
`salaire.retraite`, `voyage.activite_visite`, `numerique.ia` n'étaient pas
mesurées, elles étaient tirées à pile ou face. Le plancher de dix cas par
classe est ce qui rend le seuil opposable, et `report_by_class` n'affiche que
ce qui reste en dessous : la liste est le reste à faire, et elle est vide le
jour où le modèle est bon.

**Trois axes manquaient, tous les trois quotidiens.** Le corpus écrivait un
français soigné que personne ne tape dans un champ rapide :

| Axe | Ce qu'il mesure | Exemple |
|---|---|---|
| `abrege` | le télégraphique du champ rapide | « coiff », « retrait 50 », « permis code » |
| `releve_bancaire` | le libellé de relevé recopié tel quel | « PRLV SEPA ENGIE », « VIR SEPA CAF APL » |
| `enumeration` | une liste d'articles, sans verbe ni enseigne | « cahiers stylos et colle » |

`releve_bancaire` est le plus proche de l'usage réel et le plus absent de
l'entraînement : le générateur écrit des syntagmes décorés, jamais les
majuscules sans accent d'un relevé, alors que recopier sa banque est une des
façons les plus courantes de saisir une dépense passée. Le pipeline de saisie
retire la date et le montant avant le modèle, donc « CB CARREFOUR MARKET 31/08 »
lui arrive comme « CB CARREFOUR MARKET » : c'est cette forme-là qui est écrite
dans le corpus.

Les axes ne sont pas décoratifs : c'est la seule lecture qui désigne où
investir. Relevé du modèle livré, catégorie stricte — **mesuré sur les 373 cas
d'avant le 1er septembre**, donc sans les trois axes ajoutés depuis et sans le
plancher par classe ; les colonnes ne se comparent qu'entre elles :

| Quick-add | v13 livré | + cadres | **+ correctifs** | Scan | v13 | **v2** |
|---|---|---|---|---|---|---|
| `sans_entite` | 90,9 % | 92,7 % | **94,5 %** | `confusable` | 88,6 % | **91,4 %** |
| `commerce_local` | 88,6 % | 88,6 % | **94,3 %** | `hors_alimentaire` | 76,6 % | **78,1 %** |
| `contexte` | 91,1 % | 93,3 % | **93,3 %** | `abrege` | 83,3 % | 76,7 % |
| `marque_nue` (témoin) | 90,0 % | 85,0 % | **90,0 %** | `restauration` | 60,0 % | **63,3 %** |
| `recurrence` | 73,5 % | 79,4 % | **88,2 %** | **ensemble** | 77,4 % | **78,0 %** |
| `revenu` | 85,0 % | 85,0 % | 85,0 % | | | |
| **`phrase_libre`** | **60,5 %** | **60,5 %** | **84,2 %** | | | |
| `homographe` | 81,1 % | 78,4 % | **83,8 %** | | | |
| `chiffre` | 86,7 % | 90,0 % | 83,3 % | | | |
| `argot` | 82,1 % | 84,6 % | 79,5 % | | | |
| **ensemble** | **83,1 %** | 84,2 % | **87,9 %** | | | |

Deux leviers, deux effets nets. **Retirer l'amplification des marchés
étrangers** — 11 360 des 28 709 entités de `nsi` et `wikidata` gardent leur nom
et rien de plus — divise par plus de deux le poids de `loisirs.livre_presse`
(9 000 exemples au plafond, 3 726 après) et lui retire son rôle de classe où
tombe tout syntagme inconnu. **Le lexique de groupes verbaux**
(`corpus/quick_add/verbs.py`, 144 clauses sur 60 classes) rend à `phrase_libre`
les 23,7 points qui lui manquaient : `lexicon.py` apprenait que des noms portent
une classe, rien n'apprenait qu'une action en porte une.

Ce que ça coûte : `argot` recule de 2,6 points et `chiffre` de 3,4, l'abrégé du
scan de 6,6. Le corpus a perdu 20 000 exemples, et ce sont les axes les plus
courts — un mot d'argot, une référence produit, un libellé tronqué — qui payent
la coupe.

**À lire avec réserve.** Le lexique verbal a été écrit *après* avoir constaté
l'échec de `phrase_libre`. Aucune de ses phrases n'y est recopiée —
`test_verb_phrases_never_copy_the_hard_corpus` l'interdit, et il a mordu dès la
première écriture — mais il vise la même capacité, et cet axe n'est plus une
mesure aveugle. Le confirmer demande un lot de phrases neuves.

Le rapport sépare aussi ce que le modèle a retenu de ce qu'il déduit — 93,9 %
sur les 49 cas présents tels quels dans `train.jsonl`, **81,5 % sur les 324
autres**. Le partage se calcule au lancement, jamais dans le JSON : écrit dans
le corpus, il vieillirait au premier `corpus.quick_add.build`.

Ce que le corpus dur a rendu visible et qu'aucun autre ne voyait :

- **la phrase libre s'effondre.** « on a mangé sur le pouce entre deux
  rendez-vous », « j'ai fait remplir le réservoir avant de partir » : le
  générateur n'écrit que des syntagmes décorés, jamais une phrase à verbe
  conjugué, et le modèle n'en a vu aucune ;
- **la restauration de ticket n'était pas mesurée du tout.** 60 % sur des
  libellés que l'entraînement couvre pourtant à 5 258 lignes ;
- **deux classes-aimant absorbent l'inconnu.** Sur 99 erreurs,
  `alimentation.supermarche` en prend 27 et `loisirs.livre_presse` 12 — cette
  dernière parce que 1 224 de ses 1 467 entités sont des titres de presse
  Wikidata du monde entier (« Kyunghyang Shinmun », « 24 sata »). La classe est
  devenue le sac où tombe tout syntagme nominal inconnu ;
- **treize mots-outils français sont des entités de la base** : `de`, `du`,
  `et`, `je`, `les`, `ou`, `tu` viennent de codes IATA Wikidata (Condor,
  Ethiopian, Tunisair), `avec`, `plus`, `son`, `ta`, `tous` d'enseignes NSI et
  d'une marque Open Food Facts. Chacune produit ses formes de surface à
  l'entraînement ;
- **la base se trompe parfois** : `nike air max` y est `shopping.electronique`,
  `galaxy` `alimentation.supermarche`. Le modèle répond alors juste selon ses
  données et faux selon l'utilisateur.

### Où en est le modèle face à la cible (2026-09-01, `output/run_v3`)

Corpus reconstruit sur 82 classes, 5 epochs, meilleur checkpoint à l'epoch 3.
Le réentraînement était obligatoire — pas pour gagner des points, pour exister :
les deux classes ajoutées n'avaient aucun exemple.

| Mesure | v13 livré | **v3** |
|---|---|---|
| entités jamais vues, catégorie stricte | 66,3 % | **75,9 %** |
| mémorisation (`world.py`) | 95 % | 95 % |
| ECE | 3,4 % | **2,8 %** |
| cas durs, **corpus du 31 août à l'identique** | 86,3 % | **86,3 %** |
| cas durs, **corpus de 827** | — | **81,1 %** |
| accord ONNX int8 / PyTorch | — | 99,1 % |

**La ligne à lire est la quatrième :** sur exactement les mêmes 380 cas, le
modèle n'a pas bougé. Ce que le réentraînement a rendu, c'est l'alignement — en
production le quick-add passe de « lève une exception à chaque saisie » à
86,3 %. Les 9,6 points gagnés sur les entités jamais vues viennent du corpus
reconstruit, pas de la recette.

**La cinquième ligne est celle qui compte, et elle est loin.** Sur le corpus qui
mesure vraiment : **12 classes sur 81 atteignent 95 %**. Les axes, du meilleur
au pire :

| Axe | strict | | Axe | strict |
|---|---|---|---|---|
| `abrege` | 97,5 % | | `argot` | 85,5 % |
| `contexte` | 91,9 % | | `chiffre` | 84,1 % |
| `releve_bancaire` | 86,1 % | | `commerce_local` | 80,5 % |
| `revenu` | 85,0 % | | `recurrence` | 80,0 % |
| `homographe` | 78,0 % | | `sans_entite` | 77,3 % |
| **`phrase_libre`** | **72,0 %** | | **`enumeration`** | **71,4 %** |

`releve_bancaire` à 86,1 % est la surprise : l'axe était aveugle — aucun libellé
de relevé n'existe dans l'entraînement — et le modèle y tient parce que le nom
d'enseigne porte tout (`PRLV SEPA ENGIE` se réduit à `engie`). `abrege` à
97,5 % dit la même chose : moins de mots, moins de bruit, et l'enseigne suffit.
Les deux axes qui s'effondrent sont ceux **sans entité du tout** —
`phrase_libre` et `enumeration` demandent de lire une intention, et rien dans le
corpus d'entraînement n'apprend ça au-delà des 144 clauses de `verbs.py`.

**Trois défauts nommés, par ordre de coût :**

1. **La direction de la transaction se trompe une fois sur vingt.** La tête de
   type rend 95,4 % d'ensemble mais **85,0 % sur l'axe `revenu`** : « le
   gestionnaire a reversé le loyer net » sort en dépense, « quittance du studio
   que je loue » en revenu. Le générateur écrit ses revenus avec des préfixes
   de revenu, donc la direction s'apprend au préfixe et pas au verbe — `reversé`,
   `encaissé`, `perçu`, `versé par` ne portent rien. C'est le défaut le plus
   cher : une erreur de catégorie se corrige d'un geste, une dépense comptée
   comme une entrée fausse le solde ;
2. **`loisirs.livre_presse` reste la classe-aimant** — 13 des 159 erreurs, sur
   des syntagmes nominaux qu'elle n'a aucune raison d'attirer (« pension du
   régime général », « indemnités journalières »). Le déplafonnement des
   marchés étrangers a réduit la classe sans lui retirer ce rôle ;
3. **Les seize classes de revenus se confondent entre elles.** `income` rend
   78,1 % contre 81,9 % pour `expense`, et les confusions sont systématiques :
   `remboursement_ami` absorbe tout ce qui contient « part de », `salaire.retraite`
   tout ce qui contient « pension ». `generalization.py` le confirme sur les
   entités jamais vues — `salaire.salaire_net` à 26 %, `salaire.freelance` à
   39 %, `exceptionnel.vente_occasion` à 37 %.

**Ce qu'il ne faut pas faire pour y répondre.** `phrase_libre` a déjà été
corrigé une fois en écrivant `verbs.py` après avoir constaté son échec, et
l'axe a cessé d'être une mesure aveugle. Écrire maintenant des gabarits de
relevé bancaire ou des tournures de revenu en visant ces axes referait la même
erreur en pire : le seul chiffre qui resterait honnête serait celui des entités
jamais vues. Le corpus d'entraînement doit gagner ces capacités par une source
indépendante — un lexique de verbes de direction construit sans regarder le
corpus dur, et une amplification des classes de revenus sur les entités déjà
moissonnées — et l'axe reste le juge, jamais le modèle.

### Le corpus dur est écrit sans faute, l'utilisateur ne tape pas sans faute

Restaient trois écarts entre 83,1 % et ce que l'app rend. Mesurés, deux sont
nuls et le troisième porte tout :

| | Cas durs quick-add |
|---|---|
| poids PyTorch, texte propre | 83,1 % |
| **ONNX int8**, texte propre | 83,4 % |
| ONNX int8, montant tapé puis retiré par le pipeline | 83,4 % |
| **ONNX int8, une faute de frappe** | **71,6 %** |

La quantification ne coûte rien et le pipeline de saisie non plus. Une seule
faute en coûte douze points, et `measure_typed_input` la mesure désormais axe
par axe — mêmes opérateurs que `robustness.py`, tenus à l'écart de ceux de
l'entraînement :

| Axe | propre | une faute | chute |
|---|---|---|---|
| **`argot`** | 82,1 % | **53,8 %** | **−28,2** |
| `chiffre` | 86,7 % | 70,0 % | −16,7 |
| `revenu` | 85,0 % | 72,5 % | −12,5 |
| `sans_entite` | 90,9 % | 81,8 % | −9,1 |
| `phrase_libre` | 60,5 % | 52,6 % | −7,9 |
| `marque_nue` | 90,0 % | 90,0 % | 0,0 |
| **ensemble** | **83,1 %** | **74,0 %** | **−9,1** |

L'argot s'effondre parce qu'il est court : « macdo », « kawa », « muscu » ne
survivent pas à la lettre qui ripe, là où « Boulangerie Lefèvre » garde assez de
matière. Le témoin `marque_nue` ne bouge pas d'un point — une enseigne apprise
par cœur résiste, ce qui est déduit non.

**Un bug de l'app est sorti de cette mesure, et il est corrigé.**
`PriceParserService` prenait le dernier nombre de la saisie pour le montant,
quel que soit ce qu'il désigne : sans prix tapé, 23 des 373 cas arrivaient
amputés au modèle — `Galaxy S24` → `Galaxy S`, `plein de SP98` → `plein de
SP`, `A10 péage` → `A péage`, `forfait 100 Go` → `forfait Go`. Sur ces 23
saisies la justesse tombait de 87,0 % à 73,9 %.

Deux règles générales suffisent, et aucune ne nomme un cas : **un nombre collé
à des lettres appartient au nom** (`SP98`, `A10`, `S24`, `W32`), **un nombre
suivi d'une unité est une quantité** (`100 Go`, `2 kg`, `12 mois`). Le symbole
monétaire collé reste un montant — `45€` est lu comme avant.

Reste `iPhone 15` : rien dans la forme ne le distingue de `carrefour 45`, et
c'est la seconde qui est la saisie courante. Le montant s'affiche et se
corrige, la catégorie non : le doute est tranché en faveur du montant, et cette
saisie-là arrive encore tronquée au modèle.

**Ce qu'un cas doit valoir pour entrer.** `tests/test_hard_corpora.py` tient
chaque règle ; les deux qui ont sauvé le corpus à l'écriture sont la fuite et la
vérité contestable. Vingt-deux libellés de ticket se retrouvaient mot pour mot
dans `receipts_train.jsonl` après normalisation — vingt et un portaient
d'ailleurs la même classe que l'entraînement, ce qui a confirmé la convention
suivie ; tous ont été réécrits. Sept cas quick-add ont été retirés faute de
vérité tranchée (« Krys nouvelles lunettes » — opticien ou parapharmacie ?
« sushis à emporter » — restaurant ou vente à emporter ?). Un cas qu'on ne
saurait pas trancher devant l'utilisateur ne mesure pas le modèle, il mesure
notre hésitation.

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
| mémorisation | `world.py` | ≥ 95 % |
| **entités jamais vues, catégorie stricte** | `generalization.py` | **> 75,9 %**, la valeur de `run_v3` |
| justesse sur les 50 % plus confiants | `generalization.py` | ≥ 93 % |
| niveau `app` | `quick_add.py` | ≥ 95 % |
| type (dépense/revenu) | `world.py` | 100 % |
| ECE | `world.py` | ≤ 5 % |
| une faute de frappe | `robustness.py` | chute < 10 points sous le propre |
| casse et accents | `robustness.py` | égal au propre, à 1 point près |
| **toute classe, quick-add** | `hard.py` | **> 95 %** — la cible produit, 12/81 aujourd'hui |
| **direction de la transaction, axe `revenu`** | `hard.py` | **100 %** — 85,0 % aujourd'hui |
| **cas durs quick-add, ensemble** | `hard.py` | **> 81,1 %**, la valeur de `run_v3` |
| **cas durs scan, ensemble** | `hard.py` | **> 73,6 %** |
| classes en sortie du modèle et de l'ONNX | `test_model_contract.py` | égal à la taxonomie, sans exception |
| phrase libre | `hard.py` | > 72,0 % |
| énumération | `hard.py` | > 71,4 % |
| restauration de ticket | `hard.py` | > 60,0 % |
| **cas durs, une faute de frappe** | `hard.py` | **> 69,8 %** |
| argot, une faute de frappe | `hard.py` | > 61,8 % |

La première ligne prime sur toutes les autres : un ensemble à 88 % qui laisse
`aide_allocation.bourse` à 40 % n'est pas un modèle à 88 % pour l'utilisateur
qui touche une bourse, c'est un modèle qui se trompe une fois sur deux. Les
lignes `hard.py` d'ensemble sont celles qui bougent quand l'app s'améliore : ce
sont les seules mesurées sur des formulations que le générateur n'écrit pas et
sur les classes que le golden ne contient pas. Aucun axe ne doit reculer, même
si l'ensemble progresse — une moyenne qui monte pendant qu'un axe tombe est un
déplacement de l'erreur, pas un gain.

La ligne qui décide côté connaissance reste celle des entités jamais vues : c'est la seule qui
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
**135 532 lignes, 86 095 libellés sans ambiguïté**.

**La limite est nette et il faut la connaître :** 98 % des libellés viennent de
`shop=supermarket` (97 785) et `shop=convenience` (16 202) — jardinerie 382,
pharmacie 378, bricolage 255, librairie 77. Open Prices règle la moitié
alimentaire et **ne dit rien** de la moitié où le modèle se plante :
restaurant, travaux, vêtements, mobilier. Un plat du jour et une planche de
contreplaqué n'ont pas de code-barres.

### Les deux bases qui manquaient (2026-08-29)

Le code-barres d'Open Prices n'était cherché que dans l'alimentaire et
l'hygiène-beauté. Les deux autres bases du projet Open Food Facts existent, et
ce sont exactement celles des classes les plus minces :

| Base | Produits FR étiquetés | Ce qu'elle couvre |
|---|---|---|
| Open Products Facts | 7 194 | entretien, presse, électronique, tabac, papeterie |
| Open Pet Food Facts | 2 072 | animalerie |
| Open Beauty Facts | 8 966 (6 000 lus avant) | hygiène-beauté |

Elles n'ont pas la même forme : l'alimentaire et l'hygiène-beauté sont publiés
en parquet sur Hugging Face, les deux autres n'existent qu'en CSV compressé sur
leur site. DuckDB lit les deux à distance, et `fetch_off.py` les fait sortir
sous la même paire de fichiers par base — rien en aval ne sait d'où une
catégorie est venue.

`products_slug` traduit la taxonomie d'Open Products Facts, qui est celle de
Google Shopping : une catégorie y porte toute son ascendance, du plus large au
plus fin. Les tags sont donc lus **à l'envers**, ce qui prend la catégorie la
plus précise que la table connaît et enjambe les feuilles qui ne décrivent
aucun commerce (`en:3-ply`, `en:160-sheets`). Un produit dont aucun tag ne
parle sort du corpus : 6 206 des 6 990 produits FR sont classés, et rien n'est
rangé au supermarché par défaut. Ce qui relève de l'alimentaire ou de la beauté
est rendu à la base qui en répond — deux tables pour la même question feraient
du dentifrice un produit de rayon d'un côté et un cosmétique de l'autre.

Open Pet Food Facts ne demande pas de table : la base entière est de
l'alimentation animale, et lire ses catégories ne servirait qu'à ranger
ailleurs les produits que ses contributeurs ont mal étiquetés.

Ce que ça déplace, corpus ticket d'entraînement :

| Classe | avant | après |
|---|---|---|
| `divers.animaux` | 477 | **2 425** |
| `loisirs.livre_presse` | 597 | **1 782** |
| `shopping.electronique` | 979 | **1 862** |
| `famille_education.fournitures` | 303 | **675** |
| `divers.tabac_jeux` | 427 | **646** |
| `famille_education.activites_enfants` | 343 | **497** |
| `sante_beaute.pharmacie` | 1 423 | 1 650 |
| `shopping.mobilier_deco` | 1 421 | 1 728 |
| **total** | **50 216** | **55 774** |

Côté Open Prices le gain est mince — 886 libellés de plus portent une vérité,
et **aucun article du golden n'en gagne une** : les tickets FindIt sont
alimentaires, et leurs lignes non alimentaires ne sont dans aucune des quatre
bases. Le trou de mesure du §8 reste entier ; ce chantier remplit le corpus
d'entraînement, pas le corpus d'évaluation.

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
Il moissonne les quatre bases : ajouter la cinquième se fait en ajoutant une
ligne à `DUMPS` et une table à `categories.py`.

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

### Ce que rendent les corpus refaits (2026-08-29)

Deux modèles entraînés sur la vérité d'article, mesurés sur les **mêmes** 548
articles T1-test — `receipts.json` n'a pas bougé d'un octet entre les deux :

| Variante | v13 (vérité d'enseigne) | ancien corpus | corpus enrichi |
|---|---|---|---|
| brut | 46,7 % / 59,3 % | 45,3 % / 55,3 % | 46,9 % / 54,6 % |
| minuscules | 49,3 % / 82,3 % | 64,2 % / 77,6 % | 63,1 % / 73,9 % |
| **normalisé** | **40,0 % / 83,2 %** | **65,0 % / 81,0 %** | **68,4 % / 81,9 %** |

Refaire la vérité vaut **+25 points** de strict ; les quatre bases produit en
valent **+3,4 de plus**, et font disparaître en normalisé les confusions
`supermarché → livre_presse` (23 cas) et `supermarché → animaux` (21) que le
modèle n'avait aucun vocabulaire pour éviter.

Ce n'est pas l'epoch de plus qui le rend : à epoch 4, l'ancien corpus menait sur
`eval_category_f1` (0,7541 contre 0,7453). Le modèle enrichi est différent, pas
plus cuit.

**Il échoue une porte, et il faut le savoir avant de publier :**

| Porte | ancien corpus | corpus enrichi | Cible |
|---|---|---|---|
| **`world` mémorisation** | 98 % | **95 %** | **≥ 97 % ✗** |
| entités jamais vues, strict | 75,8 % | 75,8 % | > 66,3 % ✓ |
| — à la famille près | 77,4 % | 77,2 % | > 68,7 % ✓ |
| 50 % plus confiants | 98,1 % | 96,6 % | ≥ 93 % ✓ |
| `quick_add` niveau `app` | 100 % | 100 % | ≥ 95 % ✓ |
| ECE | 2,4 % | 4,8 % | ≤ 5 % ✓ |
| casse et accents | — | 76,6 % = 76,6 % | égal au propre ✓ |

Le mécanisme est identifiable, pas mystérieux. Parmi les huit échecs de `world` :
`Nocibé parfum → alimentation.supermarche (94 %)`, `capsules Nespresso →
épicerie`. En passant Open Beauty Facts de 6 000 à 8 966 produits et en routant
le sous-arbre `personal-care` d'Open Products Facts vers `beauty_slug`, le
nombre de libellés **beauté rangés au supermarché** a bondi — ce qui est juste
pour une ligne de caisse et faux pour une enseigne tapée au quick-add.

C'est la contradiction du `baguette` du §8, dans l'autre sens, et
`drop_contradictions` ne la voit pas : elle ne compare que les lignes du corpus
ticket entre elles, jamais contre `train.jsonl`. **Étendre son arbitrage aux
deux corpus est le premier correctif à tenter.**

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
- **Arbitrer les contradictions entre les deux corpus, pas seulement dans le
  corpus ticket.** `drop_contradictions` ne compare que les lignes de
  `receipts_train.jsonl` entre elles. Un libellé que le corpus ticket range au
  supermarché et que `train.jsonl` range ailleurs passe les deux fois, et le
  modèle apprend la contradiction : c'est ce qui a coûté trois points de
  mémorisation `world` aux quatre bases produit (§8). C'est le premier poste à
  ouvrir avant de republier.
- **Vérité d'article pour le non-alimentaire.** Open Prices couvre le rayon
  courses et rien d'autre : plat de restaurant, quincaillerie, vêtement,
  mobilier n'ont pas de code-barres, et ce sont les classes où le modèle se
  trompe. Les quatre bases produit ont fourni le vocabulaire manquant à
  l'entraînement, mais **pas un article de mesure de plus** : les ~3 000
  libellés concernés du golden demandent une annotation, filtrée comme celle du
  tagger de rôles. C'est le premier poste à ouvrir : la mesure de §8 est juste
  mais aveugle sur ces classes.
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

| 80 classes, vérité d'article (2026-08-29, `output/item_truth`, epoch 4, non publié) | corpus ticket refait : 50 216 lignes dont 85 209 libellés de caisse réels d'Open Prices, vérité par code-barres et non par enseigne ; 0 contradiction, 0 fuite T1-test | **98 %** — ECE 2,4 %, entités jamais vues 75,8 % | catégorie 100 % (`app`), hard 88 % |

| 80 classes, quatre bases produit (2026-08-29, `output/four_bases`) | + Open Products Facts et Open Pet Food Facts, Open Beauty Facts déplafonné : 55 774 lignes, 86 095 libellés sans ambiguïté ; 0 contradiction, 0 fuite | **95 %** — ECE 4,8 %, entités jamais vues 75,8 % ; **sous la cible de mémorisation** | catégorie 100 % (`app`), hard 88 % |
| **82 classes, alignement rétabli (2026-09-01, `output/run_v3`, epoch 3)** | deux classes ajoutées à la taxonomie le 31 août sans rien reconstruire : poids, ONNX et corpus décalés de deux crans. Connaissance et deux corpus refaits sur 82 classes ; 154 962 + 50 000 exemples | **95 %** — ECE 2,8 %, entités jamais vues **75,9 %** | corpus dur porté à 827 cas : **81,1 %**, dont **12 classes sur 81 au-dessus de 95 %** |

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
