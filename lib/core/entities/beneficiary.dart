import 'dart:math';

import 'package:flutter/painting.dart';
import 'package:mybudget/models/beneficiary_model.dart';

class Beneficiary {
  final BeneficiaryModel _model;

  Beneficiary._(this._model);

  factory Beneficiary.fromModel(BeneficiaryModel model) =>
      Beneficiary._(model);

  int get id => _model.id;
  String get name => _model.name;
  int get color => _model.color;

  String get initials {
    if (name.trim().isEmpty) return '?';

    final parts =
        name.trim().split(RegExp(r'[\s\-]+')).where((p) => p.isNotEmpty).toList();

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    final single = parts.first;
    if (single.length >= 2) {
      return '${single[0].toUpperCase()}${single[1].toLowerCase()}';
    }
    return single[0].toUpperCase();
  }

  static int generateColor() {
    final random = Random();
    final hue = random.nextDouble() * 360;
    final hslColor = HSLColor.fromAHSL(1.0, hue, 0.5, 0.4);
    return hslColor.toColor().toARGB32();
  }
}
