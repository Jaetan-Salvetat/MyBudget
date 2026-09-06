import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mybudget/core/exceptions/flag_blocklist_exception.dart';
import 'package:mybudget/core/models/flag_blocklist.dart';
import 'package:mybudget/core/services/preferences_service.dart';

const String flagBlocklistEndpoint = 'https://mybudget.jaetan.dev/flags.json';
const Duration _fetchTimeout = Duration(seconds: 5);
const int _okStatus = 200;

class FlagBlocklistService {
  const FlagBlocklistService({required this.httpClient});

  final http.Client httpClient;

  FlagBlocklist cached() {
    final String? payload = PreferencesService.getFlagBlocklist();
    if (payload == null) return FlagBlocklist.empty;
    return _parse(payload) ?? FlagBlocklist.empty;
  }

  Future<FlagBlocklist> refresh() async {
    try {
      final http.Response response = await httpClient
          .get(Uri.parse(flagBlocklistEndpoint))
          .timeout(_fetchTimeout);

      if (response.statusCode != _okStatus) {
        debugPrint(
          '[flags] disjoncteur indisponible : HTTP ${response.statusCode}',
        );
        return cached();
      }

      final FlagBlocklist? blocklist = _parse(response.body);
      if (blocklist == null) return cached();

      await PreferencesService.setFlagBlocklist(response.body);
      return blocklist;
    } on Exception catch (error) {
      debugPrint('[flags] disjoncteur injoignable : $error');
      return cached();
    }
  }

  FlagBlocklist? _parse(String payload) {
    try {
      final Object? decoded = jsonDecode(payload);
      if (decoded is! Map<String, Object?>) {
        throw const FlagBlocklistMalformedException(field: 'racine');
      }
      return FlagBlocklist.fromJson(decoded);
    } on FormatException catch (error) {
      debugPrint('[flags] liste de blocage illisible : $error');
      return null;
    } on FlagBlocklistException catch (error) {
      debugPrint('[flags] liste de blocage invalide : ${error.message}');
      return null;
    }
  }
}
