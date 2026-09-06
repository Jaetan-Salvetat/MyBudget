const int majorFactor = 1000000;
const int minorFactor = 10000;
const int maxPatch = minorFactor - 1;
const int maxMinor = majorFactor ~/ minorFactor - 1;
const int maxVersionCode = 2100000000;
const int maxMajor = maxVersionCode ~/ majorFactor;

class StoreVersionException implements Exception {
  const StoreVersionException(this.message);

  final String message;

  @override
  String toString() => 'StoreVersionException: $message';
}

class StoreVersion {
  const StoreVersion(this.major, this.minor, this.patch);

  factory StoreVersion.parse(String version) {
    final List<String> fields = version.split('+').first.split('.');

    if (fields.length != 3) {
      throw StoreVersionException(
        'Version « $version » : trois champs attendus sous la forme x.y.z',
      );
    }

    final List<int?> parsed = fields.map(int.tryParse).toList();

    if (parsed.contains(null)) {
      throw StoreVersionException('Version « $version » : champs non numeriques');
    }

    return StoreVersion(parsed[0]!, parsed[1]!, parsed[2]!);
  }

  factory StoreVersion.fromCode(int code) => StoreVersion(
    code ~/ majorFactor,
    code % majorFactor ~/ minorFactor,
    code % minorFactor,
  );

  final int major;
  final int minor;
  final int patch;

  int get code => major * majorFactor + minor * minorFactor + patch;

  String get name => '$major.$minor.$patch';

  @override
  bool operator ==(Object other) =>
      other is StoreVersion &&
      other.major == major &&
      other.minor == minor &&
      other.patch == patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => name;
}

StoreVersion nextStoreVersion({
  required int major,
  required int minor,
  required int? highestPublishedCode,
}) {
  if (major > maxMajor) {
    throw StoreVersionException(
      'Majeure $major : le plafond Play de $maxVersionCode limite a $maxMajor',
    );
  }

  if (minor > maxMinor) {
    throw StoreVersionException(
      'Mineure $minor : la tranche du code de version s arrete a $maxMinor',
    );
  }

  if (highestPublishedCode == null) {
    return StoreVersion(major, minor, 0);
  }

  final StoreVersion published = StoreVersion.fromCode(highestPublishedCode);

  if (published.major == major && published.minor == minor) {
    if (published.patch >= maxPatch) {
      throw StoreVersionException(
        'Patch epuise pour $major.$minor : la tranche s arrete a $maxPatch',
      );
    }

    return StoreVersion(major, minor, published.patch + 1);
  }

  final StoreVersion candidate = StoreVersion(major, minor, 0);

  if (candidate.code <= highestPublishedCode) {
    throw StoreVersionException(
      'pubspec.yaml annonce $major.$minor, anterieure a la version publiee '
      '${published.major}.${published.minor}',
    );
  }

  return candidate;
}
