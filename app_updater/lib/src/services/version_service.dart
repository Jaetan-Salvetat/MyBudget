import '../config/update_config.dart';
import '../exceptions/update_exception.dart';

class VersionService {
  final VersionComparator? _customComparator;

  VersionService({VersionComparator? comparator})
      : _customComparator = comparator;

  bool isNewer(String currentVersion, String candidateVersion) {
    if (_customComparator != null) {
      return _customComparator(currentVersion, candidateVersion);
    }
    return _compareSemver(currentVersion, candidateVersion) < 0;
  }

  int _compareSemver(String a, String b) {
    final partsA = _parseSemver(a);
    final partsB = _parseSemver(b);

    for (var i = 0; i < 3; i++) {
      if (partsA[i] < partsB[i]) return -1;
      if (partsA[i] > partsB[i]) return 1;
    }
    return 0;
  }

  List<int> _parseSemver(String version) {
    var cleaned = version;
    if (cleaned.startsWith('v') || cleaned.startsWith('V')) {
      cleaned = cleaned.substring(1);
    }

    final dashIndex = cleaned.indexOf('-');
    if (dashIndex != -1) {
      cleaned = cleaned.substring(0, dashIndex);
    }

    final parts = cleaned.split('.');
    if (parts.length < 2 || parts.length > 3) {
      throw VersionParseException(version: version);
    }

    try {
      return [
        int.parse(parts[0]),
        int.parse(parts[1]),
        parts.length > 2 ? int.parse(parts[2]) : 0,
      ];
    } on FormatException {
      throw VersionParseException(version: version);
    }
  }
}
