# Quick-Add — optimisations perf

Mesures CPU Mac (int8, `eval_corpus.json`, 157 cas). Le device physique reste à mesurer.

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

## 3. Tokenizer : format binaire + hors isolate UI — à faire

`QuickAddTokenizer.load()` fait aujourd'hui, sur l'isolate qui dessine :

```dart
rootBundle.loadString(assetPath)   // décodage UTF-8 de 33 MB
json.decode(jsonStr)               // arbre JSON complet en mémoire
rawVocab.map(...)                  // 256 000 entrées, recopiées dans une 2e map
for (i in 580 604 merges)          // 580k concaténations '${pair[0]} ${pair[1]}'
```

Deux leviers cumulables :

- **Format binaire pré-calculé** (script de build dans `tool/`, régénéré depuis `tokenizer.json` à
  chaque ré-entraînement) : lecture d'un `Uint8List` + balayage linéaire. Pas de parseur JSON, pas
  d'arbre intermédiaire, les paires de merges deviennent des paires d'entiers. Fichier attendu :
  33 MB → 5-8 MB.
- **Déport sur un isolate** : à ne faire qu'en renvoyant un buffer compact. Renvoyer les deux maps
  (256k et 580k entrées) coûterait une copie du même ordre de grandeur que le parsing économisé.

Le premier suffit probablement à rendre le second inutile. Mesurer `load()` en Dart sur device
avant de choisir — les 287 ms Python sont un plancher qui ne dit rien du coût réel.

## 4. Warm-up — à faire

Le modèle se charge au premier caractère tapé : `quick_add_bar.dart` → `onInputChanged` → debounce
200 ms → `_analyze` → `quickAddEngineProvider`. Rien ne le précharge. Déclencher
`ref.read(quickAddEngineProvider.future)` en fire-and-forget au splash ou au montage du dashboard
sort le chargement du chemin critique.

## 5. Ne pas invalider le moteur local quand seul le distant change — à faire

`quickAddEngineProvider` `watch` le classifieur local et la configuration distante dans le même
provider. Les quatre `ref.invalidate(quickAddEngineProvider)` des écrans de réglages (clé API,
modèle, mode moteur) rechargent donc aussi le modèle embarqué — plusieurs secondes pour un
changement qui ne le concerne pas. Séparer les deux, ou sortir le local du chemin invalidé.

## Reste

- Options de session ORT (XNNPACK/NNAPI, `intraOpNumThreads`) : non configurées, `OnnxRuntime()` nu
- Cache de classification par `cleanedText` : le debounce relance une inférence complète même quand
  seul le montant a changé
