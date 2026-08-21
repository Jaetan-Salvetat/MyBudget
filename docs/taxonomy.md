# Taxonomie des catégories

## Contrat

`assets/categories.json` est la **source de vérité unique** : 15 groupes, 75 sous-catégories.
Aucune catégorie n'est stockée en base, aucune n'est créée par l'utilisateur.

Une transaction référence un **slug** `groupe.sous_categorie` (ex. `restauration.cafe`).
Format imposé : `[a-z0-9_]+` de chaque côté du point.

Le modèle ONNX produit un **index**, pas une chaîne. `QuickAddLabels.categories[index]`
fait la traduction. **L'ordre de cette liste est le contrat avec le modèle** : elle est
générée, jamais éditée à la main.

```
dart run tool/generate_taxonomy_labels.dart            # régénère quick_add_labels.dart
dart run tool/generate_taxonomy_labels.dart --stdout   # liste ordonnée pour le training
```

`categories.json`, `assets/models/model.onnx` et `quick_add_labels.dart` forment **un seul
artefact versionné**. Le champ `version` est contrôlé contre
`CategoryTaxonomyService.expectedVersion` au chargement : un mismatch lève une exception
plutôt que de produire un mapping silencieusement faux.

## Faire évoluer la taxonomie

| Changement | Coût | Règle |
|---|---|---|
| `label`, `icon`, `color` | Aucun | Éditer le json, ship |
| Ajouter une sous-catégorie | Ré-entraînement | **Append-only** en fin de groupe : les index existants restent stables |
| Supprimer, renommer ou déplacer un slug | Ré-entraînement | **Interdit** — voir ci-dessous |

Un slug ne meurt jamais : les transactions historiques le référencent. Pour retirer un
nœud, on le déprécie sans le supprimer :

```json
"logement.assurance": { "deprecated": true, "alias_of": "finance.assurance_habitation" }
```

`resolve()` suit l'alias — l'historique s'affiche correctement, le picker masque le nœud,
le modèle ne le prédit plus. Aucune migration de base, jamais.

Toute modification impose de bumper `version` et de régénérer les labels.

## Implémentation dans l'app

Aucune catégorie n'est stockée en base. `CategoryTaxonomyService` charge l'arbre en mémoire
au démarrage et l'expose via `categoryTaxonomyProvider`.

```
ExpenseModel.categorySlug = "restauration.cafe"   (String?, @Index)
  ├─ affichage transaction  → feuille : « Café », icône local_cafe
  ├─ agrégation dashboard   → groupe  : split('.').first → « Restauration »
  └─ picker                 → CategoryPickerSheet, deux niveaux
```

Le parent n'est **jamais stocké** : deux champs peuvent diverger, et déplacer un nœud
imposerait alors une migration de données. Il se dérive — mais **via la taxonomie, jamais
par `split('.')`** : un nœud déplacé garde son ancien slug et n'appartient plus au groupe
que ce slug épelle.

```dart
resolver.groupKeyOf('logement.assurance')  // → 'finance'   (suit alias_of)
'logement.assurance'.split('.').first      // → 'logement'  (faux après déplacement)
```

`CategoryDisplayResolver.groupKeyOf` est le seul point d'entrée autorisé pour l'agrégation
et le filtrage.

| Élément | Rôle |
|---|---|
| `CategoryTaxonomyService` | arbre depuis l'asset, `resolve` / `group` / `leaves` |
| `CategoryOverrideModel` | table creuse `(slug @Unique, name?, icon?, color?)` |
| `CategoryDisplayResolver` | fusionne taxonomie + overrides → `CategoryDisplay` |
| `categoryDisplayResolverProvider` | point d'entrée unique côté UI |

Une ligne d'override n'existe que si l'utilisateur a effectivement personnalisé quelque
chose ; `CategoryOverrideRepository.save` supprime la ligne quand elle redevient vide.
Une couleur posée sur un groupe cascade sur ses feuilles ; une couleur posée sur une
feuille l'emporte sur son groupe.

## Personnalisation utilisateur

Autorisée : renommer un nœud, changer son icône, changer sa couleur — groupes et feuilles.
Accessible par Settings → Catégories, un arbre en lecture seule.

Interdite : créer, supprimer, fusionner. La structure est le contrat avec le modèle —
l'ouvrir revient à produire des catégories que le modèle ne pourra jamais prédire.

L'échappatoire n'est pas la création de catégorie mais le **seuil de confiance** et la
**mémoire de correction**. Sous `QuickAddResultModel.categoryConfidenceThreshold` (0.6), la
carte de confirmation marque la catégorie « à confirmer » et ouvre le picker amorcé sur le
top-3 du modèle (`QuickAddClassification.categorySuggestions`).

## Mémoire de correction

Le modèle plafonne autour de 96 %. La mémoire ne l'améliore pas : elle fait que chaque
erreur n'est vue **qu'une fois**.

```
"macdo 12"  →  PriceParser  →  "macdo"  →  normalisation  →  clé
                                    modèle → restauration.fast_food
                                    mémoire["macdo"] → écrase si présente
```

Elle s'applique **après** le modèle, pas à sa place : la correction utilisateur ne portait
que sur la catégorie, les têtes type et récurrence doivent continuer à tourner. L'inférence
fait ~50 ms on-device, court-circuiter n'achèterait rien et figerait trois dimensions au
lieu d'une.

`CategoryMemoryService.normalizeKey` : minuscules, accents retirés, espaces collapsés. Le
match est **exact** — « macdo » ne rattrape pas « macdo avec Paul ». Un match par tokens
généraliserait mais ouvrirait les faux positifs, et un faux positif silencieux est pire
qu'un miss.

| Champ | Rôle |
|---|---|
| `key` `@Unique` | texte normalisé |
| `slug` | catégorie retenue |
| `corrections` | nombre d'éditions |
| `useMemory` | la mémoire répond-elle ; basculé à false à la 5ᵉ édition, et nulle part ailleurs |
| `updatedAt` | éviction LRU au-delà de `maxEntries` (500) |

**À la 5ᵉ édition l'entrée est retirée** : le slug cesse d'être mis à jour et `useMemory`
passe à false, donc `recall` ne répond plus. C'est le cas des clés sans bonne réponse —
« amazon » peut être n'importe quoi. Sans ça la mémoire apprend la dernière réponse et la
rejoue avec assurance. Le compteur continue de monter, mais rien ne rebascule `useMemory`.

La mémoire est de la donnée utilisateur : effacée par « supprimer toutes les données »,
incluse dans l'export sous `categoryMemory`. Sans ça une restauration referait toutes les
erreurs déjà corrigées.

## Revenus

`RevenueModel.categorySlug` fonctionne comme celui des dépenses, sur les 4 groupes de
revenus. Le picker s'ouvre avec `type: TransactionType.income`, le quick-add remplit le
slug, la ligne l'affiche.

Le dashboard n'a **pas** de breakdown des revenus par source : les données sont là, l'écran
reste à faire.

## Transactions sans catégorie

Un `categorySlug` null, ou un slug que la taxonomie ne connaît plus, tombe dans
`CategoryDisplayResolver.uncategorizedKey` — un bucket gris « Non catégorisé » visible dans
le breakdown et filtrable.

Les ignorer ferait disparaître le montant du breakdown tout en le laissant dans le total :
les segments ne sommeraient plus à 100 % sans que rien n'explique l'écart.
`groupKeyOrUncategorized` est la définition unique de « pas de catégorie », pour que
l'agrégation et le filtrage ne puissent pas diverger.

## Décisions structurantes

**Les abonnements sont classés par nature de dépense, pas par mode de paiement.** Netflix
tombe dans `loisirs.streaming`, la fibre dans `logement.telecom`, la salle de sport dans
`loisirs.sport`. Un groupe « Abonnements » regrouperait des dépenses sans rapport entre
elles et viderait de leur sens les groupes existants. Le caractère récurrent est déjà porté
par `Frequency`, qui est une dimension indépendante de la catégorie.

**Les assurances sont regroupées dans `finance`**, y compris l'assurance habitation et la
mutuelle santé, plutôt qu'éclatées dans `logement` et `sante_beaute`. Ce sont des contrats
de même nature, comparables entre eux.

**`sante_beaute` reste un groupe unique** malgré la différence entre soin et confort : le
séparer doublerait le nombre de groupes pour un gain de lisibilité nul sur le dashboard.

**Il n'y a pas de sous-catégorie `autre` par groupe.** Elles demanderaient des exemples
d'entraînement artificiels et deviendraient des attracteurs qui absorbent de vraies
prédictions. Le filet est le seuil de confiance : sous le seuil, aucune assignation
automatique, le picker s'ouvre sur le top-3. `divers.autre` reste le dernier recours.
