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
                          décodage sous contrainte → re-checksum
                          │ échec ↓
                          tagger de rôles → re-checksum
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
Kaggle `srjpdl/findit-dataset`, copié dans `data/raw/findit/`)** : seul
dataset public de tickets de caisse français. 1000 tickets T1 (500 train +
500 test) ~1752×3390, chacun avec sa **transcription texte exacte** — c'est
elle qui fournit le ground truth article par article (via
`truth/transcript.py` : même structuration appliquée au texte parfait,
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

Un corpus web US (40 photos ExpressExpense SRD) a servi de contrôle
hors-domaine : 23/42 auto-validés, zéro faux positif vérifié à l'œil, échecs
tous imputables au vocabulaire US (`Food`/`TL`/`CC`). Il a été **retiré du
corpus le 2026-08-26** — le scan ne vise que la France, et entraîner sur des
tickets anglophones diluait la supervision sans rien apprendre d'utile.

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

L'instrument central est **`research/bench/local.py`** : il rejoue le flow
local complet (règles → retry → classifieur V2) depuis les dumps OCR d'un
run device — une modification de règles ou de modèle se mesure en secondes
sur 1000 vrais tickets, sans retoucher au téléphone. Métriques : validation
directe, faux auto-validés (la barre : 0 montant faux), corrections/ticket
en confirmation. `research/bench/failures.py` classe chaque échec
(structuration / total non lu / montants absents de l'OCR / golden non
checksummable) pour dire où investir.

**Corpus de travail sain (2026-08-24)** : les tickets structurellement
ingagnables sont exclus des benchs via `data/golden/excluded.txt` (101
tickets : 52 golden non-checksummables — cantine subventionnée, balance —
et 49 aux montants absents de l'OCR, dont `t1test_68`, l'unique vrai faux
validé historique). Liste régénérable :
`bench/failures.py device_flow --write-excluded` ; filtrée par
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

`research/reference/line_features.py` (32 features déterministes par ligne porteuse
de prix : géométrie, lexiques, contexte ±1 ligne — portables en Dart) +
`research/line_classifier/train.py` (HistGradientBoosting) +
`research/reference/structure_ml.py` (structuration depuis les labels, re-checksum).

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


## Flow V3 porté en Dart & diagnostics (2026-08-24, soir)

- **Ordre des étages mesuré** (899 dumps) : classifieur avant le retry.
  Passe 1 : règles → classifieur argmax → décodeur ; si rien ne vérifie,
  retry (2e OCR, l'étage cher) → règles → classifieur → décodeur. Même
  précision (832/899), **94 retries au lieu de 198**. Référence Python :
  `research/reference/local_flow.py` (`decide_local`), miroir Dart `flow.dart`
  (`decide` + `classifierRescue`), harnais `local_flow.dart`.
- **Portage Dart complet** : lexiques et règles de calibration
  (`structure.dart`), features V2+V3 (`line_features.dart`, CRC-32 et
  Levenshtein inclus), inférence du classifieur depuis un JSON exporté
  (`classifier.dart`, `research/line_classifier/export.py`, écart vs
  sklearn 4e-16), décodeur DP (`decode.dart`). **Parité flow complet
  Python↔Dart : 1000 dumps, 0 divergence** (`bench/parity.py --model`).
  Tie-breaking du décodeur déterministe des deux côtés (tri stable des
  références, ordre fixe des labels).
  Plage du DP bornée à `[−D, cible + D]` (D = capacité de remise des lignes
  dont P(remise) passe le seuil) : élagage exact, sans quoi le décodeur en
  Dart pur prenait 30 s par ticket sur un S9+.
- **Harnais** : modèle en asset (`assets/models/line_clf_v3.json`),
  `--dart-define=AUTO_SUITE=true` lance la suite sans interaction (pilotage
  adb), chaque ticket de la liste ouvre un détail (résultat / image zoomable
  / texte OCR des deux passes), stats de session en direct (étages, taux
  vérifié, retries, latences) accessibles depuis chaque écran.
- **`research/bench/diagnose.py`** — le système de vérification côté test :
  tous les étages sur tous les tickets, **vérité par ligne** alignée sur le
  golden (`truth/roles.py` : item / discount / total / payment / tva /
  subtotal / quantity / discount_summary / change / ignore) → matrices de
  confusion par étage ; **concordance** entre étages vérifiés (un désaccord
  = collision détectable sans golden) ; **calibration** du taux de faux par
  niveau de confiance affichable ; noms d'articles vs golden ; dégâts OCR
  vs transcription ; **test adversarial du décodeur** (référence remplacée
  par une valeur fausse). Sortie `results/diagnostics/<run>.jsonl` +
  rapport (`--report=<jsonl>` rejoue le rapport sans recalcul).

Premiers enseignements (899 tickets) :

| Signal disponible sans golden | Tickets | Faux affichés |
|---|---|---|
| ≥ 3 méthodes vérifiées concordantes | 745 | 0 |
| 2 méthodes concordantes | 52 | 1 (paire net zéro) |
| 1 seule méthode | 17 | 0 |
| **désaccord entre méthodes vérifiées** | 19 | **2** |
| aucune | 66 | — |

- Le **décodeur seul** vérifie 796/899 mais avec 5 faux : c'est l'étage
  risqué, la cascade le masque. **Adversarial : 21 % des références
  fausses trouvent quand même une solution** (574/2686) — un total mal lu
  par l'OCR a une chance sur cinq d'être « vérifié » à tort par le décodeur
  seul.
- La concordance est le signal manquant : les 2 vrais faux affichés sont
  dans les 19 « désaccord ». Proposition : « vérifié » = ≥ 2 méthodes
  d'accord ; 1 méthode ou désaccord → bandeau « à relire ».
- Confusions dominantes du classifieur (argmax, 899 tickets) : lignes
  `ignore` promues article 56, `tva` promues article 54, `total` lues
  article 40, `payment` ignorées 49 — la cible du prochain entraînement.
- Noms d'articles : similarité médiane 0,95 vs golden, 5,8 % sous 0,6 —
  premier chiffre sur les libellés, jamais mesurés avant.
- Causes racines des 67 non vérifiés : 32 parasites promus par le
  classifieur, 20 références non reconnues, 8 références jamais parsées en
  prix, 4 articles manqués, 3 totaux illisibles.

## Vers 99 % : invariants arithmétiques & fusion des passes (2026-08-25)

Objectif fiabilité (pas de latence) : **832 → 858/899 (95,4 %)**, faux
vérifiés 3 → **2** (les deux paires subvention à net zéro, golden
« gemini-seul »). Méthode : lecture ligne à ligne des 67 échecs, puis
uniquement des règles *structurelles* — jamais de règle par ticket, aucun
seuil déplacé, aucun golden ni exclusion touchés. Tout reste gated par le
checksum au centime et `min_prob`.

| Étape | Vérifiés | Faux |
|---|---|---|
| Départ (V3 + DP, parité Dart) | 832 (92,5 %) | 3 |
| Parsing + lexiques (VISA, S/TOT, CARTES BANCAIRES, SANS CONTACT ; `17 ,00`, `17;00`, `7.074` sur ligne total ; TOTAL flou à 1 édition) + ré-entraînement V3 | 841 | 5* |
| + `invariants.py` + références multi-sources dans le décodeur | 849 | 3 |
| + garde-fou retry assoupli (même total lu) | 850 | 3 |
| + fusion des passes (`fuse_passes.py`) | 854 | 3 |
| + totaux de rayon arithmétiques, Σ rayons | 856 | 3 |
| + taxes jamais article, total intermédiaire éligible s'il clôt les articles, total final avant le premier paiement | 858 | 3 |
| + ligne 0 € jamais article (règles) | **858 (95,4 %)** | **2** |

Par split (modèle entraîné sur T1-train uniquement) : **T1-train 432/451
(95,8 %)**, **T1-test 426/448 (95,1 %)** — l'écart train/test reste faible,
les règles n'ont pas surappris le corpus.

\* Leçon : les lexiques nourrissent les features V3 (similarité floue) —
changer un lexique sans ré-entraîner déplace les probabilités
(« Totaux: » passé de P(total) 0,24 à 0,76). Tout changement de lexique =
`line_classifier/train.py --v3` + `line_classifier/export.py`.

Les mécanismes (`research/reference/invariants.py`, sans modèle, portables en Dart) :

1. **Décomposition TVA** : un HT et une taxe à taux légal (2,1/5,5/10/20 %,
   ±1 centime) prouvent le TTC — sur une ligne de table (`B 20,00% 6,13
   1,22 7,35`, `1> 5.50 0.56 10.04`), ou HT lexical (`HT`, `H.T`, `NET`,
   `TTL`) + ligne TVA. Multi-taux sommés. Les lignes consommées ne sont
   jamais des articles ; toute ligne à lexique taxe (`TVA`, `TUA`, `TAX`)
   non plus. Un taux seul (`5,50`, `20,00`) n'est pas une ligne de taxe :
   ce sont aussi des prix.
2. **Espèces − rendu** = montant réglé (le plus grand paiement avant la
   ligne de rendu ; `Rendu Espèces` est un rendu, pas un paiement).
3. **Récap de remises** : une remise égale à la somme des remises réelles
   précédentes est un récapitulatif (`REMISE TOTALE`, `TOTAL REMISE
   IMMEDIATE`) — si elle porte le mot total ou si ≥ 2 remises la précèdent
   (deux remises identiques ne sont pas un récap).
4. **Totaux de rayon** : une ligne égale à la somme courante des articles
   depuis le rayon précédent (≥ 2 articles sans lexique, 1 avec) est un
   sous-total — ignorable même si le classifieur dit article
   (`ALINENTAIRE 9.05`). Σ des rayons = référence quand ils couvrent tous
   les articles (`Total Soins 12,55` + `Total Non Alimentaire 9.90` =
   22,45 alors que le total à payer est illisible).
5. **Éligibilité des références** : jamais un montant HT ; le total final =
   dernier total lexical **avant le premier paiement** (`Total Bon
   immédiat 3.72` imprimé après la CB n'est pas le total) ; avant lui, un
   sous-total ou total intermédiaire seulement s'il clôt les articles (ni
   article ni remise après lui, pas de rayon différent avant) — `Net Total`
   US suivi de taxes oui, `SOUS TOTAL` suivi de `REMISE` non, `TOTAL
   ALIMENTAIRE` suivi d'articles non.
6. **Références multi-sources** (`decode_constrained.py`) : lignes total du
   classifieur (P ≥ 0,5, rangs éligibles), dernier total lexical (même à
   P faible : `TO'AL Euro`, `OTAL REGLEMENT`), TVA, espèces − rendu, Σ
   rayons — fusionnées par montant, chaque source d'accord ajoute un bonus.
   Une référence virtuelle (sans ligne) coupe à la première ligne qui la
   prouve.
7. **Ticket mono-article** (parking, carburant) : montant prouvé par une
   source arithmétique ET une autre, aucun candidat article, compteur
   d'articles absent ou 1 → l'unique achat porte le montant et le nom de
   l'enseigne. Refusé sinon (`2 ARTICLE(S) TOTAL 4.70` avec articles
   illisibles reste en confirmation).
8. **Fusion des passes** (`fuse_passes.py`, étage `local_fused`) : lignes
   de la passe brute et de la passe prétraitée alignées par position
   verticale ; ligne non chiffrée remplacée par la lecture de l'autre
   passe, ligne absente insérée, montant différent → **alternative** que
   le DP arbitre (pénalité log 0,5). Rien d'inventé : chaque montant vient
   d'une passe OCR. +4 tickets Carrefour (`S2.75e` lu 52,75 d'un côté,
   2,75 de l'autre).
9. **Affichage** : `verified_total` = la référence qui a réellement
   vérifié la somme (jamais un total lu qui ne colle pas — cas paiement +
   compteur d'articles où le total lu était une ligne TVA).

Validité, mesurée avant de conclure :

- **Adversarial** (référence remplacée par un montant faux) : **20,1 %**
  de collisions sur la valeur fausse (21,4 % avant) — le décodeur n'a pas
  été fragilisé par les candidats supplémentaires. La métrique de
  `diagnose.py` a été corrigée : retrouver le *vrai* total par une autre
  source (table TVA, espèces − rendu) n'est pas une collision (brut : 42 %).
- **Concordance** : 4 tickets `local_fused` sans autre méthode d'accord,
  0 faux ; tous les vérifiés à ≥ 2 méthodes : 0 faux hors les 2 net-zéro.
- **Hold-out jamais regardé** : synthétique 120 identique (100/100/97,9 %,
  précision 100 %) ; `device_fr_big` 208 → 211 vérifiés (+3, dont
  `0697` récupéré par la règle « total avant paiement ») ; `device_web`
  (US, hors domaine) 152 → 148 : 3 pertes sont des **corrections** (taxe
  ou remise avalée en silence avant : `srd_1123`, `srd_1126`,
  `invoice_with_discount`), 1 est une taxe sans lexique (`IL Sales`), et
  le total affiché devient le sous-total vérifié (hors taxe) — sémantique
  US à traiter avec la locale, pas ici.

**Plafond réaliste sur FindIt.** Les 41 restants : ~12 sans aucune ligne
chiffrée ou aux articles illisibles dans les deux passes (`t1test_740`,
`t1train_1738`, `981`, `1274`, `530`, `84`, `450`, `139`…), 4 carburant
(volume en litres pris pour un article, total sans lexique), 3 lignes TVA
imprimées incohérentes avec le total (`t1test_741`), 1 ticket photographié
en double (`483`), 1 échange à article négatif (`770`), ~10 Carrefour à
lignes fusionnées par le clustering (deux prix sur une ligne : `3.75e
2.94€`) ou articles manqués par les deux passes, 1 montant à 50 % non
imprimé (`868`). Sans meilleure OCR (ou image), le gisement générique
restant est le clustering des tickets inclinés (lignes à deux prix) — ~5
tickets. Le **99 % est une cible pour photos fraîches** (tier synthétique
photo : 100 %), pas pour ce corpus pire-cas.

**Portage Dart (2026-08-25)** : `pipeline/` porte tout le chapitre —
`invariants.dart`, `fuse_passes.dart`, décodeur à références multiples,
alternatives et mono-article (`decode.dart`), `verifiedTotal`, lexiques et
parsing (`structure.dart`), étage `FlowStage.localFused`, orchestration
partagée `decideFirstPass` / `decideRetryPass` (outil de parité et harnais
utilisent le même code), modèle ré-exporté dans l'asset du harnais.
**Parité `bench/parity.py --model` : 1000/1000 sur `device_flow`, 699/699
sur fr / fr_big / fr_enhanced / web / emulator_all, 0 divergence.** 183
tests Dart. Harnais : la page « Stats de session » se met à jour en direct
(le builder renvoyait un widget `const` identique, jamais reconstruit —
remplacé par un `SessionSnapshot` immuable par notification).

## Portage Dart & banc on-device (2026-08-24)

- **`pipeline/`** : package Dart pur `receipt_pipeline` — portage de
  `lines.py` + `structure.py` + `flow.py`, 46 tests portés. Parité vérifiée
  champ à champ contre Python sur 699 dumps OCR (FindIt, enhanced, web,
  synthétique) : **0 divergence** (`research/bench/parity.py` +
  `pipeline/tool/parity.dart`).
- **`harness/`** devient un banc à deux modes : « Suite complète »
  (images via `adb push` dans `files/input/`, flow local complet par ticket,
  dump OCR historique + section `flow`) et « Scanner un ticket » (photo →
  flow local → résultat structuré à l'écran). Le prétraitement retry
  (autocontrast + unsharp + upscale 2400 px) est embarqué en Dart.
- **`research/bench/device_flow.py`** score un run de suite tel qu'exécuté
  sur le device : parité device ↔ Python par ticket, métriques vs golden.
  Nommage des images poussées : `t1test_<doc>.jpg` / `t1train_<doc>.jpg`.

Runs 1000 tickets golden : S9+ (2018) et Pixel 8 Pro — **OCR strictement
identique sur 99,7 % des images, 0 décision divergente** : le moteur ML Kit
est constant inter-devices, la seule variable réelle est la qualité de la
photo (capteur, focus). Latence pipeline S9+ : médiane 404 ms, p95 1,2 s.
Dumps : `data/results/device_flow[_pixel]/` (gitignorés), corpus de replay
de `bench/local.py`.

Parité connue : l'APK d'avant le fix des diacritiques a produit 1 dump
divergent (`t1train_790`, « TŤC ») — corrigé dans le package (table de
repli latin étendu-A), APK reconstruit.

## Golden dataset

`data/golden/T1-{test,train}/` : 1000 tickets FR annotés (enseigne, date,
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

1. ~~Portage Dart du chapitre « Vers 99 % »~~ **fait** (parité
   1000/1000). Reste : relancer la suite device (S9+ / Pixel) pour mesurer
   la latence du nouveau flow (fusion + DP à alternatives).
2. **Niveau de confiance par concordance** : n'afficher « vérifié »
   qu'avec ≥ 2 méthodes d'accord ; durcir le décodeur (adversarial
   20 %) : nombre de flips, marge de log-prob.
3. Au-delà de 95 % : clustering des tickets inclinés (lignes à deux prix),
   puis modèle de séquence / encodeur layout-aware (classe BERT, golden +
   synthétique).
4. **Intégration app (mode LOCAL uniquement)** : brancher `receipt_pipeline`
   (sans clé API, sans cooldown, offline), sortie vers
   `ReceiptScanResultModel` — écran d'édition et `validateAndCreate`
   inchangés. Le mode cloud existant ne bouge pas. Spec : `VERIFICATION.md`.
5. **BERT** sur les libellés extraits — augmentation « style ticket » du
   dataset quick-add, calibrée sur les 1000 tickets réels du golden.
6. Fil rouge : valider sur des photos fraîches prises au téléphone via le
   mode « Scanner un ticket » du harnais (le corpus FindIt est un pire-cas
   scanné, pas le scénario nominal — la capture app devra soigner
   résolution/focus, seule vraie variable inter-devices).

## Photos réelles, métrique stricte & corpus annoté (2026-08-25)

Le point 6 des étapes ci-dessus est tombé : 71 photos de tickets prises au
téléphone (Intermarché, Noz, Maxi Zoo, Gifi…) mesurées de bout en bout. Elles
invalident deux hypothèses de toute l'étude, et une troisième est tombée en
mesurant correctement.

**L'orientation.** 54 % des photos ont leur texte à ±90° — un ticket long se
photographie en paysage. Le clustering raisonne en recouvrement vertical et
n'a aucun sens avant d'avoir retiré ce quart de tour ; sans correction, le
ticket entier devient une seule ligne. Corrigé côté recherche (`ocr/`, page
remise d'aplomb avant structuration), **pas encore dans l'app**.

**Le corpus FindIt n'est pas un pire-cas.** Orientation corrigée, le flow ne
vérifie que 35 % de ces photos contre 90,4 % sur FindIt. C'est un cas facile
déguisé : mono-enseigne, scanné à plat.

**Le checksum ne mesure pas ce que l'utilisateur voit.** `count_edits`
comparait des montants, sans ordre, et **ni les libellés, ni l'enseigne, ni la
date**. Or le nom décide de la catégorie donc de la ligne de budget, la date
décide du mois. `bench/exactness.py` pose la métrique produit : un ticket ne
compte que si **tout** est juste — enseigne, date, total, et chaque article
apparié sur (nom, montant net), sans article en trop ni manquant.

| Sur T1-test (500 tickets) | au départ | après cette passe |
|---|---|---|
| « vérifiés » (checksum) | 90,4 % | 90,2 % |
| **tickets parfaits** | **51,0 %** | **69,0 %** |

Deux tolérances, et seulement deux, pour mesurer le rattachement et pas l'OCR :
les libellés se comparent par similarité (`120GENU` vaut `120GENV`) mais un
libellé qui ne nomme rien (`EUR`, un code) ne s'apparie à rien ; l'enseigne
accepte l'inclusion (`city` vaut `CARREFOUR CITY`, l'OCR ne lit que le logo).

Le flow Python jetait les libellés (`LocalOutcome` ne portait que des
montants) là où le Dart les remonte depuis toujours : aucune mesure ne
*pouvait* voir un libellé rattaché au mauvais prix.

### Où part le reste

| Poste | Au départ | Maintenant | Ce qui a changé |
|---|---|---|---|
| articles | 131 (26 %) | 124 (25 %) | libellés faibles rattachés par le tagger |
| date | 153 (31 %) | **19 (4 %)** | lecture reprise + ligne désignée par le tagger |
| enseigne | 58 (12 %) | **32 (6 %)** | ligne désignée par le tagger, plus `lines[0]` |
| total | 26 (5 %) | 26 (5 %) | inchangé |

La date était le premier poste ; sa lecture a été reprise et figée par 38
tests — année sur deux ou quatre chiffres, séparateurs `/ . -`, jour et mois
sur un chiffre, mois en toutes lettres ou abrégés et accentués, numéros de
téléphone masqués (séparateur obligatoire **et identique** : sinon le masque
avale les codes de caisse, et une date encadrée de séparateurs est rejetée).

Reste dans les 124 articles faux : **66 libellés qui nomment le mauvais
produit** (le tagger ne corrige que ceux qui ne nomment rien), 44 montants
faux, 14 écarts de comptage.

### Ce qui casse, mesuré sur un ticket lisible et bien orienté

Sur un Maxi Zoo dont l'OCR est quasi parfait, `Total remise: EUR 58,98` est
pris pour le total — « REMISE » n'est pas dans `EXCLUDED_TOTAL_WORDS`. Comme
`total_index` sert **aussi** de borne à la zone articles, cette borne descend
en bas du ticket et `Achat différé` / `Montant net` entrent comme articles.
Un seul défaut, deux symptômes, et le décodeur retombe sur la référence fausse
en comptant quatre fois le même 16,99 → sortie fausse **badgée vérifiée**.

Racine commune : les règles supposent qu'une ligne porte un article, ce qui
est vrai chez Carrefour et faux dès qu'une enseigne imprime le prix deux fois.

### Le classifieur ne pouvait pas rattraper ça

`train.py` prenait les décisions des règles pour vérité sur les 77 % de
tickets qu'elles validaient : le modèle était leur élève, entraîné sur une
seule enseigne, et n'étiquetait que les lignes porteuses de prix.

Le corpus annoté le remplace : tickets annotés depuis l'image, filtrés par
checksum (`research/annotate/README.md`), fiabilité prouvée contre le golden
FindIt — **412/414 sur T1-train (99,5 %) et 413/413 sur T1-test (100 %)**. Le
jeu d'évaluation — `T1-test` et `photos_pixel` — ne sert jamais à entraîner.

Réentraîné dessus, le classifieur gagne beaucoup **sur les rôles** :

| | exactitude | `discount` | `total` | `payment` | `ignore` |
|---|---|---|---|---|---|
| supervisé par les règles | 93,9 % | 61,4 % | 81,7 % | 88,1 % | 91,6 % |
| supervisé par le corpus | **96,7 %** | **79,5 %** | **97,2 %** | **95,1 %** | 89,8 % |

**Et rien sur le flow** : 90,2 % de vérifiés inchangés, et les faux vérifiés
passent de 2 à 4. La cause, vue sur `t1test_722` : le golden a `2,40 + 0,10`,
le décodeur retient `1,55 + 0,95` — même somme, mauvais montants. Le
subset-sum a plusieurs solutions exactes et seules les probabilités du
classifieur les départagent ; un classifieur *différent*, même meilleur, en
choisit simplement une autre. **La métrique de rôles et celle du flow ne sont
pas alignées** — le goulot n'est pas la qualité du classifieur, c'est que le
décodeur accepte une combinaison ambiguë. Rien n'a été publié : la barre reste
zéro montant faux.

### Le tagger de rôles

Un seul modèle, toutes les lignes, 14 classes (`line_classifier/train_roles.py`,
features de `line_features_all.py` — géométrie relative, forme du texte,
lexiques, et le voisinage immédiat qui permet d'apprendre qu'après le total il
n'y a plus d'articles). Sur les 435 tickets d'évaluation, 10 448 lignes :

| `item` | `total` | `date_line` | `store` | `payment` | `item_label` | `discount` |
|---|---|---|---|---|---|---|
| 98,5 % | 96,4 % | 95,0 % | 93,0 % | 92,1 % | 82,7 % | 76,6 % |

93,4 % d'exactitude globale. **Le tagger désigne la ligne, le parsing lit le
champ** : l'enseigne est la ligne argmax `store` (et rien du tout si le modèle
hésite — mieux vaut pas d'enseigne qu'une ligne au hasard), la date est lue
sur la ligne `date_line` avec repli sur le ticket entier.

Le décodeur sous contrainte n'a pas été touché — c'est lui qui avait doublé
les faux vérifiés.

Le tagger, le modèle de lien et le rattachement des libellés sont portés en
Dart et branchés dans l'app (`pipeline/lib/src/label_link.dart`,
`LocalReceiptScanner`). Les modèles du scan partagent désormais leur version
et leur release avec ceux de l'ajout rapide : un seul `tool/models/publish.sh`
les publie tous, un seul `fetch.sh` les récupère, et l'app lit chaque nom dans
le manifeste des assets.

### Le rattachement du libellé, appris (2026-08-26)

Le libellé se rattachait par une règle de distance : la ligne juste au-dessus,
si le tagger la disait `item_label` avec au moins 0,90 de confiance. Deux
nombres choisis à la main pour une question qui dépend du ticket — et le
tagger n'a que 74,7 % de précision sur ce rôle, donc le seuil arbitrait entre
réparer un libellé faux et écraser un libellé juste.

`line_classifier/train_link.py` pose la question directement : **à quelle
distance au-dessus est le libellé de cet article ?** La vérité est déjà dans
le corpus (`label_index`), les features sont la fenêtre des trois lignes
précédentes (`line_features_all.window`). Sur les 2 195 lignes d'article du
jeu d'évaluation : **99,0 % d'exactitude** (87,6 % en répondant toujours « sur
sa propre ligne »), et sur les libellés déportés — le cas qui casse — rappel
96,6 % pour 96,9 % de précision, contre 82,7 / 74,7 au tagger.

| T1-test | avant | après |
|---|---|---|
| tickets parfaits | 71,6 % | **72,8 %** |
| articles faux | 112 | 105 |
| vérifiés / faux vérifiés | 90,2 % / 4 | inchangés |

Le gap « libellé rattaché au mauvais prix » passe de 40 à 33 tickets. Les 33
restants ne sont plus un problème de rattachement : sur 26 d'entre eux le
libellé attendu n'existe nulle part dans l'OCR, abîmé à la lecture.

### Le découpage du libellé, appris (2026-08-26)

Le rattachement désigne la bonne ligne ; le libellé restait découpé dedans par
une règle — une coupe verticale unique, le quantile 0,9 des prix
(`_label_column_left`), plus quatre expressions régulières de nettoyage
(`_clean_name`). Mesuré sur les 186 libellés faux de T1-test, **78 % venaient
de ce découpage** et non du rattachement ni de l'OCR :

| cause | articles | tickets perdus *uniquement* pour ça |
|---|---|---|
| découpage du libellé | 146 (78 %) | 69 (14,3 %) |
| rattachement à la mauvaise ligne | 21 (11 %) | 14 (2,9 %) |
| libellé absent de l'OCR | 19 (10 %) | 14 (2,9 %) |

Sur les 103 résidus, 88 sont des tokens purement numériques : un code article
(`583877 DIAMOND TAPIS`), un code rayon (`SANDW 6015`), une quantité
(`*AVOCAT 2x`), un prix unitaire (`CVDC CARTE VITRIN 4.40 1`). Un ticket
imprime trois à cinq colonnes et leurs frontières changent d'une enseigne à
l'autre : **une coupe scalaire ne peut pas les exprimer.**

La colonne devient donc une feature *par mot* (`reference/word_features.py`) :
géométrie relative, forme du token, et surtout la **bande verticale** — ce que
les autres lignes du ticket impriment à cette abscisse. Un mot dont la bande
est numérique appartient à une colonne ; le même mot ailleurs appartient au
nom.

Le décodage (`reference/spans_ml.py`) impose ce qu'un libellé est par nature —
un intervalle **contigu** de mots portant des lettres — et rien de plus.
L'intervalle retenu est celui de log-odds maximale : un mot n'y entre que s'il
rapporte plus qu'il ne coûte. Aucun seuil.

La vérité vient de l'alignement du libellé du golden sur les mots d'une ligne
(`truth/spans.py`), au-dessus de 0,95 de ressemblance : ce que l'OCR a abîmé
n'enseignerait qu'une frontière inventée, et le filtre joue ici le rôle que le
checksum joue pour les montants. Elle se lit directement des images sans
passer par l'annotation de rôles — celle-ci rejette les tickets dont un
montant est illisible, et ce sont eux qui portent les découpages rares : 1 516
lignes d'entraînement en passant par elle, **2 108** sans.

A/B à vérité et flow identiques, seul le rattachement du libellé change :

| T1-test (483 tickets jugés) | avant | après |
|---|---|---|
| tickets parfaits | 307 (63,6 %) | **340 (70,4 %)** |
| articles faux | 148 | **118** |
| enseigne / date / total faux | 28 / 19 / 18 | inchangés |
| vérifiés / faux vérifiés | 93,2 % / 1 | inchangés |

Le tagger rend le bon intervalle sur **96,0 %** des 2 166 lignes du jeu
d'évaluation. Comme le classifieur de lignes, il ne touche à aucun montant :
un libellé ne peut ni sauver ni corrompre un checksum.

`export_span.py` rend le JSON portable, et `line_classifier/export.py` gagne
au passage le cas **binaire** — une seule sortie brute, lue à la sigmoïde là
où un modèle multiclasse passe au softmax. `bench.roles_parity` compare
désormais cinq choses : features de ligne, features de mot, rôle, distance au
libellé et **libellé découpé** — 0 divergence sur 999 tickets de T1, écart max
de features de mot 5,6e-16.

**Le nombre en tête reste ouvert, et il n'est pas de notre côté.** Sur les 207
lignes de T1-test qui commencent par un entier, le golden garde ce nombre dans
le libellé 146 fois et l'exclut 61 fois — « 1 MxBO Filet-Fish » d'un côté,
« 1 M GIANT » → « M GIANT » de l'autre, sur des tickets de même famille. La
décision est cohérente *par ticket* (98 tickets cohérents contre 1), donc
l'annotateur suit quelque chose ; mais aucune géométrie disponible ne le
sépare : bande numérique, dispersion des bords de colonne, écart au mot
suivant rapporté à l'écart habituel du ticket — tous mesurés, tous confondus
entre les deux cas (dispersion du bord droit 0,073 contre 0,054, écart 0,0056
contre 0,0060). Deux tentatives de features et un rééquilibrage des classes
plus tard, le modèle exclut 25 % de ce qu'il devrait exclure.

C'est une limite de la **référence**, pas du modèle : le golden ne dit pas si
une quantité fait partie du nom. Le remède n'est pas un meilleur classifieur,
c'est de sortir la quantité du libellé et d'en faire un champ — la question
disparaît alors des deux côtés, celui du modèle comme celui de la vérité.

### Deux niveaux de gravité, et ce que le checksum ne voit pas (2026-08-26)

La métrique comptait un ticket faux dès qu'un champ divergeait, tous à
égalité. Ils ne le sont pas. Un **montant**, une **enseigne**, une **date**
sont affichés en clair à côté d'un ticket que l'utilisateur a encore en main :
il les relit et les corrige. Un **libellé posé sur le mauvais article** et un
**article absent** ne se voient pas — la ligne a l'air normale, la somme tombe
juste, rien n'attire l'œil. Ces deux-là partent silencieusement dans le budget.

`bench/exactness.py` sépare donc les articles en quatre verdicts au lieu d'un.
L'appariement va du plus sûr au moins sûr — couple (nom, montant) d'abord,
puis montant seul, puis nom seul — et ce qui reste manque ou est en trop :

| apparié par | verdict | gravité |
|---|---|---|
| montant, pas le nom | libellé faux | **silencieux** |
| rien, côté attendu | article manquant | **silencieux** |
| rien, côté extrait | article en trop | **silencieux** |
| nom, pas le montant | montant faux | rattrapable |

Le tableau qui compte est celui des tickets **vérifiés** : ceux-là ne passent
par aucun écran de confirmation, donc personne ne relira rien.

| T1-test, 450 tickets vérifiés | tickets | articles |
|---|---|---|
| **au moins une erreur silencieuse** | **83 (18,4 %)** | |
| libellé sur le mauvais article | 73 (16,2 %) | 164 |
| article manquant | 14 (3,1 %) | 25 |
| article en trop | 3 (0,7 %) | 3 |

**Le checksum contraint la somme, pas le libellé ni le nombre d'articles.** Il
ne peut structurellement voir aucune des deux. Les 25 articles manquants ne
sont d'ailleurs pas des produits perdus : 18 sont des articles à net 0,00 que
`structure.py` jette (`if price == 0`) ou des lignes de remise repliées dans
leur article — la somme tombe juste puisqu'ils valent zéro. **5 seulement sont
de vraies fusions**, deux produits collés sur une ligne d'OCR.

### Décodage joint lien × span : mesuré, abandonné (2026-08-26)

Sur les 184 libellés faux, 35 (19 %) viennent d'une mauvaise distance prédite,
et 27 d'entre eux sont « prédit 0, attendu 1 ou 2 » — le modèle place le
libellé sur la ligne du prix alors qu'elle ne porte aucun nom :

```
ligne du prix : 1.29 EUR                    vraie ligne : ALIM TN 6011
ligne du prix : Net 0.335kg*4.35€/kg 1.46   vraie ligne : EPINARD VRAC
ligne du prix : Montant : 39.45             vraie ligne : Carburant : GAZOLE
```

L'idée : choisir la distance qui maximise `log p_lien(k) + score du meilleur
intervalle sur la ligne i−k`, les probabilités des deux modèles, sans seuil.
Un premier relevé semblait la soutenir — sur les erreurs, la vraie ligne score
mieux que la choisie dans 83 % des cas (log-odds moyen, écart médian +0,8).

**Ce relevé était trompeur** : il demandait si la vraie ligne score *mieux*,
pas si elle peut *gagner*. Le modèle de lien est très confiant — `log p(0)`
frôle 0 quand `log p(1)` vaut −7 — et aucun écart de span ne rattrape ça.
Balayage du poids sur T1-train, 1 983 articles :

| composition | bonne ligne |
|---|---|
| lien seul (actuel) | 1 960 (98,84 %) |
| lien + 0,75 × log-odds moyen | 1 961 (98,89 %) |
| lien + 2 × log-odds moyen | 1 955 (98,59 %) |
| lien + 5 × log-odds moyen | 1 882 (94,91 %) |

**+1 article, puis dégradation.** La cause est un défaut de conception du
tagger de spans : il n'est entraîné que sur des lignes **porteuses** de
libellé. Lui demander « cette ligne en porte-t-elle un ? » est une question
qu'il n'a jamais vue, et son score sur une pesée ou un prix seul est hors
distribution.

Corrigé — négatifs ajoutés, les lignes que le lien aurait pu désigner à la
place — le score devient exploitable mais le gain reste dérisoire : **99,04 %
au mieux, +4 articles**, pour **4,4 points perdus sur le découpage** (96,0 % →
91,6 % d'intervalles exacts), un même modèle ne servant pas deux questions.
Revenu à l'état mesuré.

Ce qu'il faut en retenir pour la suite : un score « cette ligne porte-t-elle
un libellé ? » **est** apprenable, mais il ne sert pas à *choisir* la ligne —
le lien a déjà raison à 98,8 %. Il servirait à **douter**, et le doute est la
seule chose qui puisse faire tomber les 18,4 % d'erreurs silencieuses : un
libellé sans invariant arithmétique n'a que sa probabilité comme garde-fou.
Cela demande un modèle à part, pas une feature de plus.

### Neuf rôles au lieu de quatorze, et le tagger entre dans le flow (2026-08-26)

Le tagger de rôles existait depuis un moment et ne servait qu'à désigner
l'enseigne et la date. La décision « cette ligne est-elle un article » — celle
qu'il connaît le mieux — ne lui était jamais demandée, et les règles la
prenaient par géométrie et lexiques.

**Six des quatorze rôles ne sont lus par personne.** `structure_roles` lit
item, item_label, discount, total, subtotal, payment ; `header_ml` lit store
et date_line. Distinguer tax, change, summary, header, footer et noise
n'apporte rien à aucun consommateur, et l'annotateur ne peut pas y être
cohérent : mesuré sur T1-test, **41 % des erreurs du tagger sont des
confusions entre ces six-là**. La projection est dans `line_labels.py`, à
côté de celle du classifieur V2 ; le corpus, lui, garde ses quatorze rôles.

| tagger, T1-test | 14 rôles | 9 classes |
|---|---|---|
| exactitude par ligne | 94,8 % | **96,9 %** |
| tickets sans aucune erreur de rôle | 51,8 % | **66,3 %** |
| tickets sans erreur sur les montants | 83,9 % | **84,8 %** |

**Et le flow ne bouge presque pas** : 91,3 % → 91,8 % de checksum via les
rôles. C'est le piège déjà rencontré une fois, et il tient toujours — un
classifieur par ligne décide indépendamment ligne à ligne, alors qu'une seule
erreur sur une ligne porteuse de montant casse le ticket entier. À 98,6 % de
rappel sur `item` et cinq articles par ticket, un ticket sur vingt perd un
article et c'est fini pour lui. **L'exactitude de rôles et l'exactitude du
flow ne sont pas la même métrique.**

### Les règles servent-elles encore ? Chaque étage, seul (2026-08-26)

La chaîne n'est pas « les règles » : c'est un **ensemble de lectures que le
checksum arbitre**. Les règles n'y sont qu'un votant. Chaque étage seul, puis
les combinaisons :

| étage seul | T1-test (scans à plat) | photos_pixel (vraies photos) |
|---|---|---|
| règles | 371 (89,4 %) | **4 (20,0 %)** |
| classifieur V2 | 379 (91,3 %) | 12 (60,0 %) |
| **décodeur sous contrainte** | **404 (97,3 %)** | 13 (65,0 %) |
| rôles (9 classes) | 381 (91,8 %) | 11 (55,0 %) |
| rôles annotés (plafond) | 409 (98,6 %) | 17 (85,0 %) |

| combinaison | T1-test | photos_pixel |
|---|---|---|
| règles + V2 + décodeur | 408 (98,3 %) | 13 (65,0 %) |
| **sans les règles** | 404 (97,3 %) | **13 (65,0 %)** |
| **+ rôles** | 408 (98,3 %) | **15 (75,0 %)** |
| tickets que seules les règles sauvent | 4 | **0** |
| tickets que seuls les rôles sauvent | 0 | **2** |

Sur les vraies photos, **les règles seules ne vérifient que 20 % des tickets
et les retirer de la chaîne ne coûte aucun ticket**. Sur les scans à plat
elles en sauvent encore 4 sur 415. Ce qui porte la chaîne aujourd'hui, ce
n'est pas elles : c'est le décodeur sous contrainte, 97,3 % à lui seul.

Elles restent en place quand même. Pas parce qu'elles sont bonnes — la preuve
qu'elles sont inutiles repose sur **20 tickets annotés** et sur une comparaison
**à une seule passe OCR**, quand la production leur en donne deux plus la
fusion. L'argument pour les retirer sera la simplicité du code, et il se
tranchera sur un corpus photo sérieux.

### L'étage de rôles, branché en dernier (2026-08-26)

`classifier_rescue` essaie désormais quatre seconds avis : argmax du
classifieur, décodage sous contrainte, puis **structuration par les rôles**.
Le tagger passe en dernier, et c'est délibéré : sur une même passe, un ticket
qu'un étage antérieur fait boucler garde exactement la lecture qu'il avait. Il
peut en revanche vérifier en passe 1 ce qu'un étage antérieur n'aurait vérifié
qu'en passe 2 — l'étiquette d'étage change alors, jamais les montants.
**Vérifié sur les 483 tickets de T1-test : 3 tickets gagnés, 0 lecture
modifiée.**

| T1-test | avant | après |
|---|---|---|
| vérifiés | 450 (93,2 %) | **452 (93,6 %)** |
| tickets parfaits | 340 (70,4 %) | **342 (70,8 %)** |
| erreurs silencieuses (tickets vérifiés) | 83 (18,4 %) | 84 (18,6 %) |
| faux vérifiés | 1 | 1 |

Le gain est nul sur les scans à plat et vaut +10 points sur les vraies photos.
Le ticket silencieux supplémentaire est le risque assumé d'un étage qui
vérifie plus : il n'apparaît que parce qu'un ticket de plus est vérifié.

`structure_roles.dart` porte l'étage, `flow.dart` l'ajoute à
`classifierRescue`, et `bench.parity` compare le flow complet ticket par
ticket : **699 tickets, 0 divergence**. Il a fallu réparer ce bench au
passage — il dépaquetait `outcome.items` comme des tuples depuis que
`LocalOutcome` porte des `ExtractedItem`, et ne tournait donc plus.

### Le golden se juge lui-même (2026-08-26)

Le golden est une annotation LLM sur image : il se trompe, et en silence. Il
s'impose pourtant la même égalité que le pipeline — Σ(articles − remises) =
total. **27 tickets de T1-test (5,4 %) n'y satisfont pas**, et 24 d'entre eux
étaient comptés comme des échecs du pipeline.

Deux chaînes indépendantes tranchent, et seulement si elles bouclent : la
transcription officielle FindIt (texte parfait, aucun OCR) puis le corpus
annoté (le ticket relu depuis l'image). Le reste sort du score —
`data/golden/inconclusive.txt`, compté à part, jamais en échec.

| | T1-test | T1-train |
|---|---|---|
| golden cohérent | 94,6 % | 95,0 % |
| réparé par une chaîne indépendante | 2,0 % | 1,2 % |
| aucune chaîne ne boucle | 3,4 % | 3,8 % |

Sur les cinq tickets que la transcription tranche, **elle donne raison au
pipeline** : `572`, `578` et `1075` déduisaient une remise que le golden avait
oubliée, et l'analyse les portait au passif comme des « remises fantômes ».
Un faux vérifié sur quatre disparaît de la même façon — c'était le golden.

| T1-test | avant | après |
|---|---|---|
| tickets parfaits | 364/500 (72,8 %) | **365/483 (75,6 %)** |
| — dont réparations réelles | | +4 tickets à corpus constant (73,6 %) |
| — dont vérité manquante | | 17 tickets hors score |
| faux vérifiés | 4 | 3 |

`truth/golden.py` porte le critère et l'arbitrage, `truth/references.py` les
lectures concurrentes, `truth.audit_golden` le rapport et la liste.

### Portage Dart du modèle de lien (2026-08-26)

`label_link.dart` refait l'inférence, `line_features_all.dart` la fenêtre,
`export_link.py` le JSON portable (écart max export vs sklearn : 2,2e-16).
`bench.roles_parity` compare désormais trois choses ligne à ligne — features,
rôle, distance au libellé : **0 divergence sur 999 tickets** de T1.

La parité étendue à T1 a fait tomber deux défauts qu'elle ne voyait pas
avant, tous deux dans le repli d'accents Dart :

- le cyrillique n'était pas replié (`okaïdi` avec un ï cyrillique, U+0457) ;
- `ß` reste `ß` avec le `toUpperCase` de Dart, quand Python rend `SS`.

`tool/generate_accent_fold.py` couvre maintenant le grec et le cyrillique, et
dérive la table de la **majuscule** du caractère, ce qui capture les
expansions de casse. 811 entrées au lieu de 572.

Deux seuils divergeaient aussi : le Dart désignait l'enseigne et la ligne de
date à 0,90 de confiance là où la référence Python — celle que le bench
mesure — se contente de 0,5. L'app suivait donc une politique jamais
mesurée ; elle suit maintenant la référence.

### Schéma à 14 rôles annotés

Le corpus annote 14 rôles ; le tagger n'en prédit plus que 9 depuis
2026-08-26 (voir plus haut) — six d'entre eux ne sont lus par personne. Ce qui
suit décrit le vocabulaire d'**annotation**, qui n'a pas bougé.

`store` et `date_line` sortent de `header` : les mesures montrent qu'ils
échouent pour des raisons opposées — l'enseigne est une *sélection de ligne*
ratée, la date une *lecture* ratée sur la bonne ligne. Le modèle désigne la
ligne, le parsing garde la lecture du champ. Pas de second classifieur : les
rôles de ligne sont mutuellement exclusifs, les découper fabriquerait des
conflits à arbitrer, et 537 tickets ne nourrissent pas N modèles.

## Contenu

```
ml/scan/
├── research/            # la recherche, en Python
│   ├── reference/       #   le pipeline de référence — tout ce qui a un miroir Dart
│   ├── truth/           #   vérité terrain : transcriptions, rôles de ligne, golden
│   ├── corpus/          #   génération du synthétique, reconstruction des sélections
│   ├── line_classifier/ #   entraînement et export du classifieur de lignes
│   ├── llm/             #   LLM/VLM comme annotateur : structuration, client Gemini
│   ├── bench/           #   la mesure : parité, scoring, diagnostics, benchmarks
│   ├── models/          #   artefacts du classifieur de lignes (versionnés)
│   └── tests/           #   invariants du pipeline de référence
├── pipeline/            # package Dart receipt_pipeline — le portage livré
├── harness/             # banc Flutter on-device
└── data/                # corpus, datasets, dumps OCR (gitignoré sauf golden/)
```

`research/reference/` est le seul dossier lié par contrat au Dart : chaque
module y a son miroir dans `pipeline/lib/src/`, et `research/bench/parity.py`
échoue à la moindre divergence.

- **`research/reference/`** — reconstruction des lignes (`lines.py`),
  structuration par les règles (`structure.py`) et par les rôles
  (`structure_roles.py`), invariants structurels (`invariants.py`),
  fusion des passes (`fuse_passes.py`), décodage sous contrainte checksum
  (`decode_constrained.py`), features du classifieur (`line_features.py`,
  `line_features_v3.py`) et contrat de classes (`line_labels.py`),
  structuration par classifieur (`structure_ml.py`), features par mot et
  découpage du libellé (`word_features.py`, `spans_ml.py`), politique de flow
  (`flow.py`, `local_flow.py`).
- **`research/bench/`** — bench du mode local rejoué des dumps (`local.py`,
  l'instrument central), taxonomie des échecs (`failures.py`), diagnostics
  (`diagnose.py`), scoring d'un run device (`device_flow.py`), scoring
  synthétique (`score.py`), parité Dart↔Python (`parity.py`), bench
  multi-étages historique (`flow.py`), benchmarks LLM/VLM (`gemma.py`,
  `gemini.py`, `capacity.py`).
- **`research/truth/`** — vérité depuis les transcriptions (`transcript.py`),
  rôle réel de chaque ligne (`roles.py`), mots qui composent un libellé
  (`spans.py`), sélection des tickets à vérité fiable (`selection.py`),
  construction du golden (`annotate.py`).
- **`research/corpus/`** — générateur synthétique (`content.py`, `render.py`,
  `generate.py`), reconstruction des sélections (`rebuild.py`).
- **`pipeline/`** — package Dart `receipt_pipeline` (lines, structure,
  line_features, classifier, decode, flow, sérialisation) + tests +
  `tool/parity.dart`.
- **`harness/`** — banc Flutter on-device : mode « Suite complète » (flow
  local sur images poussées via `adb push` dans `files/input/`, prioritaire
  sur `assets/corpus/` ; `adb pull` de `files/results/`) et mode « Scanner
  un ticket » (caméra).
- **`data/golden/`** — golden dataset **versionné** : 1000 annotations JSON.
  `data/raw/findit/` (dataset Find it!), `data/corpus/` (synthétique et
  sélections d'images), `data/results/` (sorties OCR par device, caches LLM)
  sont gitignorés.
- **`VERIFICATION.md`** — spec d'implémentation app du système de vérification.

## Datasets : sources et reconstruction

Les images ne sont **pas versionnées** (poids ~2GB + licence FindIt
recherche-only, redistribution interdite) ; seules les annotations golden le
sont. `research/fetch_data.sh` reconstruit tout :

| Dataset | Source | Licence |
|---|---|---|
| Find it! (1000 tickets FR + transcriptions) | officiel : http://findit.univ-lr.fr/download-the-dataset/ (formulaire) ; miroir : `kaggle datasets download srjpdl/findit-dataset` | recherche, citer Artaud et al. ICPR 2018 |
| Wikimedia Commons (1 ticket FR) | `Special:FilePath` — voir fetch_data.sh | libres |
| Synthétique (120 tickets + ground truth) | `research/corpus/generate.py` (seed 42, déterministe) | interne |

Les sélections dérivées (`selection_fr`, `selection_fr_big`) se
reconstruisent à l'identique via `research/corpus/rebuild.py` (mêmes ids,
mêmes noms de fichiers → caches et benchs restent comparables).

Reproduire les mesures : l'OCR device se relance en poussant les images dans
`files/input/` du harnais (`adb push`), les benchs se rejouent gratuitement
depuis les caches de `data/results/` et le golden.
