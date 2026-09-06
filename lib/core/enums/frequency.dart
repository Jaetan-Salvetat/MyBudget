enum Frequency {
  monthly,
  annual,
  oneTime;

  static const Map<String, Frequency> _legacyLabels = {
    'Mensuel': Frequency.monthly,
    'Annuel': Frequency.annual,
    'Ponctuel': Frequency.oneTime,
  };

  String get storageKey => name;

  String get label {
    switch (this) {
      case Frequency.monthly:
        return 'Mensuel';
      case Frequency.annual:
        return 'Annuel';
      case Frequency.oneTime:
        return 'Ponctuel';
    }
  }

  static Frequency fromStorage(String value) {
    for (final frequency in Frequency.values) {
      if (frequency.storageKey == value) return frequency;
    }
    return _legacyLabels[value] ?? Frequency.monthly;
  }
}
