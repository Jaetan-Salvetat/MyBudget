# Quick-Add AI

Catégorisation intelligente du quick-add via LLM. Stratégie hybride **on-device / cloud** selon les capacités du téléphone.

## Objectif

Transformer un input langage naturel français en transaction structurée :

```
"j'ai filé 20 balles à ma sœur pour le cadeau de maman"
→ { type: "expense", name: "Cadeau maman", amount: 20.0,
    category: "Cadeaux", beneficiary: "ma sœur" }
```

## Stratégie : 2 modèles selon config device

### 🥇 On-device : Gemma 4 E2B (~2 GB)

**Cible** : téléphones modernes (Android 12+, ≥ 4 GB RAM libre, GPU Adreno/Mali récent).

- Inférence locale via **MediaPipe LLM Inference** (Google officiel)
- Format `.task`, téléchargé on-demand au 1er lancement
- Latence cible : 1-3s sur device récent
- 100% offline une fois téléchargé
- Score benchmark : **8.5/10**

### ☁️ Cloud fallback : DeepSeek V4 Flash

**Cible** : téléphones incompatibles (vieux, peu de RAM, pas de GPU), ou échec/timeout du modèle local.

- API via **OpenRouter** (`deepseek/deepseek-v4-flash`)
- Latence : 3-5s (dépend du réseau)
- Coût marginal par requête
- Nécessite connexion internet
- Score benchmark : **9/10**

## Sélection du modèle au runtime

```
QuickAddInput
  │
  ├─ DeviceCapabilityChecker
  │   ├─ Android ≥ 7.0
  │   ├─ RAM libre ≥ 3 GB
  │   └─ GPU disponible
  │
  ├─ [compatible] → Gemma 4 E2B (on-device)
  │     ├─ Lazy load au focus du champ
  │     ├─ Unload après inactivité
  │     └─ Fallback cloud si timeout > 5s
  │
  └─ [incompatible] → DeepSeek V4 Flash (cloud)
```

## Fichiers concernés (à créer)

- `lib/core/services/ai/quick_add_ai_service.dart` — façade publique
- `lib/core/services/ai/on_device_inference_service.dart` — Gemma 4 E2B via MediaPipe
- `lib/core/services/ai/cloud_inference_service.dart` — DeepSeek via OpenRouter
- `lib/core/services/ai/device_capability_checker.dart` — détection device
- `lib/core/services/ai/model_downloader.dart` — gestion .task download/cache

## Benchmark complet

Voir [memory/project_quick_add_model_benchmark.md](.claude/projects/.../memory/project_quick_add_model_benchmark.md) — 10 modèles testés (Phi-3 mini, Qwen3 0.6B/1.7B, Llama 3.2 1B/3B, Gemma 3 1B, Gemma3n e2b, SmolLM3 3B, Gemma 4 E2B, DeepSeek V4 Flash).

## Prompt utilisé

Voir `/tmp/quick_add_tests/prompt.txt` — JSON strict avec enum de catégories `[Alimentation, Transport, Logement, Loisirs, Santé, Cadeaux, Abonnements, Salaire, Remboursement, Famille, Autre]`.

## Status

- [x] Benchmark modèles
- [x] Choix des 2 modèles (Gemma 4 E2B + DeepSeek V4 Flash)
- [ ] Intégration MediaPipe LLM Inference (Android)
- [ ] Intégration OpenRouter API
- [ ] Device capability detection
- [ ] UX quick-add input
- [ ] Cache `.task` + version checking
- [ ] Tests unitaires + intégration
