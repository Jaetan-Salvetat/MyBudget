import 'package:flutter/foundation.dart';

/// A single step in a [FrostedStepper].
@immutable
class FrostedStep {
  const FrostedStep({required this.title, this.subtitle});

  final String title;
  final String? subtitle;
}
