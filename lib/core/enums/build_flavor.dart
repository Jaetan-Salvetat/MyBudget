import 'package:flutter/services.dart';

enum BuildFlavor {
  dev(id: 'dev'),
  beta(id: 'beta'),
  prod(id: 'prod'),
  store(id: 'store');

  const BuildFlavor({required this.id});

  final String id;

  static const BuildFlavor fallback = dev;

  static BuildFlavor get current => fromId(appFlavor);

  static BuildFlavor fromId(String? id) {
    for (final BuildFlavor flavor in values) {
      if (flavor.id == id) return flavor;
    }
    return fallback;
  }

  bool get supportsInAppUpdate => this != store;

  bool get exposesQuickAddEngineSettings => this != store;
}
