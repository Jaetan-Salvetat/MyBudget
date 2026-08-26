/// Structuration décidée par le tagger de rôles.
///
/// Les règles déduisent de la géométrie et de lexiques quelles lignes sont des
/// articles ; le tagger apprend la question sur toutes les lignes du corpus,
/// et il y répond mieux. Il ne servait pourtant qu'à désigner l'enseigne et la
/// date : la décision « article ou pas » ne lui était jamais demandée.
///
/// Elle l'est ici. Les montants restent recopiés de l'OCR, jamais recalculés ;
/// les libellés suivent la même colonne que les règles ; et le checksum reste
/// juge. Comme les autres seconds avis, cet étage ne peut que sauver un ticket
/// flagué, jamais en corrompre un vérifié.
///
/// Miroir de `ml/scan/research/reference/structure_roles.py`.
library;

import 'lines.dart';
import 'structure.dart';

const String roleItem = 'item';
const String roleItemLabel = 'item_label';
const String roleDiscount = 'discount';
const String roleSubtotal = 'subtotal';
const String roleTotal = 'total';
const String rolePayment = 'payment';

/// Le reçu que décrivent ces rôles. [merged] et [roles] sont alignés.
ExtractedReceipt? extractRoles(List<PhysicalLine> merged, List<String> roles) {
  final column = labelColumnLeft(merged);
  final items = <ExtractedItem>[];
  double? total;
  double? subtotal;
  double? payment;
  String? pending;

  for (var index = 0; index < merged.length; index++) {
    final line = merged[index];
    final role = index < roles.length ? roles[index] : null;
    if (role == roleItemLabel) {
      pending = plausibleLabel(line.text);
      continue;
    }

    final priced = rightmostPrice(line);
    if (priced == null) continue;
    final price = roundCents(priced.price);

    // Un article ne peut pas être négatif : quel que soit le rôle prédit, un
    // montant négatif se déduit du précédent.
    if (role == roleItem && price >= 0) {
      // Un `item_label` désigné prime sur la zone de gauche : le tagger a dit
      // que le nom était ailleurs, et une pesée lisible (« 0,792 kg 2,65
      // EUR/kg ») ne doit pas le contredire au seul motif qu'elle porte des
      // lettres.
      final zone = labelZone(line, column).trim();
      items.add(
        ExtractedItem(
          name: cleanName(pending ?? plausibleLabel(zone) ?? zone),
          amount: price,
          discount: 0.0,
          lineIndex: index,
        ),
      );
      pending = null;
    } else if ((role == roleDiscount || (role == roleItem && price < 0)) &&
        items.isNotEmpty) {
      items.last.discount = roundCents(items.last.discount + price.abs());
    } else if (role == roleTotal && total == null) {
      total = price;
    } else if (role == roleSubtotal && subtotal == null) {
      subtotal = price;
    } else if (role == rolePayment && payment == null) {
      payment = price;
    }
  }

  if (items.isEmpty) return null;
  return ExtractedReceipt(
    store: merged.isEmpty ? null : merged.first.text,
    date: findDate(merged),
    total: total,
    subtotal: subtotal,
    payment: payment,
    items: items,
  );
}
