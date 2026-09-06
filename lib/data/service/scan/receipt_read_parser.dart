import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:mybudget/core/constants/receipt_schema.dart';
import 'package:mybudget/data/service/scan/local_receipt_scan.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

final RegExp _isoDate = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$');

final RegExp _frenchDate = RegExp(
  r'^(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{2}|\d{4})$',
);

LocalReceiptScan? receiptScanOf(String raw) {
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException catch (error) {
    debugPrint('[scan] réponse de lecture illisible : $error');
    return null;
  }
  if (decoded is! Map) return null;

  final items = _itemsOf(decoded[ReceiptSchema.itemsKey]);
  if (items.isEmpty) return null;

  final total = _amountOf(decoded[ReceiptSchema.totalKey]);
  return LocalReceiptScan(
    store: _textOf(decoded[ReceiptSchema.storeKey]),
    date: _dateOf(decoded[ReceiptSchema.dateKey]),
    total: total,
    items: items,
    verified: proves(items, total),
  );
}

/// Lecture d'une section : l'enseigne seule.
String? sectionStoreOf(String raw) =>
    _textOf(_decode(raw)?[ReceiptSchema.storeKey]);

String? sectionDateOf(String raw) =>
    _dateOf(_decode(raw)?[ReceiptSchema.dateKey]);

/// Lecture d'une section : le total seul.
double? sectionTotalOf(String raw) =>
    _amountOf(_decode(raw)?[ReceiptSchema.totalKey]);

/// Lecture d'une section : les articles et le total que le modèle leur associe.
({double? total, List<ExtractedItem> items})? sectionArticlesOf(String raw) {
  final decoded = _decode(raw);
  if (decoded == null) return null;

  final items = _itemsOf(decoded[ReceiptSchema.itemsKey]);
  if (items.isEmpty) return null;

  return (total: _amountOf(decoded[ReceiptSchema.totalKey]), items: items);
}

/// La somme d'une liste d'articles, remises déduites.
double sumOf(List<ExtractedItem> items) => roundCents(
  items.fold(0.0, (sum, item) => sum + item.amount - item.discount),
);

bool proves(List<ExtractedItem> items, double? total) =>
    total != null &&
    (sumOf(items) - total).abs() < ReceiptSchema.checksumTolerance;

Map<Object?, Object?>? _decode(String raw) {
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException catch (error) {
    debugPrint('[scan] section illisible : $error');
    return null;
  }
  return decoded is Map ? decoded : null;
}

List<ExtractedItem> _itemsOf(Object? value) {
  if (value is! List) return const [];

  final items = <ExtractedItem>[];
  for (final entry in value) {
    if (entry is! Map) continue;

    final name = _textOf(entry[ReceiptSchema.itemNameKey]);
    final amount = _amountOf(entry[ReceiptSchema.itemAmountKey]);
    if (name == null || amount == null) continue;

    final discount = _amountOf(entry[ReceiptSchema.itemDiscountKey]) ?? 0.0;
    items.add(
      ExtractedItem(
        name: name,
        amount: amount,
        discount: discount > amount ? amount : discount,
      ),
    );
  }
  return items;
}

String? _textOf(Object? value) {
  if (value is! String) return null;

  final text = value.trim();
  return text.isEmpty ? null : text;
}

String? _dateOf(Object? value) {
  final text = _textOf(value)?.trim();
  if (text == null) return null;

  final iso = _isoDate.firstMatch(text);
  if (iso != null) {
    return _isoOf(int.parse(iso[1]!), int.parse(iso[2]!), int.parse(iso[3]!));
  }

  final french = _frenchDate.firstMatch(text);
  if (french == null) return null;

  return _isoOf(
    _yearOf(french[3]!),
    int.parse(french[2]!),
    int.parse(french[1]!),
  );
}

int _yearOf(String digits) {
  final year = int.parse(digits);
  return digits.length == 4 ? year : 2000 + year;
}

String? _isoOf(int year, int month, int day) {
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;

  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return null;

  return '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}

double? _amountOf(Object? value) {
  if (value is! num) return null;

  final amount = roundCents(value.toDouble());
  return amount > 0 ? amount : null;
}
