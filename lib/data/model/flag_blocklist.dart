import 'package:mybudget/core/exceptions/flag_blocklist_exception.dart';

const String _blockedField = 'blocked';
const String _idField = 'id';
const String _buildsField = 'builds';

class FlagBlocklist {
  const FlagBlocklist(this._blockedBuilds);

  factory FlagBlocklist.fromJson(Map<String, Object?> json) {
    final Object? entries = json[_blockedField];
    if (entries is! List<Object?>) {
      throw const FlagBlocklistMalformedException(field: _blockedField);
    }

    final Map<String, Set<int>?> blocked = <String, Set<int>?>{};
    for (final Object? entry in entries) {
      if (entry is! Map<String, Object?>) {
        throw const FlagBlocklistMalformedException(field: _blockedField);
      }
      final Object? id = entry[_idField];
      if (id is! String || id.isEmpty) {
        throw const FlagBlocklistMalformedException(field: _idField);
      }
      blocked[id] = _parseBuilds(entry[_buildsField]);
    }

    return FlagBlocklist(blocked);
  }

  static Set<int>? _parseBuilds(Object? builds) {
    if (builds == null) return null;
    if (builds is! List<Object?>) {
      throw const FlagBlocklistMalformedException(field: _buildsField);
    }
    return builds.map((Object? build) {
      if (build is! int) {
        throw const FlagBlocklistMalformedException(field: _buildsField);
      }
      return build;
    }).toSet();
  }

  static const FlagBlocklist empty = FlagBlocklist(<String, Set<int>?>{});

  final Map<String, Set<int>?> _blockedBuilds;

  Iterable<String> get blockedFlagIds => _blockedBuilds.keys;

  bool blocks({required String flagId, int? buildNumber}) {
    if (!_blockedBuilds.containsKey(flagId)) return false;
    final Set<int>? builds = _blockedBuilds[flagId];
    if (builds == null) return true;
    return buildNumber != null && builds.contains(buildNumber);
  }
}
