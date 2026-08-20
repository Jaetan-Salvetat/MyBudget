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

## Personnalisation utilisateur

Autorisée : renommer un nœud, changer son icône, changer sa couleur. Stocké dans une table
creuse indexée par slug, écrite uniquement en cas de personnalisation effective.

Interdite : créer, supprimer, fusionner. La structure est le contrat avec le modèle —
l'ouvrir revient à produire des catégories que le modèle ne pourra jamais prédire.

L'échappatoire n'est pas la création de catégorie mais la **mémoire de correction** :
une correction utilisateur est mémorisée et rejouée avant le modèle.

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
