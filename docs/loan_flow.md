# Loan Flow

## Principe

Le contrat et les événements déclarés par l'utilisateur sont persistés. Tout le
reste est **dérivé** par une fonction pure `f(contrat, événements, date)` :
aucun worker, aucun état cumulé, aucun compteur incrémental. Ouvrir l'app tous
les jours ou dans trois ans donne exactement le même résultat, et corriger un
événement recalcule l'intégralité de l'échéancier depuis le contrat.

```
LoanModel (contrat)  +  LoanEventModel[] (remboursements anticipés)
                     │
                     ▼  LoanScheduleService.build()  — fonction pure
              LoanSchedule : List<LoanInstallment>
                     │
                     ▼
   Loan : CRD, mensualité, cumuls, coût total, TAEG, statut
```

## Ce qui est demandé vs ce qui est calculé

| Demandé (contractuel) | Calculé (jamais saisi) |
|---|---|
| Montant, taux nominal, durée, date de début, jour de prélèvement | Mensualité, échéancier complet, date de fin |
| Amortissable / in fine | Capital restant dû, cumuls capital / intérêts / assurance |
| Différé : nombre de mois **et type** (partiel / total) | Coût total du crédit, **TAEG** (IRR sur les flux) |
| Assurance : type, valeur, mode de calcul | Statut, progression, mois restants |
| Frais (dossier, garantie, courtage) | Montant de l'indemnité de remboursement anticipé |
| Type de prêt (prêt auto, prêt immobilier, …) | **Régime IRA**, dérivé du type et du montant |
| Absence de clause d'IRA au contrat | Économie et mois gagnés sur un remboursement anticipé |
| Compte de prélèvement | |

## Type de prêt et régime

On demande un **produit**, pas une qualification juridique : personne ne se dit
« je contracte un crédit à la consommation », on se dit « je prends un prêt
auto ». Exposer `Consommation / Immobilier` faisait renoncer l'utilisateur qui
ne reconnaissait pas son prêt dans la liste.

Le `CreditRegime` en est **dérivé**, jamais stocké : on persiste le fait le plus
riche et on en déduit le plus pauvre. De `car` on retrouve toujours `consumer`,
l'inverse est impossible.

| `LoanPurpose` | Régime | Pré-réglage |
|---|---|---|
| `mortgage` Prêt immobilier | Immobilier | — |
| `bridge` Prêt relais | Immobilier | In fine, indemnité décochée |
| `works` Prêt travaux | Seuil 75 000 € | — |
| `car` Prêt auto ou moto | Consommation | — |
| `personal` Prêt personnel, trésorerie | Consommation | — |
| `student` Prêt étudiant | Consommation | — |
| `instalmentPlan` Paiement en plusieurs fois | Consommation | Premier versement immédiat |
| `family` Prêt familial, entre particuliers | Seuil 75 000 € | Indemnité décochée |
| `other` Autre | Seuil 75 000 € | — |

Trois types dépendent du montant : un prêt travaux bascule en régime
immobilier au-delà de 75 000 €, et le suit si l'utilisateur corrige le montant —
un régime stocké serait resté périmé.

Valeur inconnue ou enregistrement antérieur → `other`, donc régime dérivé du
seuil : le repli ne met jamais une indemnité à zéro par accident.

Les pré-réglages ne font que **suggérer** : changer de type n'écrase jamais un
champ déjà réglé par l'utilisateur.

Hors périmètre : prêt professionnel (hors Code de la consommation, indemnité
purement contractuelle), LOA et leasing (une location, pas un prêt : ni capital
restant dû ni amortissement), rachat de crédits.

Le motif d'exonération d'IRA et le mode de ré-amortissement sont demandés **au
moment du remboursement anticipé**, pas à la création du prêt.

## Moteur d'échéancier

`LoanScheduleService` (`lib/core/services/loan_schedule_service.dart`) déroule
l'échéancier mois par mois, arrondi au centime, dernière échéance ajustée pour
solder exactement le capital.

| Phase | Traitement |
|---|---|
| Différé partiel | Intérêts + assurance payés, capital non amorti |
| Différé total | Assurance seule payée, intérêts capitalisés (amortissement négatif) |
| Amortissable | Annuité constante recalculée sur le capital en début de phase |
| In fine | Intérêts seuls, capital remboursé sur la dernière échéance |

Date d'échéance n : `dayOfMonth` du mois `startDate + n`, borné au dernier jour
du mois. Avec `immediateFirstPayment`, la première échéance tombe sur
`startDate` (paiement en 4x, premier versement à l'achat) : elle ne porte
**aucun intérêt** — les fonds n'ont pas été détenus un seul jour — et l'annuité
est calculée à terme à échoir (`annuité ordinaire / (1 + i)`).

Garde-fous du contrat, appliqués dans `LoanTerms` : durée bornée à
`maxDurationInMonths` (600), taux négatif ramené à 0, différé plafonné à
`durée − 1` pour qu'une échéance amortisse toujours le capital. Le formulaire
refuse en amont une durée hors bornes, un différé ≥ durée et des frais ≥ montant.

## Remboursement anticipé

Un `LoanEventModel` porte le type (total / partiel), la date, le montant, le
mode de ré-amortissement et le motif d'exonération. Il prend effet **à la
première échéance à partir de sa date** : les intérêts courent jusque-là, comme
en banque.

- **Total** : l'échéance de règlement paie la mensualité normale, puis solde le
  capital restant et l'indemnité. L'échéancier s'arrête là.
- **Partiel, réduction de durée** : mensualité inchangée, l'échéancier
  raccourcit et la dernière échéance est ajustée.
- **Partiel, réduction de mensualité** : durée inchangée, annuité recalculée sur
  le capital restant.

Le versement est plafonné au capital restant dû. Sous 10 % du montant emprunté
(art. L313-47), la banque peut refuser : `EarlyRepaymentQuote.isBelowBankMinimum`
le signale sans bloquer.

`LoanPayoffService` produit un `EarlyRepaymentQuote` (capital soldé, indemnité,
total à payer, économie, mois gagnés, nouvelle mensualité, nouvelle date de fin)
avant confirmation.

## Indemnité de remboursement anticipé

`EarlyRepaymentIndemnityService` applique le barème légal français. Le régime se
déduit du montant emprunté (seuil des 75 000 €).

| Régime | Barème |
|---|---|
| Immobilier (art. R313-25) | `min(6 mois d'intérêts sur le capital remboursé ; 3 % du CRD avant remboursement)` |
| Consommation (art. L312-34) | Rien sous 10 000 € remboursés sur 12 mois glissants, puis 1 % du capital remboursé (0,5 % si durée restante ≤ 12 mois), plafonné aux intérêts restants |

Le plafond « intérêts restants » du régime conso est mesuré sur la
**continuation contractuelle** — l'échéancier rebâti avec les seuls événements
antérieurs — et non sur une projection approchée : c'est la seule façon d'être
juste pendant un différé ou après une réduction de mensualité.

Exonération totale sur motif légal (art. L313-48, régime immobilier) : vente
suite à mutation professionnelle, décès de l'emprunteur ou du conjoint,
cessation forcée d'activité. Le contrat peut aussi supprimer l'indemnité
(`hasIndemnityClause` : PTZ, prêt familial, prêt employeur). À taux zéro le
barème donne naturellement 0 (4x sans frais, prêt familial).

## TAEG

`AnnualPercentageRateService` résout par bissection le taux mensuel qui annule
la VAN des flux (`montant − frais` reçu à t0, chaque échéance en sortie,
assurance incluse), puis annualise.

Il est calculé sur l'**échéancier contractuel**, jamais sur celui qui porte les
remboursements anticipés : le TAEG caractérise le contrat et ne doit pas bouger
après coup. Les périodes sont comptées en mois entiers — exact pour un
échéancier mensuel régulier, approché si le premier décalage est irrégulier.

## Couverture

Le moteur couvre nativement le crédit immobilier (avec différé et assurance), le
crédit à la consommation, le prêt in fine, le prêt familial à 0 % et le paiement
en 4x (`amortizable`, taux 0, durée 4, `immediateFirstPayment`, frais éventuels).

Hors périmètre : déblocages progressifs VEFA (intérêts intercalaires sur fonds
débloqués), crédit renouvelable (pas d'échéancier fixe) et taux
variable / révisable / capé (`interestRate` est fixe sur toute la durée).

## Lien avec Quick-Add

Le quick-add ne crée pas de prêt : trop rare et trop critique pour du LLM. Il
redirige vers le formulaire avec le montant pré-rempli.
