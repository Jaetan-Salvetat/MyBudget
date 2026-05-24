# MyBudget — Architecture Flows

## Modèles ML

| Modèle | Taille | Latence | Rôle |
|---|---|---|---|
| CamemBERT INT8 | ~110 MB | ~100ms | NER, type, fréquence, tags sémantiques |
| Gemma 0.5B INT4 LoRA | ~300 MB | ~0.5-0.7s | Catégorisation, icône, normalisation nom |

Total on-device : ~410 MB.

## Features

| Feature | Flow doc | Méthode principale | Layer dominant |
|---|---|---|---|
| Quick-Add | [quick_add_flow.md](quick_add_flow.md) | CamemBERT + Gemma LoRA | 1 (confirm) |
| Categories | [category_flow.md](category_flow.md) | LLM (nom/icône) + algo (color/dedup) | 0 |
| Correction Memory | [correction_memory_flow.md](correction_memory_flow.md) | ObjectBox cache | 0 |
| Beneficiaries | [beneficiary_flow.md](beneficiary_flow.md) | NER + fuzzy match | 1 |
| Loans | [loan_flow.md](loan_flow.md) | Form + algo (amortization) | 3 |
| Transfers | [transfer_flow.md](transfer_flow.md) | Form + prefs | 3 |
| Accounts | [account_flow.md](account_flow.md) | Form + autocomplete | 3 |
| Dashboard | [dashboard_flow.md](dashboard_flow.md) | Algo pur | 0 |
| Receipt Scan | [receipt_scan_flow.md](receipt_scan_flow.md) | LLM Vision (futur) | 0-1 |
| Onboarding | [onboarding_flow.md](onboarding_flow.md) | AI-first, zero config | 2 |
| Import/Export | [import_export_flow.md](import_export_flow.md) | Algo pur | 1-2 |
| Auto-Update | [auto_update_flow.md](auto_update_flow.md) | Algo pur | 0 |
| Home Widget | [home_widget_flow.md](home_widget_flow.md) | Algo pur | 0 |
| Settings | [settings_flow.md](settings_flow.md) | Manuel | 3 |

## Layers

| Layer | Définition | Après pivot |
|---|---|---|
| 0 — Zero input | Aucune action user | 21 sub-tasks |
| 1 — One tap | 1 tap de confirmation | 16 sub-tasks |
| 2 — Minimal input | Saisie minimale (montant, nom) | 6 sub-tasks |
| 3 — Full manual | Form complet | 9 sub-tasks |

## Impact mensuel (60 dépenses, 4 revenus, 1 virement)

| | Avant | Après | Économisé |
|---|---|---|---|
| Taps/mois | ~398 | ~75 | ~323 |
