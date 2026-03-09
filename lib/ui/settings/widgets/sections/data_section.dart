import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mybudget/ui/settings/data_provider.dart';
import 'package:mybudget/ui/settings/widgets/settings_section.dart';
import 'package:mybudget/ui/settings/widgets/settings_tile.dart';
import 'package:mybudget/ui/settings/widgets/data_management_dialogs.dart';

class DataSection extends ConsumerWidget {
  const DataSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsSection(
      title: 'Données',
      children: [
        SettingsTile(
          title: 'Exporter mes données',
          subtitle: 'Sauvegardez vos données financières',
          leading: const Icon(Icons.upload_file),
          onTap: () => ref.read(dataProvider.notifier).exportUserData(context),
        ),
        SettingsTile(
          title: 'Importer mes données',
          subtitle: 'Restaurez vos données depuis une sauvegarde',
          leading: const Icon(Icons.download),
          onTap: () => _importUserData(context, ref),
        ),
        SettingsTile(
          title: 'Supprimer toutes mes données',
          subtitle: 'Cette action est irréversible',
          leading: const Icon(Icons.delete_forever),
          onTap: () => DataManagementDialogs.showDeleteDataConfirmationDialog(context, ref),
        ),
      ],
    );
  }

  Future<void> _importUserData(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result == null || result.files.isEmpty) {
        return;
      }

      final path = result.files.single.path;
      if (path == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chemin du fichier invalide')),
          );
        }
        return;
      }

      final file = File(path);
      if (!await file.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fichier introuvable')),
          );
        }
        return;
      }

      if (context.mounted) {
        DataManagementDialogs.showImportConfirmationDialog(context, ref, file);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection du fichier: $e')),
        );
      }
    }
  }
}
