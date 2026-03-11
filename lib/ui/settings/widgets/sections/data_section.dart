import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/ui/settings/data_provider.dart';
import 'package:mybudget/ui/settings/widgets/settings_section.dart';
import 'package:mybudget/ui/settings/widgets/settings_tile.dart';
import 'package:mybudget/ui/settings/screens/import_preview_screen.dart';
import 'package:mybudget/ui/settings/widgets/data_management_dialogs.dart';
import 'package:share_plus/share_plus.dart';

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
          onTap: () => _exportUserData(context, ref),
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
          onTap: () => DataManagementDialogs.showDeleteDataConfirmationDialog(
              context, ref),
        ),
      ],
    );
  }

  Future<void> _exportUserData(BuildContext context, WidgetRef ref) async {
    try {
      final filePath =
          await ref.read(dataProvider.notifier).exportUserData();

      await SharePlus.instance.share(
        ShareParams(
          text: 'Sauvegarde de vos données MyBudget',
          subject: 'MyBudget - Données exportées',
          files: [XFile(filePath)],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        FrostedSnackbar.show(context, message: 'Erreur lors de l\'export: $e');
      }
    }
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
          FrostedSnackbar.show(context, message: 'Chemin du fichier invalide');
        }
        return;
      }

      final file = File(path);
      if (!await file.exists()) {
        if (context.mounted) {
          FrostedSnackbar.show(context, message: 'Fichier introuvable');
        }
        return;
      }

      final jsonContent = await file.readAsString();

      if (context.mounted) {
        try {
          final validationResult =
              ref.read(dataProvider.notifier).validateImportData(jsonContent);

          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ImportPreviewScreen(
                  validationResult: validationResult,
                  jsonContent: jsonContent,
                ),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            FrostedSnackbar.show(context,
                message: 'Erreur lors de la lecture du fichier: $e');
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        FrostedSnackbar.show(context,
            message: 'Erreur lors de la sélection du fichier: $e');
      }
    }
  }
}
