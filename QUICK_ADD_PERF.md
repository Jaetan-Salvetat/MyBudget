# Quick-Add — optimisations perf

Mesures CPU Mac (int8, `evaluation/data/quick_add.json`, 157 cas). Le device physique reste à mesurer.

Point de départ, premier appel à l'ajout rapide :

```
session ONNX init      : 248 ms   (Mac ; 1-3 s attendues sur Android)
tokenizer.json parse   : 287 ms   (parseur C ; en Dart sur l'isolate UI, plusieurs secondes)
inference              : 10.7 ms
```

## 2. Graphe dynamique + buckets 8/16/32/64 — fait

Le graphe ONNX était figé à `[batch, 64]` et `QuickAddTokenizer` padait toujours à 64, pour une
saisie de 4 tokens en médiane (p90 : 6). Les positions de bourrage sont masquées dans l'attention
et exclues du mean pooling : c'était du calcul sans effet sur la sortie.

- `export_onnx.py` : axe `sequence` dynamique, trace à 16 tokens pour ne rien figer
- `QuickAddTokenizer` : `lengthBuckets = [8, 16, 32, 64]`, padding au plus petit palier qui contient
  la saisie. Des paliers plutôt que la longueur exacte, pour qu'ORT réutilise ses buffers au lieu
  d'en réallouer à chaque forme inédite.

**Gain ×4.6** (10.7 → 2.3 ms, mono-thread), **157/157 prédictions identiques** au graphe figé,
vérifié à chaque palier. 156 cas sur 157 tombent dans le bucket 8.

Effet de bord corrigé : `flutter_onnxruntime` met l'asset extrait en cache dans le dossier
temporaire sous son seul nom de fichier. Un modèle republié sous le même nom n'aurait jamais été
relu sur une installation existante — l'app aurait continué à tourner sur l'ancien après mise à
jour. L'asset porte donc sa version (`model_v2.onnx`, à incrémenter à chaque modèle) et
`QuickAddModelRunner.load()` supprime les extractions des versions précédentes, qui pèsent 142 Mo
chacune.

## 3. Tokenizer : format binaire — fait

`QuickAddTokenizer.load()` faisait, sur l'isolate qui dessine : décodage UTF-8 de 33 MB,
`json.decode`, puis construction de deux tables de hachage de 256 000 et 580 604 entrées. Mesuré à
**561 ms à froid** (host Dart) — dont 211 ms de `json.decode` et 167 ms de construction des clefs
de merges. L'encodage, lui, ne coûtait rien : 0,05 ms.

Le coût étant entièrement dans la construction des tables, elles ont disparu. Le format binaire
(`assets/models/tokenizer.bin`, `QuickAddTokenizerFormat`) stocke le vocabulaire trié par octets et
les fusions triées par paire d'identifiants ; `encode()` fait des recherches dichotomiques
directement dans le `Uint8List`, sans jamais matérialiser une entrée.

| | avant | après |
|---|---|---|
| `load()` | 561 ms | **8,7 ms** |
| `encode()` | 0,05 ms | 0,09 ms |
| asset | 33 MB | **10,4 MB** |

Les fusions désignent leurs deux moitiés par identifiant plutôt que par texte — un BPE entraîné ne
fusionne que des tokens du vocabulaire, ce que la génération confirme (0 fusion écartée sur
580 604). Comparer deux entiers évite de reconstruire une clef texte à chaque comparaison.

Le déport sur un isolate devient inutile : 8,7 ms sur le thread UI ne se voient pas.

Régénération après ré-entraînement :
`dart run tool/model/build_tokenizer_asset.dart <tokenizer.json> assets/models/tokenizer.bin`.

Validation : `test/fixtures/tokenizer_golden.json` capture l'encodage de 168 entrées avec
l'implémentation JSON d'origine (corpus complet + cas limites : chaînes vides, non-ASCII, CJK,
troncature). Le test golden échoue à la moindre divergence — le modèle doit recevoir exactement ce
qu'il recevait à l'entraînement.

## 3 bis. Modèle hors dépôt — fait

Les deux workflows faisaient `lfs: true` : chaque run de CI tirait 176 MB d'objets LFS, dont
`ci.yml` cinq fois (matrice de 5 jobs). La bande passante LFS consommée depuis Actions compte dans
le quota, 1 Go/mois en gratuit.

Le modèle vit maintenant dans les release assets, qui ne sont pas facturés :

- `tool/model/lock.env` — dépôt, release, nom de l'asset, SHA-256. Versionné, donc un vieux commit
  récupère le modèle qu'il attend.
- `tool/model/fetch.sh` — télécharge si absent ou non conforme, vérifie l'empreinte, sort en erreur
  sinon. Appelé par les deux workflows de release avant `flutter build`, avec un `actions/cache`
  clé sur `tool/model/lock.env`.
- `tool/model/publish.sh` — régénère le tokenizer, dépose le modèle sous la version suivante, crée
  la release, réécrit le lock. Refuse un tag existant.
- `QuickAddModelRunner` lit le nom du modèle dans le manifeste des assets plutôt que dans une
  constante : publier n'a qu'un endroit à mettre à jour, et un modèle absent — `tool/model/fetch.sh`
  oublié — échoue avec un message explicite au lieu de casser chez l'utilisateur.
- `assets/models/*.onnx` et `assets/models/tokenizer.json` passent dans `.gitignore`.
- `ci.yml` n'a besoin de rien : aucun test ne charge le vrai ONNX,
  `quick_add_model_runner_test.dart` mocke `OnnxRuntime`.

LFS ne porte plus que `tokenizer.bin`, 11 MB. Les ~440 MB déjà dans l'historique LFS y restent :
seuls les futurs modèles échappent au quota.

Piège à connaître : `pubspec.yaml` déclare `assets/models/` comme dossier, pas fichier par fichier.
Un modèle absent ne casse donc pas le build — l'APK part sans modèle et l'app échoue au premier
ajout rapide. D'où la vérification d'empreinte qui fait échouer le job.

## 4. Warm-up — fait

Le moteur se chargeait au premier caractère tapé : `quick_add_bar.dart` → `onInputChanged` →
debounce 200 ms → `_analyze` → `quickAddEngineProvider`. Rien ne le préchargeait.

`quickAddWarmUpProvider` est lu dans `SplashScreen.initState()`. Le splash dure 2 200 ms, le
chargement complet en prend ~810 ms sur host : il tient largement, et l'ajout rapide est prêt avant
que l'utilisateur atteigne le dashboard.

Deux garde-fous :

- il respecte `quickAddEnabledProvider` — charger 142 Mo pour une fonctionnalité coupée serait du
  gâchis ;
- il n'expose pas son échec. L'ajout rapide n'est pas ce qui doit empêcher l'app de démarrer, et
  l'erreur se représente d'elle-même au premier usage, avec son message.

Le point 3 devait précéder celui-ci : sans lui, précharger au splash aurait déplacé le gel de
560 ms du tokenizer sur l'animation du splash au lieu de le supprimer. La session ONNX, elle, part
sur un thread natif — visible dans la stack trace du plugin — et ne gèle rien.

## 5. Ne pas invalider le moteur local quand seul le distant change — à faire

`quickAddEngineProvider` `watch` le classifieur local et la configuration distante dans le même
provider. Les quatre `ref.invalidate(quickAddEngineProvider)` des écrans de réglages (clé API,
modèle, mode moteur) rechargent donc aussi le modèle embarqué — plusieurs secondes pour un
changement qui ne le concerne pas. Séparer les deux, ou sortir le local du chemin invalidé.

## Reste

- Options de session ORT (XNNPACK/NNAPI, `intraOpNumThreads`) : non configurées, `OnnxRuntime()` nu
- Cache de classification par `cleanedText` : le debounce relance une inférence complète même quand
  seul le montant a changé
