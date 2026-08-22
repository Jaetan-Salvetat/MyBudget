# Quick-Add Flow

## Architecture

Pipeline 100% on-device, déterministe hors modèle : regex + BERT multi-head ONNX. Une seule passe modèle, pas de LLM, pas de réseau.

```
Frappe (chaque caractère)
  │
  ▼ ~0ms
[REGEX] PriceParserService — extraction montant → chip montant
  │
  ▼ pause 200ms (debounce)
[BERT multi-head ONNX] type + catégorie (55 classes) + récurrence
  │
  ▼
[Taxonomie] classe → groupe (13 groupes user-facing) → chips catégorie / récurrence
  │
  ▼ Entrée ou bouton
Transaction créée · snackbar « Annuler » 5s
```

## Live preview

`QuickAddNotifier` tient un `QuickAddDraft` : ce que l'app comprend du texte en
cours. Les champs arrivent en deux temps.

- **Instantané** : le montant, par regex, à chaque frappe.
- **Après la pause** : le modèle, debouncé de 200ms. Une analyse dont la saisie
  a bougé est jetée (compteur de séquence), jamais appliquée en retard.

Entre deux analyses la catégorie connue est conservée : les chips se
rafraîchissent, elles ne clignotent pas.

`classify()` ne valide rien — un texte sans montant est classé quand même,
`amount` reste `null` et le draft n'est pas soumettable. La validation vit dans
`submit()`.

## Pas de carte de confirmation

Les chips **sont** la confirmation : la catégorie est lue avant l'envoi et se
corrige d'un tap. Dès que le modèle a répondu, `QuickAddCategoryZone` remplace
la répartition du mois par ses candidats (`categorySuggestions`, celui du
brouillon en tête) — corriger vaut mieux que relire le mois pendant qu'on tape.
La correction part dans la mémoire.
Envoyer crée la transaction directement ; `QuickAddSubmission` porte l'id créé
et la snackbar l'annule pendant 5s (`deletePermanently`, jamais la clôture
d'une récurrence).

## Modèle

| Élément | Valeur |
|---|---|
| Backbone | mmBERT-small (ModernBERT, 384 hidden dim) |
| Têtes | type (expense/income) · catégorie (55) · récurrence (ponctuel/fixe) |
| Format | ONNX int8, ~135 MB, embarqué dans les assets |
| Latence | ~100ms sur device |
| Scores | easy 100% · medium 100% · hard : type 100%, cat 80%, rec 96% |

## Couche 1 — Regex (~0ms)

`PriceParserService` : extraction du montant depuis le texte brut.

- Formats : `12`, `3,50`, `13.99`, `1 200`, `2,500.50`
- Strip : `€ $ £`, "balles", "euros", "dollars"…
- Plusieurs nombres → le dernier gagne (`"2 pizzas 24"` → 24)
- Aucun montant → `amount` null, bouton d'envoi désactivé

Le texte restant, nettoyé, sert d'input au modèle et de nom à la transaction (première lettre capitalisée).

## Couche 2 — BERT multi-head (~100ms)

`QuickAddTokenizer` (BPE, max_length 64) → `QuickAddModelRunner` (ONNX, 3 outputs en 1 pass) → argmax + softmax confidence par tête.

Les labels de sortie sont dans `QuickAddLabels` et doivent rester synchronisés avec l'ordre du training (`quick-add-3/multi-head-v1`).

## Couche 3 — Résolution catégorie

La classe prédite (`restauration.fast-food/friterie`) est réduite à son groupe (`restauration`) via `CategoryTaxonomyService` (`assets/categories.json` : label, icône, couleur par groupe).

- **Expense** : matching du groupe contre les catégories user (nom normalisé : minuscules, sans accents). Match → `categoryId`. Sinon → proposition "nouvelle catégorie" (badge sur la carte), créée à la confirmation avec l'icône/couleur de la taxonomie.
- **Income** : pas de catégorie (les revenus n'en ont pas), création d'un `RevenueModel`.

## Récurrence → Fréquence

| Prédiction | Fréquence |
|---|---|
| `ponctuel` | Ponctuel |
| `fixe` | Mensuel |

## Revenue vs Expense

Même pipeline, mêmes chips. Le type est prédit par le modèle (tête dédiée, 100%
sur le jeu de test) et décide du signe affiché comme de l'entité créée
(`RevenueModel` vs `ExpenseModel`).

## Place à l'écran

Voir `docs/dashboard_flow.md` — le champ vit sous le solde sur l'accueil, et la
mise en page bascule en mode saisie au focus.

## Sortir de la saisie

- La croix du champ **annule** : texte, brouillon et focus partent ensemble.
- Le bouton retour Android cache le clavier sans lâcher le focus, ce qui
  laisserait l'écran en mode saisie sans clavier : `didChangeMetrics` détecte la
  fermeture et défocalise. Le brouillon, lui, survit.
- Scroller ferme aussi le clavier (`keyboardDismissBehavior: onDrag`).

## Compte cible

`QuickAddAccountNotifier` : premier compte par défaut, garde le choix de l'user
tant que ce compte existe. Affiché sous le champ, tapable dès qu'il y a plus
d'un compte.

## Pistes futures

- **Sous-catégories** : la classe fine (55) est disponible dans `QuickAddClassification.category`, exploitable pour des stats plus fines.
- **Date** : le mockup prévoit une chip date (« aujourd'hui », « hier ») — pas encore parsée.
