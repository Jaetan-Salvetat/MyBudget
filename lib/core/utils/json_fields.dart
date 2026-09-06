extension JsonFields on Map<String, dynamic> {
  String readString(String key, String fallback) {
    final Object? value = this[key];
    return value == null ? fallback : value.toString();
  }

  String? readOptionalString(String key) {
    final Object? value = this[key];
    return value is String ? value : null;
  }

  double readDouble(String key, double fallback) {
    final Object? value = this[key];
    return switch (value) {
      final num number => number.toDouble(),
      final String text => double.tryParse(text) ?? fallback,
      _ => fallback,
    };
  }

  int readInt(String key, int fallback) => readOptionalInt(key) ?? fallback;

  int? readOptionalInt(String key) {
    final Object? value = this[key];
    return switch (value) {
      final num number => number.toInt(),
      final String text => int.tryParse(text) ?? double.tryParse(text)?.toInt(),
      _ => null,
    };
  }

  DateTime? readOptionalDate(String key) {
    final Object? value = this[key];
    return value == null ? null : DateTime.tryParse(value.toString());
  }

  DateTime? readFirstDate(List<String> keys) {
    for (final String key in keys) {
      final DateTime? parsed = readOptionalDate(key);
      if (parsed != null) return parsed;
    }
    return null;
  }
}
