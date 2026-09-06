library;

import 'lines.dart';
import 'structure.dart';

const String roleItem = 'item';
const String roleItemLabel = 'item_label';
const String roleDiscount = 'discount';
const String roleSubtotal = 'subtotal';
const String roleTotal = 'total';
const String rolePayment = 'payment';

const Set<String> amountBearingRoles = {
  roleItem,
  roleDiscount,
  roleSubtotal,
  roleTotal,
  rolePayment,
};

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

    final candidates = priceCandidates(
      line,
      lax: amountBearingRoles.contains(role),
    );
    if (candidates.isEmpty) continue;
    final price = roundCents(candidates.first.price);

    if (role == roleItem && price >= 0) {
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
