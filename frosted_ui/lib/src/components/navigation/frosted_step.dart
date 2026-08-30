import 'package:flutter/foundation.dart';

@immutable
class FrostedStep {
  const FrostedStep({required this.title, this.subtitle});

  final String title;
  final String? subtitle;
}
