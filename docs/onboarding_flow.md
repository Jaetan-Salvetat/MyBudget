# Onboarding Flow

## Principe

AI-first : zéro slide, zéro config catégorie, droit au quick-add. Le budget se construit à l'usage.

## Flow

```
Install
  │
  ▼
Écran 1 : "Quel est ton compte principal ?"
  │  Form minimal : nom + banque (autocomplete) + solde initial
  │
  ▼
Écran 2 : Quick-add
  │  Champ texte, placeholder "Loyer, café, abonnement..."
  │  Pas de catégories visibles. Pas d'explication.
  │
  ▼
User tape "loyer 800€"
  │
  ▼
Pipeline ML → carte de confirmation
  │  "Loyer ajouté. 800 €/mois. 🏠 Loyer"
  │
  ▼
1 tap confirme → dashboard apparaît avec la 1ère entrée
```

## Séquence Install → Aha Moment

| Étape | Temps | Ce que voit l'user |
|---|---|---|
| Install | 0s | Store → téléchargement |
| Premier écran | 10s | Form compte (3 champs) |
| Premier input | 30s | Champ texte quick-add |
| Première suggestion | 31s | Carte pré-remplie (100ms CamemBERT + 0.7s Gemma) |
| Premier confirm | 32s | Dashboard avec 1 entrée |
| Aha moment (J+2) | — | Dashboard avec des vrais chiffres, catégories auto-créées |

## Empty state

Il n'y en a pas. Le champ texte quick-add EST l'empty state. Pas de dashboard vide avec "Ajoutez votre première transaction".

## Catégories par défaut

Supprimées. L'app démarre avec zéro catégorie. Elles se créent au fil des entrées via le category flow.

## Warm-up modèle

Pendant que l'user remplit le form compte (~30s), charger CamemBERT + Gemma en mémoire en background. Quand le quick-add s'affiche, les modèles sont prêts.

```
Form compte affiché
  │
  ▼ (background, parallèle)
[LOAD] CamemBERT → RAM (~2s)
[LOAD] Gemma 0.5B → RAM (~3s)
  │
  ▼
User finit le form → quick-add prêt, 0 cold start
```

## Migration users existants

| Phase | Action |
|---|---|
| Feature flag ON (nouvelles installations) | Nouveau onboarding pour les nouveaux users uniquement |
| Banner opt-in (settings) | Users existants peuvent essayer le nouveau flow |
| Default ON | Nouveau flow par défaut, ancien = "Mode avancé" |
| Cleanup | Suppression ancien onboarding |

Les catégories et transactions existantes sont conservées. Le nouveau flow s'applique uniquement aux nouvelles entrées.
