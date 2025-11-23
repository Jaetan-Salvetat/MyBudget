enum Frequency {
  monthly,
  annual;

  String get label {
    switch (this) {
      case Frequency.monthly:
        return 'Mensuel';
      case Frequency.annual:
        return 'Annuel';
    }
  }

  static Frequency fromString(String value) {
    switch (value) {
      case 'Mensuel':
        return Frequency.monthly;
      case 'Annuel':
        return Frequency.annual;
      default:
        return Frequency.monthly; // Default fallback
    }
  }
}
