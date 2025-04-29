import 'dart:io' show File, Platform;
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dotenv/dotenv.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  final scriptDir = File(Platform.script.toFilePath()).parent.path;
  final rootDir = p.dirname(scriptDir);
  final envFile = File(p.join(rootDir, '.env'));

  if (!envFile.existsSync()) {
    print('❌ Error: .env file not found at ${envFile.path}');
    return;
  }

  final env = DotEnv(includePlatformEnvironment: true)..load([envFile.path]);

  final client = Client()
    ..setEndpoint(env['APPWRITE_URL']!)
    ..setProject(env['APPWRITE_PROJECT_ID']!)
    ..setKey(env['APPWRITE_API_KEY']!);

  final databases = Databases(client);
  final databaseId = env['APPWRITE_DATABASE_ID']!;

  try {
    await setAccountsPermissions(databases, databaseId);
    await setExpensesPermissions(databases, databaseId);
    await setRevenuesPermissions(databases, databaseId);
    print('✅ All permissions configured successfully!');
  } catch (e) {
    print('❌ Error configuring permissions: $e');
  }
}

Future<void> setAccountsPermissions(
    Databases databases, String databaseId) async {
  try {
    // Configuration pour que chaque utilisateur ne puisse accéder qu'à ses propres données
    await databases.updateCollection(
      databaseId: databaseId,
      collectionId: 'accounts',
      name: 'Accounts',
      // Permettre uniquement la création à tous les utilisateurs authentifiés
      // Les permissions de lecture/mise à jour/suppression seront définies au niveau du document
      permissions: [
        'create("role:authenticated")',
      ],
      documentSecurity: true, // Activer la sécurité au niveau du document
    );

    print('✅ Accounts permissions configured');
  } catch (e) {
    print('❌ Error configuring accounts permissions: $e');
    rethrow;
  }
}

Future<void> setExpensesPermissions(
    Databases databases, String databaseId) async {
  try {
    // Configuration pour que chaque utilisateur ne puisse accéder qu'à ses propres données
    await databases.updateCollection(
      databaseId: databaseId,
      collectionId: 'expenses',
      name: 'Expenses',
      // Permettre uniquement la création à tous les utilisateurs authentifiés
      // Les permissions de lecture/mise à jour/suppression seront définies au niveau du document
      permissions: [
        'create("role:authenticated")',
      ],
      documentSecurity: true, // Activer la sécurité au niveau du document
    );

    print('✅ Expenses permissions configured');
  } catch (e) {
    print('❌ Error configuring expenses permissions: $e');
    rethrow;
  }
}

Future<void> setRevenuesPermissions(
    Databases databases, String databaseId) async {
  try {
    // Configuration pour que chaque utilisateur ne puisse accéder qu'à ses propres données
    await databases.updateCollection(
      databaseId: databaseId,
      collectionId: 'revenues',
      name: 'Revenues',
      // Permettre uniquement la création à tous les utilisateurs authentifiés
      // Les permissions de lecture/mise à jour/suppression seront définies au niveau du document
      permissions: [
        'create("role:authenticated")',
      ],
      documentSecurity: true, // Activer la sécurité au niveau du document
    );

    print('✅ Revenues permissions configured');
  } catch (e) {
    print('❌ Error configuring revenues permissions: $e');
    rethrow;
  }
}
