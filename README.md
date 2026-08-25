# MyBudget

Une app Android pour **gérer ton budget perso simplement** — dépenses fixes, revenus, emprunts, transferts, le tout en local sur ton téléphone.

Pas de compte à créer, pas de serveur, aucune donnée ne sort de ton appareil.

## Ce que tu peux faire

**Tableau de bord**
- Solde net, taux d'épargne, totaux mensuels en un coup d'œil
- Navigation par mois pour comparer les périodes
- Répartition des dépenses par catégorie avec pourcentages
- Prochaines échéances à venir

**Comptes bancaires**
- Gère plusieurs comptes avec leur solde calculé automatiquement
- Détail par compte : dépenses, revenus, transferts entrants/sortants

**Dépenses & revenus**
- Ajoute des charges et revenus mensuels, annuels ou ponctuels
- Les dépenses annuelles sont lissées sur 12 mois
- Catégories personnalisables (icône + couleur)
- Bénéficiaires associables à chaque opération
- Filtres avancés : recherche, catégorie, compte, montant, fréquence

**Scan de tickets de caisse**
- Prends en photo un ticket ou importe-le depuis ta galerie
- L'IA (Gemini) extrait les articles, montants et catégories automatiquement
- Vérifie et ajuste avant de valider — tout est créé en une seule fois
- Possibilité d'utiliser ta propre clé API Gemini

**Emprunts**
- Création guidée pas à pas
- Prêts amortissables et in fine
- Gestion du différé de remboursement et de l'assurance emprunteur
- Suivi détaillé : capital restant, mensualités, tableau d'amortissement, progression

**Transferts**
- Planifie des virements récurrents entre tes comptes
- Pris en compte automatiquement dans le solde de chaque compte

**Personnalisation**
- 7 couleurs au choix + couleur dynamique (Material You)
- Mode clair, sombre ou automatique

**Tes données**
- Import / export complet en JSON
- Réinitialisation depuis les paramètres
- Mises à jour automatiques depuis GitHub
- Widget sur l'écran d'accueil

**Aide & feedback**
- Guide d'utilisation intégré
- Formulaires de signalement de bug et de suggestion directement dans l'app

## Télécharger

Récupère la dernière version (APK) sur la page [Releases](https://github.com/Jaetan-Salvetat/MyBudget/releases).

Une version **beta** est aussi disponible pour tester les nouveautés en avant-première.

## Développement

**Prérequis** : Flutter 3.47.1, Git LFS (`brew install git-lfs && git lfs install`), JDK 17.

```bash
git clone https://github.com/Jaetan-Salvetat/MyBudget.git
cd MyBudget
git lfs pull            # tokenizer de l'ajout rapide (~11 Mo)
flutter pub get
./tool/model/fetch.sh   # modèle du classifieur (~142 Mo)
flutter run --flavor dev
```

`./tool/model/fetch.sh` n'est pas optionnel. Le modèle ONNX vit dans les
[release assets](https://github.com/Jaetan-Salvetat/MyBudget/releases) plutôt que dans le dépôt :
142 Mo par version que LFS facturerait en stockage et en bande passante à chaque checkout de CI.
Sans lui, le build passe et l'APK se construit — mais l'app échoue au premier ajout rapide, parce
que `assets/models/` est déclaré comme dossier dans `pubspec.yaml` et qu'un fichier manquant ne
casse rien à la compilation. Le script vérifie l'empreinte SHA-256 décrite dans `tool/model/lock.env`
et sort en erreur si elle ne correspond pas.

### Publier un nouveau modèle

Après un ré-entraînement (`ml/classifier/`) :

```bash
cd ml/classifier && python -m training.export_onnx && cd ../..
./tool/model/publish.sh          # ou ./tool/model/publish.sh v5 pour imposer la version
flutter test
```

Le script régénère `tokenizer.bin` depuis le tokenizer d'entraînement, dépose le modèle sous la
version suivante, crée la release GitHub avec le modèle et la source du tokenizer, et réécrit
`tool/model/lock.env`. Il refuse de publier sur un tag existant. Restent à committer : `tool/model/lock.env`
et `assets/models/tokenizer.bin`.

Aucun code n'est à éditer : `QuickAddModelRunner` lit le nom du modèle dans le manifeste des
assets, et échoue avec un message explicite si `assets/models/` n'en contient aucun — ou plusieurs.

**La version dans le nom du fichier n'est pas cosmétique.** `flutter_onnxruntime` extrait l'asset
dans le dossier temporaire et le met en cache sous son seul nom de fichier : republier un modèle
sous un nom déjà utilisé laisserait toutes les installations existantes tourner sur l'ancien après
mise à jour, sans erreur visible. `QuickAddModelRunner` supprime au chargement les extractions des
versions précédentes, qui pèsent autant que le modèle.

Garder `QuickAddLabels` synchronisé avec l'ordre des labels du training. Le golden
`test/fixtures/tokenizer_golden.json` vérifie que le tokenizer binaire encode exactement comme le
`tokenizer.json` d'origine.
