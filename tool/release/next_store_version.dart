import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

import 'store_version.dart';

const String _credentialsVariable = 'PLAY_SERVICE_ACCOUNT_JSON';
const String _packageVariable = 'PACKAGE_NAME';
const String _publisherScope =
    'https://www.googleapis.com/auth/androidpublisher';
const String _publisherBase =
    'https://androidpublisher.googleapis.com/androidpublisher/v3/applications';

String _requiredEnvironment(String name) {
  final String? value = Platform.environment[name];

  if (value == null || value.isEmpty) {
    throw StateError('Variable d environnement $name absente');
  }

  return value;
}

StoreVersion _declaredVersion() {
  final File pubspec = File('pubspec.yaml');
  final String? line = pubspec
      .readAsLinesSync()
      .where((String line) => line.startsWith('version:'))
      .firstOrNull;

  if (line == null) {
    throw StateError('Aucune ligne « version: » dans ${pubspec.path}');
  }

  return StoreVersion.parse(line.split(':').last.trim());
}

Map<String, dynamic> _decode(http.Response response, String action) {
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException(
      '$action a echoue (${response.statusCode}) : ${response.body}',
    );
  }

  if (response.body.isEmpty) {
    return const <String, dynamic>{};
  }

  return jsonDecode(response.body) as Map<String, dynamic>;
}

Future<int?> _highestPublishedCode(
  http.Client client,
  String packageName,
) async {
  final Uri edits = Uri.parse('$_publisherBase/$packageName/edits');
  final String editId =
      _decode(await client.post(edits), 'Ouverture de l edit')['id'] as String;

  try {
    final Map<String, dynamic> listing = _decode(
      await client.get(Uri.parse('$edits/$editId/bundles')),
      'Liste des bundles',
    );
    final List<dynamic> bundles =
        listing['bundles'] as List<dynamic>? ?? const <dynamic>[];

    if (bundles.isEmpty) {
      return null;
    }

    return bundles
        .map((dynamic bundle) => (bundle as Map<String, dynamic>)['versionCode'] as int)
        .reduce((int a, int b) => a > b ? a : b);
  } finally {
    await client.delete(Uri.parse('$edits/$editId'));
  }
}

Future<void> main() async {
  final String packageName = _requiredEnvironment(_packageVariable);
  final StoreVersion declared = _declaredVersion();
  final AutoRefreshingAuthClient client = await clientViaServiceAccount(
    ServiceAccountCredentials.fromJson(
      _requiredEnvironment(_credentialsVariable),
    ),
    const <String>[_publisherScope],
  );

  try {
    final StoreVersion next = nextStoreVersion(
      major: declared.major,
      minor: declared.minor,
      highestPublishedCode: await _highestPublishedCode(client, packageName),
    );

    stdout.writeln('name=${next.name}');
    stdout.writeln('code=${next.code}');
  } finally {
    client.close();
  }
}
