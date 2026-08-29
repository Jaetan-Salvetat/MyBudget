/// The three parts of a day the journal groups its lines under.
enum DayMoment {
  morning('Ce matin'),
  afternoon('Cet après-midi'),
  evening('Ce soir');

  const DayMoment(this.label);

  final String label;

  static const int _afternoonStartHour = 12;
  static const int _eveningStartHour = 18;

  static DayMoment ofHour(int hour) {
    if (hour < _afternoonStartHour) return DayMoment.morning;
    if (hour < _eveningStartHour) return DayMoment.afternoon;
    return DayMoment.evening;
  }
}
