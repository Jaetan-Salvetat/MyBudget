import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:mybudget/core/constants/receipt_schema.dart';
import 'package:mybudget/core/enums/gemini_nano_channel.dart';
import 'package:mybudget/core/enums/gemini_nano_failure.dart';
import 'package:mybudget/core/enums/gemini_nano_preference.dart';
import 'package:mybudget/core/services/ai/gemini_nano_service.dart';
import 'package:mybudget/core/services/scan/local_receipt_scan.dart';
import 'package:mybudget/core/services/scan/nano_receipt_prompt.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

final RegExp _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');

class NanoReceiptReader {
  const NanoReceiptReader({
    this._service = const GeminiNanoService(),
    this._channel = GeminiNanoChannel.fallback,
  });

  final GeminiNanoService _service;
  final GeminiNanoChannel _channel;

  Future<void> warmUp() =>
      _service.warmUp(_channel, GeminiNanoPreference.scan);

  Future<LocalReceiptScan?> read(List<PhysicalLine> lines) async {
    final prompt = nanoReceiptPrompt(lines);
    if (prompt == null) return null;

    final String raw;
    try {
      raw = await _service.generate(
        prompt: prompt,
        schema: ReceiptSchema.name,
        channel: _channel,
        preference: GeminiNanoPreference.scan,
      );
    } on GeminiNanoException catch (error) {
      debugPrint('[scan] Gemini Nano a renoncé : ${error.message}');
      return null;
    }

    return _scanOf(raw);
  }

  LocalReceiptScan? _scanOf(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      debugPrint('[scan] réponse Gemini Nano illisible : $error');
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
      verified: _proves(items, total),
    );
  }

  static List<ExtractedItem> _itemsOf(Object? value) {
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

  static bool _proves(List<ExtractedItem> items, double? total) {
    if (total == null) return false;

    final sum = roundCents(
      items.fold(0.0, (sum, item) => sum + item.amount - item.discount),
    );
    return (sum - total).abs() < ReceiptSchema.checksumTolerance;
  }

  static String? _textOf(Object? value) {
    if (value is! String) return null;

    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  static String? _dateOf(Object? value) {
    final text = _textOf(value);
    if (text == null || !_isoDate.hasMatch(text)) return null;

    return DateTime.tryParse(text) == null ? null : text;
  }

  static double? _amountOf(Object? value) {
    if (value is! num) return null;

    final amount = roundCents(value.toDouble());
    return amount > 0 ? amount : null;
  }
}
