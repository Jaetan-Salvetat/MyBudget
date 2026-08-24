# Scan local — étude OCR + structuration

Objectif : passer d'une photo de ticket à des données fiables (articles, prix,
remises, total, date) 100% on-device, avec un signal de confiance exploitable.
La catégorisation (BERT) est hors scope de cette étude.

## Verdict (2026-08-24)

Architecture retenue, chaque étage mesuré :

```
photo → ML Kit → déskew + clustering → [structuration] → checksum
                                                          ├─ OK (88%) → BERT → validation directe
                                                          └─ échec → escalade cloud (si clé) → re-checksum
                                                                     └─ sinon écran de confirmation pré-rempli
```

- **V1** : `[structuration]` = règles géométriques (0,17 correction/ticket,
  0 invention, 0,3s, gratuit, offline) ; escalade cloud = flow VLM existant
  avec un modèle classe Gemini Flash (0,00 correction/ticket mesuré).
- **V2** : `[structuration]` devient un **classifieur de lignes** entraîné
  sur le golden — apprend les formats inconnus sans pouvoir inventer un
  montant — le jour où il bat les règles sur le bench. Interface identique.
- Éliminé par les données : OCR à entraîner, modèle end-to-end image→JSON
  embarqué, LLM génératif on-device (voir benchmark plus bas).

Mesures sur 120 tickets synthétiques français (ground truth exact) + 7 tickets
réels, exécutées sur Pixel 8 Pro et émulateur (sorties identiques) :

| Niveau | Recall articles | Précision | Remises | Checksum |
|---|---|---|---|---|
| clean (scan net) | 100% (344/344) | 100% | 58/58 | 40/40 |
| photo (rotation, perspective, ombre, flou) | 100% (348/348) | 100% | 63/63 | 40/40 |
| hard (thermique pâli + froissé + flou fort) | 96,9% (372/384) | 100% | 71/72 | 35/40 |

Tickets réels : 5/5 photos exploitables parfaites (dont un froissé et un
incliné). Les 2 échecs sont des thumbnails web 200-250px, résolution qu'aucune
photo de téléphone ne produit.

**Corpus français réel — dataset Find it! (ICPR 2018, L3i La Rochelle, miroir
Kaggle `srjpdl/findit-dataset`, copié dans `test/dataset_findit/`)** : seul
dataset public de tickets de caisse français. 1000 tickets T1 (500 train +
500 test) ~1752×3390, chacun avec sa **transcription texte exacte** — c'est
elle qui fournit le ground truth article par article (via
`transcript_truth.py` : même structuration appliquée au texte parfait,
fiable quand son propre checksum passe).

Résultat central, mesuré sur 250 vrais tickets à vérité fiable :

- **recall articles 97,9%** (1327/1356), **précision 99,0%**
- **0 article faux sur les tickets auto-validés** — les 13 divergences sont
  toutes sur des tickets flagués par le checksum → écran de confirmation
- auto-validation stricte : ~74% (ce corpus est un pire-cas : tickets
  thermiques de 2017 déjà pâlis, formats profonds type cantine
  subventionnée, balance de marché, promo Yves Rocher)

Le retry avec prétraitement (autocontrast + unsharp + upscale) récupère ~10%
des échecs. Le niveau « photo correcte d'un ticket frais » est encadré par le
tier synthétique photo (100%). Bonus : sur 15 tickets falsifiés du contest de
fraude, le checksum rejette ceux dont les montants sont incohérents.

Autres datasets évalués et écartés : SROIE/SRD (anglais), CORD (indonésien),
ReceiptSense/CORU (arabe-anglais), XFUND-fr (formulaires, pas des tickets),
Shaip 15.9k reçus 5 langues dont FR (commercial payant). Rien d'autre de
public en français.

Corpus web US (40 photos ExpressExpense SRD haute résolution + 2 FR Wikimedia) :
23/42 auto-validés, zéro faux positif vérifié à l'œil. Échecs = hors-domaine
(vocabulaire US `Food`/`TL`/`CC`, tickets longs froissés, photo à deux tickets,
avis de rappel → 0 article, comportement juste).

Latence OCR Pixel 8 Pro : médiane 312ms, p95 443ms.

## Benchmark des « cerveaux » de structuration (2026-08-24)

Trois candidats, même entrée mesurée, mêmes 250 tickets réels à vérité
terrain, même métrique — corrections utilisateur par ticket :

| Cerveau | Corr./ticket | Articles faux | Hallucinations | Latence |
|---|---|---|---|---|
| Règles + ML Kit (local, gratuit) | 0,17 (88% à zéro) | 3,1% | 0 (structurel) | 0,3s Pixel |
| Gemma 3n E2B sur texte OCR (classe on-device, 2GB) | 0,80 | 18% | oui (montants doublés/inventés) | 6,4s sur Mac M |
| **Gemini 3.7 Flash sur image (cloud)** | **0,00 (250/250)** | **0/1356** | **0** | ~6s, ~0,08¢/scan |

Conclusions :
- Le flow photo→VLM→JSON est **parfait avec un modèle de classe cloud** — et
  c'est déjà le flow du scan distant existant, il suffit d'un bon modèle.
- La même idée **embarquée** (2GB) est pire que les règles ET hallucine :
  la « compréhension » ne survit pas à la taille on-device aujourd'hui.
- Le run Gemini valide aussi la vérité terrain (accord indépendant 250/250).

Sondes « capacité vs entraînement » (50 tickets, même protocole) :

| Variante | Corr./ticket | Inventions de chiffres |
|---|---|---|
| gemma3n:e2b base | 0,70 | 5 |
| gemma3n:e2b + few-shot | 0,46 (−34%) | 4 |
| gemma3:4b (2× plus gros) | 1,28 (pire) | 18 |

Lecture : les erreurs de *tâche* (mauvaise colonne, doublage quantité,
oublis ≈ 88% des erreurs) cèdent à l'entraînement (few-shot −34%, un
fine-tuning ferait mieux). Les **inventions pures de chiffres ne cèdent ni
aux exemples ni à la taille** — elles sont structurelles au décodage
génératif (quantization Q4 comprise). Un génératif on-device fine-tuné
resterait donc au-dessus de zéro invention, notre barre. Si un « modèle qui
comprend » doit tourner en local un jour, c'est un **classifieur de lignes**
(sortie = étiquettes, montants recopiés de l'OCR, hallucination
structurellement impossible), entraînable sur le golden.

## Golden dataset

`test/golden/T1-{test,train}/` : 1000 tickets FR annotés (enseigne, date,
total, articles/prix/remises) par Gemini 3.7 Flash sur image, dont **734
double-validés** par accord avec l'extraction depuis transcription (chaîne
indépendante) ; 8 désaccords audités = conventions de représentation, zéro
erreur de montant. Sert de référence gratuite à tous les benchmarks et
d'assiette d'entraînement. Coût de construction : ~0,60 $.

Architecture qui en découle : **local d'abord** (ML Kit + structuration +
checksum : gratuit, offline, privé, 88% zéro-correction, jamais faux en
silence) → **escalade cloud sur échec de checksum** (le tail des formats
exotiques → 100%), la sortie cloud repassant par le même checksum. Le choix
local/cloud devient un réglage produit (privacy, clé API), plus un débat
technique. Note : la Batch API OpenRouter (-75%) est text-only, les images
passent en sync.

## Les trois découvertes qui conditionnent l'architecture

1. **La précision est structurellement à 100%.** Le pipeline ne sort jamais un
   prix faux : les erreurs sont des articles manqués, jamais des montants
   inventés (contrairement à un modèle génératif). Les chiffres imprimés
   survivent bien mieux que les lettres à la dégradation.

2. **Le ticket contient sa propre somme de contrôle.** `Σ(articles − remises)
   = total imprimé` détecte 100% des extractions imparfaites sur nos corpus.
   C'est le signal de confiance produit : checksum OK → validation directe,
   sinon écran de vérification.

3. **Le déskew est obligatoire.** ML Kit lit très bien un ticket incliné, mais
   ses boîtes sont en coordonnées image : à 4° d'inclinaison la colonne des
   prix dérive d'1,5 ligne et les prix s'apparient au mauvais article. Rotation
   des centres de boîtes par l'angle médian (fourni par ML Kit) → recall photo
   passe de 87% à 100%.

## Pièges rencontrés (à reproduire dans l'implémentation Dart)

- Ne jamais utiliser les lignes/blocs de ML Kit : re-clusteriser les *éléments*
  (mots) par chevauchement vertical après déskew.
- Prix éclatés par l'OCR : `-1, 00`, `5. 16` (fusion des fragments adjacents),
  `54 50` sur les totaux en gras (recollage restreint aux lignes TOTAL, sinon
  les numéros de fax deviennent des prix).
- Points de conduite Carrefour (`....14,90`), suffixes `€`/`EUR`, séparateur
  décimal `.` ou `,`.
- Lexiques (remise, total, stop) à matcher aussi sur texte compacté
  (`Monna ie`, `TOTALA PAYER`) mais seulement pour les entrées ≥5 caractères
  (sinon `HT` matche dans `MENTHE`).
- Remise = prix négatif rattaché à l'article précédent, ou libellé *commençant*
  par le lexique — `(promotion)` dans un nom d'article n'est pas une remise.
- Entrées courtes du lexique en frontière de mot obligatoire : `TEL` matchait
  dans `TORTELL.PESTO` et supprimait des articles.
- Sous-totaux par rayon (`TOTAL ALIMENTAIRE`, `TOTAL BEAUTE`) : le total à
  payer est le DERNIER montant « total » du ticket, pas le premier ; les
  articles s'arrêtent à cette ligne (tue aussi les pubs fidélité post-total).
- Ligne CB/CARTE = référence de checksum de secours UNIQUEMENT si aucun total
  n'est lu — sinon elle crée des faux positifs sur extraction incomplète.
- Total soudé au libellé par l'OCR (`TOTAL A PAYER14.59€`) : regex embarquée
  sur la ligne entière en secours.
- `T.V.A.10%` avec points échappe au lexique → variante sans points dans le
  matching, sinon la ligne TVA devient un article et double la somme.
- `HT` interdit en stop word : il tue `75CL HT MEDOC` (Haut-Médoc) ; les
  lignes TVA/TOTAL HT sont déjà couvertes par TVA et TOTAL.
- Format code-barres bricolage (`3177810004089 3.13 15.65 2` sous le libellé) :
  ligne 100% numérique avec un code 8-14 chiffres → rattacher au libellé
  précédent.
- Prix mutilés `e3.16e` (strip des lettres € des deux côtés) et soudés
  `SSP2.49€` (préfixe lettres ≤5 uniquement, sinon les numéros de version
  `V.2.16.0.70` deviennent des prix).
- Retry avec prétraitement (autocontrast + unsharp + upscale 2400px) quand le
  checksum échoue : récupère ~10% des échecs pour une seconde passe OCR.
- Ligne quantité (`3 X 1,33   3,99`) : le libellé est sur la ligne précédente,
  le prix de droite est le montant total.
- Dates éclatées (`202 6`, `o9`) : compacter et normaliser o→0 avant regex ;
  formats `/` et `.`.
- R8/proguard : le plugin ML Kit référence les recognizers chinois/devanagari
  absents ; `-dontwarn` requis, et vérifier le release build sur device (le
  shrinking a produit un NPE runtime en plus de l'erreur de build).

## Limite connue

Froissage + fondu forts : deux lignes adjacentes peuvent se chevaucher
verticalement et fusionner au clustering (5/40 en hard, 0/80 ailleurs, toujours
signalé par le checksum). Piste si besoin : clustering par colonne avec suivi
local de pente, ou classifieur de lignes léger — à ne faire que si les photos
réelles le justifient.

## Prochaines étapes (plan validé)

1. **Portage Dart** du pipeline local (`lines.py` + `structure.py`, ~400
   lignes ; spec = `test_structure.py` + bench golden) ; sortie vers
   `ReceiptScanResultModel` — écran d'édition et `validateAndCreate`
   inchangés. Scan local par défaut : sans clé API, sans cooldown, offline.
2. **Escalade cloud** sur échec de checksum : réutiliser le service distant
   existant (clé perso), re-checksum sur sa sortie.
3. **Classifieur de lignes (V2)** : entraînement sur golden + synthétique,
   critère d'entrée = battre 0,17 correction/ticket sur le bench.
4. **BERT** sur les libellés extraits — augmentation « style ticket » du
   dataset quick-add, calibrée sur les 1000 tickets réels du golden.
5. Fil rouge : valider sur des photos fraîches prises au Pixel (le corpus
   FindIt est un pire-cas scanné, pas le scénario nominal).

## Contenu

- `test/harness/` — app Flutter qui passe des images dans ML Kit et dump le
  JSON complet (mots, boîtes, confiances, angles). Deux sources : images
  poussées via `adb push` dans `files/input/` (prioritaire, aucun rebuild)
  ou `assets/corpus/` ; `adb pull` de `files/results/`.
- `test/analysis/` — clustering (`lines.py`), structuration (`structure.py`)
  + tests (`test_structure.py`), générateur synthétique (`receipt_content.py`,
  `receipt_render.py`, `generate_corpus.py`), scoring synthétique
  (`score.py`), vérité depuis transcriptions (`transcript_truth.py`),
  benchmarks LLM/VLM (`llm_structure.py`, `bench_llm.py`, `bench_gemini.py`,
  `probe_capacity.py`), construction du golden (`annotate_golden.py`).
- `test/golden/` — **golden dataset committable** : 1000 annotations JSON.
- `test/dataset_findit/` — dataset Find it! (img + txt, gitignoré) ;
  `test/corpus_synthetic/` — 120 tickets générés + ground truth ;
  `test/corpus_fr*/`, `test/corpus_web/`, `test/corpus/` — sélections
  d'images ; `test/results/` — sorties OCR par device + caches LLM
  (tout gitignoré sauf golden).

## Datasets : sources et reconstruction

Les images ne sont **pas versionnées** (poids ~2GB + licence FindIt
recherche-only, redistribution interdite) ; seules les annotations golden le
sont. `test/fetch_datasets.sh` reconstruit tout :

| Dataset | Source | Licence |
|---|---|---|
| Find it! (1000 tickets FR + transcriptions) | officiel : http://findit.univ-lr.fr/download-the-dataset/ (formulaire) ; miroir : `kaggle datasets download srjpdl/findit-dataset` | recherche, citer Artaud et al. ICPR 2018 |
| ExpressExpense SRD (200 photos US) | https://expressexpense.com/large-receipt-image-dataset-SRD.zip (MD5 `c8eb0f2d286da5ab742e7a5b59f15147`) | MIT, attribution |
| Wikimedia Commons (2 tickets FR) | `Special:FilePath` — voir fetch_datasets.sh | libres |
| Synthétique (120 tickets + ground truth) | `analysis/generate_corpus.py` (seed 42, déterministe) | interne |

Les sélections dérivées (`corpus_fr`, `corpus_fr_big`, `corpus_web`) se
reconstruisent à l'identique via `analysis/rebuild_corpora.py` (mêmes ids,
mêmes noms de fichiers → caches et benchs restent comparables).

Reproduire les mesures : l'OCR device se relance en poussant les images dans
`files/input/` du harnais (`adb push`), les benchs se rejouent gratuitement
depuis les caches de `test/results/` et le golden.
