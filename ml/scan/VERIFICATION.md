# Vérification du scan LOCAL — spec d'implémentation app

Référence pour intégrer le pipeline (`ml/scan/pipeline`, package
`receipt_pipeline`) dans MyBudget. Périmètre : **le mode LOCAL uniquement**.
Le scan est un réglage exclusif LOCAL ou CLOUD ; le mode cloud existant
(`ReceiptScanService`) ne bouge pas, il n'y a **pas d'escalade automatique**
entre les deux. Les chiffres viennent de `test/analysis/bench_local.py`
(1000 tickets FindIt, vérité golden).

> **Décision produit 2026-08-24 : jamais de validation directe.** Tout scan
> atterrit sur l'écran d'édition pré-rempli ; les étages et le checksum
> décrits ici servent uniquement à *afficher* un niveau de confiance (badge
> « vérifié » / bandeau d'alerte avec delta). Le texte ci-dessous parle
> encore de « validation directe » : lire « vérifié ». Réécriture complète
> prévue avec le refactor du flow (étage classifieur + décodeur dans
> `decide()`).

## Le principe

Le ticket contient sa propre preuve : `Σ(articles − remises) = total
imprimé`. Le pipeline ne valide automatiquement une extraction que si cette
égalité tombe juste (au demi-centime). Ses erreurs sont des articles
manqués, jamais des montants inventés — donc un checksum qui passe est un
signal fort, et un checksum qui échoue est **toujours détecté**, jamais
silencieux. Tout raffinement (retry, classifieur, référence de secours) ne
peut que *sauver* des tickets flagués : le checksum reste le juge final.

Références acceptées pour l'égalité :
1. le **total** lu (dernière ligne « total » du ticket, hors TVA/HT — sauf
   mention « TVA INCL ») ;
2. le **sous-total** (tickets US, hors taxe) ;
3. uniquement si **aucun total n'a été lu** : la ligne **carte bancaire**,
   la **somme des TTC de la table TVA**, un **total sans séparateur
   décimal** (« 2790 » = 27,90) ou un **prix orphelin** de fin de ticket ;
4. exception unique au point 3 : CB + compteur « N ARTICLE(S) » concordant
   peuvent passer outre un total lu mais faux.

Règle absolue : **une référence de secours ne doit jamais outrepasser un
total lu qui ne colle pas** (faux positifs mesurés sinon).

## Le flow de décision

```
photo → OCR → règles → checksum OK ?                       → LOCAL     : vérifié
  non → classifieur argmax → re-checksum OK ?              → LOCAL_ML  : vérifié
  non → décodage sous contrainte → checksum OK ?           → LOCAL_DP  : vérifié
  non → prétraitement (autocontrast+unsharp+2400px) → 2e OCR
        → règles (somme retry ≥ somme passe 1) ?           → LOCAL_RETRY
        → classifieur → décodeur sur la 2e passe           → LOCAL_ML / LOCAL_DP
  non →                                                      CONFIRM   : non vérifié, bandeau
```

Tout atterrit sur l'écran d'édition pré-rempli ; le stage pilote seulement
badge vs bandeau. Le retry est l'étage cher (2e OCR) : mesuré, le lancer
après le classifieur divise les retries par deux à précision égale.

Paramètres calibrés (ne pas changer sans re-bencher) :
- tolérance checksum : **0,005 €** strict ;
- **garde-fou retry** : un retry dont la somme d'articles est inférieure à
  celle de la passe 1 est refusé même si son checksum passe (collision de
  substitution : article perdu + total mal lu qui retombe pile) ;
- pré-remplissage CONFIRM : la meilleure passe locale (retry si tenté,
  sinon passe 1).

## Garanties mesurées (pire-cas FindIt, 1000 tickets)

| Étage | Part | Faux montants validés |
|---|---|---|
| LOCAL (règles) | ~71 % | 0 |
| LOCAL_RETRY | ~2 % | 0 |
| LOCAL_ML (classifieur V2) | ~5 % | 0 |
| CONFIRM | ~21 % | — (l'utilisateur vérifie) |

Ce corpus est une borne basse (thermiques 2017 pâlis, formats cantine/
balance) : le tier « photo correcte d'un ticket frais » est à 100 % de
checksum. Un seul vrai faux validé sur 1000 (ticket au prix aberrant
19 950 € avec double collision de chiffres) ; les autres signalés du bench
sont des artefacts de convention golden (lignes 0 €, subvention en article
négatif vs remise). Plafond corpus : 94,8 % des golden sont checksummables.
L'OCR ML Kit est identique inter-devices (99,7 % de textes strictement
égaux S9+ 2018 vs Pixel 8 Pro) : la seule variable réelle est la qualité de
la photo — la capture app doit soigner résolution et focus.

## Mapping UI

| Étage | Écran | Message |
|---|---|---|
| LOCAL / LOCAL_RETRY / LOCAL_ML / LOCAL_DP / LOCAL_FUSED | Aucun intermédiaire : la dépense part en création directe (flow `validateAndCreate` existant) | Optionnel : badge « Vérifié — la somme des articles correspond au total du ticket » |
| CONFIRM | Écran d'édition existant, pré-rempli | Bandeau expliquant **pourquoi** (voir ci-dessous) |

Bandeau CONFIRM — deux cas à distinguer :
1. **Total non trouvé** : « Le total du ticket n'a pas pu être lu — vérifie
   les articles. » (pas de delta affichable)
2. **Écart** : « La somme des articles (X €) ne correspond pas au total lu
   (Y €) — il manque probablement des articles. » Afficher le delta ; la
   précision étant structurellement à 100 %, l'écart signifie presque
   toujours un article manqué, pas un prix faux.

Erreurs techniques (différentes d'un checksum KO) :
- image indéchiffrable / OCR vide → message reprise photo (« Ticket
  illisible — rapproche-toi et évite les reflets ») ;
- échec technique du retry ou du classifieur → on continue avec les passes
  disponibles, jamais d'erreur montrée pour ça.

Le mode local ne demande ni clé API, ni réseau, ni cooldown : aucun de ces
états ne doit produire d'erreur dans ce mode.

## Invariants (à préserver dans l'app)

1. Le checksum est le seul juge : aucune sortie (règles, retry, classifieur)
   ne s'auto-valide sans lui.
2. Jamais d'auto-validation sur une référence de secours quand un total a
   été lu et ne colle pas (seule exception : CB + compteur d'articles).
3. Le retry ne se substitue à la passe 1 que s'il ne perd pas de valeur.
4. Le classifieur n'étiquette que des lignes : les montants sont recopiés de
   l'OCR, jamais générés — y compris en fusion des passes (`local_fused`),
   où chaque montant alternatif vient de l'autre passe OCR.
4b. Les invariants structurels (`analysis/invariants.py`) ferment l'espace
   de recherche sans modèle : ligne de taxe ou HT jamais article,
   récapitulatif de remises ignoré, total de rayon = somme courante, total
   final = dernier total lexical avant le premier paiement, sous-total
   référence seulement si aucune remise ne le suit. Références acceptées :
   total lu, décomposition TVA (HT + taxe à taux légal), espèces − rendu,
   Σ des totaux de rayon — fusionnées par montant.
4c. Le total affiché est `verified_total` : la référence qui a réellement
   vérifié la somme des articles, jamais un total lu qui ne colle pas.
4d. Ticket sans ligne d'article (parking, carburant) : un montant prouvé par
   une source arithmétique et une seconde source, sans candidat article ni
   compteur d'articles contraire, devient l'unique achat (nom = enseigne).
5. La catégorisation (BERT/quick-add) est hors périmètre : elle n'influence
   ni le checksum ni la décision d'étage, et une catégorie douteuse ne doit
   pas déclencher CONFIRM.
6. Tout changement de lexique, de règle ou de modèle passe par : tests du
   package (`dart test`) + parité (`check_parity.py`) + bench
   (`bench_local.py`, faux validés à zéro) avant merge.
