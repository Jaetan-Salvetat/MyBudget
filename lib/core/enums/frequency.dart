enum Frequency {
  monthly,
  annual,
  oneTime;

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

  static Frequency fromString(String value) {
    switch (value) {
      case 'Mensuel':
        return Frequency.monthly;
      case 'Annuel':
        return Frequency.annual;
      case 'Ponctuel':
        return Frequency.oneTime;
      default:
        return Frequency.monthly;
    }
  }
}
