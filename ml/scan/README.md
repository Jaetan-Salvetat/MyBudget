# Scan local — étude OCR + structuration

Objectif : passer d'une photo de ticket à des données fiables (articles, prix,
remises, total, date) 100% on-device, avec un signal de confiance exploitable.
La catégorisation (BERT) est hors scope de cette étude.

## Verdict (2026-08-24)

**Décision produit : le scan est LOCAL ou CLOUD, réglage exclusif — jamais
d'escalade automatique.** Le mode cloud (flow VLM existant) ne bouge pas ;
tout ce dossier vise le mode local, qui doit être l'option recommandée
(cible ~99 % de validation directe sur tickets frais). Architecture du mode
local, chaque étage mesuré :

```
photo → ML Kit → déskew + clustering → règles → checksum OK → validation directe
                          │ échec ↓
                          prétraitement + 2e OCR → règles → checksum (garde-fou)
                          │ échec ↓
                          classifieur de lignes (V2) → re-checksum
                          │ échec ↓
                          écran de confirmation pré-rempli (échec DÉTECTÉ, jamais silencieux)
```

- **Règles** : géométrie + lexiques, 0 invention structurelle, ~0,4 s.
- **Classifieur de lignes (V2, actif)** : second avis gated par checksum —
  étiquette les lignes porteuses de prix (article/remise/total/paiement/
  bruit), montants recopiés de l'OCR, hallucination impossible. Il ne peut
  que sauver des tickets flagués, jamais corrompre un validé.
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

## Mode local — bench & calibration (2026-08-24)

L'instrument central est **`analysis/bench_local.py`** : il rejoue le flow
local complet (règles → retry → classifieur V2) depuis les dumps OCR d'un
run device — une modification de règles ou de modèle se mesure en secondes
sur 1000 vrais tickets, sans retoucher au téléphone. Métriques : validation
directe, faux auto-validés (la barre : 0 montant faux), corrections/ticket
en confirmation. `analysis/analyze_local_failures.py` classe chaque échec
(structuration / total non lu / montants absents de l'OCR / golden non
checksummable) pour dire où investir.

**Corpus de travail sain (2026-08-24)** : les tickets structurellement
ingagnables sont exclus des benchs via `test/golden/excluded.txt` (101
tickets : 52 golden non-checksummables — cantine subventionnée, balance —
et 49 aux montants absents de l'OCR, dont `t1test_68`, l'unique vrai faux
validé historique). Liste régénérable :
`analyze_local_failures.py device_flow --write-excluded` ; filtrée par
`load_tickets`, donc par tous les benchs. Le plafond du corpus restant est
100 % — chaque échec est attaquable côté règles/modèle.

État sur les 899 tickets FindIt du corpus sain (pire-cas : thermiques 2017
pâlis), vérité golden (historique mesuré sur les 1000 bruts, plafond 94,8 %,
avec 78,6 % au dernier état) :

| Étape | Checksum OK (sur corpus sain) | Faux montants validés |
|---|---|---|
| Règles + calibration (TUA, TOT, INCL, fallbacks, MERCI) | 79,9 % | 1* |
| **+ classifieur V2** | **85,5 %** | 2* |
| Restant : 130 — structuration + total non lu uniquement | | |

\* `t1train_1869` et `t1train_1657` : 1 correction chacun, golden
« gemini-seul » (non double-validé) — à auditer, probablement conventions.

Décisions de calibration issues du bench :

- **Garde-fou retry** : un retry dont la somme d'articles est inférieure à
  celle de la passe 1 est refusé même si son checksum passe (collision de
  substitution observée : article 9,90 perdu + total 22,45 lu 12,55).
- **Références de secours gated `total is None`** : table TVA (somme des
  TTC), compteur « N ARTICLE(S) » + ligne CB, total sans séparateur
  (« 2790 »), prix orphelin de fin de ticket. Un fallback ne doit JAMAIS
  outrepasser un total lu qui ne colle pas (faux positif observé sinon).
- Lexiques : `TUA` (V→U), `TOT` abrégé, `A RENDRE`, total « TVA INCL »
  non exclu, frontières de mot (`MERCI` matchait dans `COMMERCIALE`).
- Écartés par les données : tolérance 2 centimes, exemption colonne des
  prix négatifs, cross-check de totaux.

## Classifieur de lignes V2 (2026-08-24, actif)

`analysis/line_features.py` (32 features déterministes par ligne porteuse
de prix : géométrie, lexiques, contexte ±1 ligne — portables en Dart) +
`analysis/train_line_classifier.py` (HistGradientBoosting) +
`analysis/structure_ml.py` (structuration depuis les labels, re-checksum).

- **98,7 % d'accuracy lignes sur T1-test** ; +53 tickets sauvés sur 1000
  (+25 sur T1-test jamais vu à l'entraînement → généralise).
- L'étiquetage est automatique et c'est LA leçon : rôles joués par les
  règles sur les tickets checksum-validés (vérité confirmée) + labels
  correctifs alignés golden sur les échecs, lignes incertaines **exclues**.
  Étiqueter « ignore » une ligne d'article au montant abîmé par l'OCR
  apprend au modèle à jeter des articles (première version : 62 %
  d'accuracy pour cette raison).
- Branché en second avis : uniquement sur les tickets que règles+retry
  flaguent, sortie re-checksummée. Zéro faux montant introduit.
- À faire pour l'app : portage de l'inférence en Dart pur (arbres
  transpilables ou petit MLP à poids constants — pas de TFLite).

La spec d'implémentation app (mapping UI, messages d'erreur, invariants) :
**`VERIFICATION.md`**.

## Intelligence sans hallucination : décodage sous contrainte + V3 (2026-08-24)

Réponse à la crainte « le système est bête » sans LLM ni VLM : toute
l'intelligence porte sur **l'étiquetage** de lignes existantes, jamais sur
le contenu — les montants sont recopiés de l'OCR, l'hallucination est
structurellement impossible. Discipline : modèles et seuils calibrés sur
**T1-train**, T1-test intouché = seule mesure de généralisation.

| Étape (corpus sain, 899) | T1-train | T1-test | Faux (test) |
|---|---|---|---|
| Départ : règles + retry + V2 argmax | 85,4 % | 85,7 % | 0 |
| + décodage sous contrainte (`decode_constrained.py`) | 86,9 % | 87,5 % | 0 |
| + V3 (features arithmétiques, lexiques flous, trigrammes) | 89,4 % | 87,7 % | 0 |
| + lexiques paiement/total étendus + étiquetage correctif total/paiement | 91,1 % | 91,7 % | 3 |
| + invariants structurels (rien après la référence, négatif ≠ article) | 92,0 % | 92,4 % | 1* |
| **+ paiement en référence sans flip (vote de deux signaux)** | **92,5 %** | **92,6 %** | **1*** |

\* `t1test_1181` : paire subvention 14,12 / −14,12 à net zéro (format
cantine), aucun montant faux dans la somme. Total corpus : **832/899
(92,5 %)**, contre 769/899 (85,5 %) en début de chantier.

Les mécanismes, du plus rentable au moins :

1. **Le checksum devient un guide, plus seulement un juge**
   (`decode_constrained.py`) : le classifieur sort des probabilités par
   ligne ; on cherche l'étiquetage le plus probable dont Σ(articles −
   remises) tombe exactement sur une référence imprimée — subset-sum exact
   en centimes par programmation dynamique, `min_prob` 0,02 (jamais forcer
   un rôle que le modèle juge impossible), référence total à P ≥ 0,5.
   Invariants de ticket encodés dans l'espace de recherche : aucune ligne à
   0 centime en article, **rien ne compte après la ligne de référence**
   (la monnaie rendue après un paiement en espèces n'est jamais un
   article — cause des 3 faux observés avant), **un prix négatif n'est
   jamais un article**, un paiement ne sert de référence qu'en dernier
   recours et **sans aucun flip** (les articles selon l'argmax doivent
   tomber pile dessus : modèle + ligne imprimée contre un total lu faux).
2. **Le vrai goulot était l'étiquetage d'entraînement**, pas le modèle :
   l'étiquetage correctif sur tickets échoués n'attribuait jamais
   TOTAL/PAYMENT, donc le modèle n'avait jamais vu une ligne total garblée
   étiquetée total. Et le lexique paiement ne connaissait que la CB —
   espèces, chèque, paiement, règlement, perçu, reçu n'existaient pas ; NET
   A REGLER, DOIT, PRIX TTC, MONTANT TTC non plus côté total. C'est
   l'étape qui rapporte +4 points sur test.
3. **V3** (`line_features_v3.py`) : signaux agnostiques au format — ce
   prix est-il la somme d'un bloc au-dessus ? une fraction TVA/HT d'un
   autre prix ? la somme des remises précédentes (récap « avantages ») ?
   dupliqué ailleurs ? — plus similarité d'édition aux lexiques (résiste à
   `Tota1`, `TOT AL`, `LU.A`) et trigrammes hachés du libellé. Régularisé
   (early stopping, feuilles ≥ 20) pour des probabilités exploitables :
   log-loss test 0,26 → 0,07, lignes fausses à P ≥ 0,99 : 52 → 8. Le gain
   propre de V3 sur test est modeste (+1) mais il rend le décodeur
   efficace.

Diagnostic des 33 restants de test (`scratchpad`, reproductible) : 11 ont un
montant golden **jamais parsé** comme prix (`27C 27.90`, `€ 49 56`),
~15 une référence trop garblée pour tout lexique (`E SPECES 23.O0`,
`Cartes Berc1TES`, `DOLT`, `TO'AL`) ou nue (`61.59 EUR`), 3 des remises
informatives propres à un format (`Nouveau prix 49,90 -5,10`). Plus de
levier générique : la suite est côté parsing OCR, ou côté modèle de
séquence / encodeur layout-aware entraîné sur golden + synthétique.


## Portage Dart & banc on-device (2026-08-24)

- **`pipeline/`** : package Dart pur `receipt_pipeline` — portage de
  `lines.py` + `structure.py` + `flow.py`, 46 tests portés. Parité vérifiée
  champ à champ contre Python sur 699 dumps OCR (FindIt, enhanced, web,
  synthétique) : **0 divergence** (`analysis/check_parity.py` +
  `pipeline/tool/parity.dart`).
- **`test/harness/`** devient un banc à deux modes : « Suite complète »
  (images via `adb push` dans `files/input/`, flow local complet par ticket,
  dump OCR historique + section `flow`) et « Scanner un ticket » (photo →
  flow local → résultat structuré à l'écran). Le prétraitement retry
  (autocontrast + unsharp + upscale 2400 px) est embarqué en Dart.
- **`analysis/score_device_flow.py`** score un run de suite tel qu'exécuté
  sur le device : parité device ↔ Python par ticket, métriques vs golden.
  Nommage des images poussées : `t1test_<doc>.jpg` / `t1train_<doc>.jpg`.

Runs 1000 tickets golden : S9+ (2018) et Pixel 8 Pro — **OCR strictement
identique sur 99,7 % des images, 0 décision divergente** : le moteur ML Kit
est constant inter-devices, la seule variable réelle est la qualité de la
photo (capteur, focus). Latence pipeline S9+ : médiane 404 ms, p95 1,2 s.
Dumps : `test/results/device_flow[_pixel]/` (gitignorés), corpus de replay
de `bench_local.py`.

Parité connue : l'APK d'avant le fix des diacritiques a produit 1 dump
divergent (`t1train_790`, « TŤC ») — corrigé dans le package (table de
repli latin étendu-A), APK reconstruit.

## Golden dataset

`test/golden/T1-{test,train}/` : 1000 tickets FR annotés (enseigne, date,
total, articles/prix/remises) par Gemini 3.7 Flash sur image, dont **734
double-validés** par accord avec l'extraction depuis transcription (chaîne
indépendante) ; 8 désaccords audités = conventions de représentation, zéro
erreur de montant. Sert de référence gratuite à tous les benchmarks et
d'assiette d'entraînement. Coût de construction : ~0,60 $.

Note historique : l'étude avait d'abord conclu à une escalade cloud sur
échec de checksum ; la décision produit finale (2026-08-24) est **deux
modes exclusifs** — le local doit tenir seul (voir Verdict). Note : la
Batch API OpenRouter (-75%) est text-only, les images passent en sync.

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
  absents (`-dontwarn` pour le build) ET le shrinking strip des classes du
  recognizer → NPE runtime sur chaque `processImage` en release. Fix mesuré :
  règles keep `com.google.mlkit.**`, `com.google.android.odml.**`,
  `com.google.android.gms.internal.mlkit_vision_text_common.**`
  (cf. harness/android/app/proguard-rules.pro) ; parité release AOT vérifiée.

## Limite connue

Froissage + fondu forts : deux lignes adjacentes peuvent se chevaucher
verticalement et fusionner au clustering (5/40 en hard, 0/80 ailleurs, toujours
signalé par le checksum). Piste si besoin : clustering par colonne avec suivi
local de pente, ou classifieur de lignes léger — à ne faire que si les photos
réelles le justifient.

## Prochaines étapes

1. **Refactor du flow** : le classifieur + décodeur deviennent un étage de
   plein droit de `decide()` (Python puis Dart, inférence injectable côté
   Dart), étage cloud retiré du package Dart, sémantique « information
   affichée » partout (décision produit : **jamais de validation
   directe**, tout passe par l'écran d'édition, checksum = badge/bandeau).
2. Portage Dart : lexiques étendus (la parité Python↔Dart est **rompue**
   depuis l'extension des lexiques, à rétablir), features V3, inférence
   du classifieur (arbres transpilés, pur Dart), décodeur DP.
3. Au-delà de 92,5 % : parsing OCR des montants abîmés, puis modèle de
   séquence / encodeur layout-aware (classe BERT, entraîné sur golden +
   synthétique) — voir section « Intelligence sans hallucination ».
3. **Intégration app (mode LOCAL uniquement)** : brancher `receipt_pipeline`
   (sans clé API, sans cooldown, offline), sortie vers
   `ReceiptScanResultModel` — écran d'édition et `validateAndCreate`
   inchangés. Le mode cloud existant ne bouge pas. Spec : `VERIFICATION.md`.
4. **BERT** sur les libellés extraits — augmentation « style ticket » du
   dataset quick-add, calibrée sur les 1000 tickets réels du golden.
5. Fil rouge : valider sur des photos fraîches prises au téléphone via le
   mode « Scanner un ticket » du harnais (le corpus FindIt est un pire-cas
   scanné, pas le scénario nominal — la capture app devra soigner
   résolution/focus, seule vraie variable inter-devices).

## Contenu

- `pipeline/` — package Dart `receipt_pipeline` (lines, structure, flow,
  sérialisation) + tests + `tool/parity.dart`.
- `VERIFICATION.md` — spec d'implémentation app du système de vérification.
- `test/harness/` — banc Flutter on-device : mode « Suite complète » (flow
  local sur images poussées via `adb push` dans `files/input/`, prioritaire
  sur `assets/corpus/` ; `adb pull` de `files/results/`) et mode « Scanner
  un ticket » (caméra).
- `test/analysis/` — clustering (`lines.py`), structuration (`structure.py`)
  + tests (`test_structure.py`), politique de flow (`flow.py` +
  `test_flow.py`), **bench du mode local rejoué des dumps
  (`bench_local.py`)**, taxonomie des échecs (`analyze_local_failures.py`),
  classifieur V2/V3 (`line_features.py`, `line_features_v3.py`,
  `train_line_classifier.py [--v3]`, `structure_ml.py`, modèles dans
  `models/`), **décodage sous contrainte checksum
  (`decode_constrained.py`)**, bench multi-étages historique
  (`bench_flow.py`), scoring d'un run device (`score_device_flow.py`),
  parité Dart↔Python (`check_parity.py`), générateur synthétique
  (`receipt_content.py`, `receipt_render.py`, `generate_corpus.py`),
  scoring synthétique (`score.py`), vérité depuis transcriptions
  (`transcript_truth.py`), benchmarks LLM/VLM (`llm_structure.py`,
  `bench_llm.py`, `bench_gemini.py`, `probe_capacity.py`), construction du
  golden (`annotate_golden.py`).
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
