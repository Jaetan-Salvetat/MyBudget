import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mybudget/ui/settings/data_viewmodel.dart';
import 'package:mybudget/ui/settings/widgets/settings_section.dart';
import 'package:mybudget/ui/settings/widgets/settings_tile.dart';
import 'package:mybudget/ui/settings/widgets/data_management_dialogs.dart';

class DataSection extends StatefulWidget {
  const DataSection({super.key});

  @override
  State<DataSection> createState() => _DataSectionState();
}

class _DataSectionState extends State<DataSection> {
  @override
  Widget build(BuildContext context) {
    final dataVM = Provider.of<DataViewModel>(context);

    return SettingsSection(
      title: 'Données',
      children: [
        SettingsTile(
          title: 'Exporter mes données',
          subtitle: 'Sauvegardez vos données financières',
          leading: const Icon(Icons.upload_file),
          onTap: () => _exportUserData(dataVM),
        ),
        SettingsTile(
          title: 'Importer mes données',
          subtitle: 'Restaurez vos données depuis une sauvegarde',
          leading: const Icon(Icons.download),
          onTap: () => _importUserData(dataVM),
        ),
        SettingsTile(
          title: 'Supprimer toutes mes données',
          subtitle: 'Cette action est irréversible',
          leading: const Icon(Icons.delete_forever),
          onTap:
              () => DataManagementDialogs.showDeleteDataConfirmationDialog(
                context,
                dataVM,
              ),
        ),
      ],
    );
  }

  Future<void> _exportUserData(DataViewModel dataVM) async {
    await dataVM.exportUserData(context);
  }

  Future<void> _importUserData(DataViewModel dataVM) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result == null || result.files.isEmpty) {
        return;
      }

      final path = result.files.single.path;
      if (path == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chemin du fichier invalide')),
          );
        }
        return;
      }

      final file = File(path);
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Fichier introuvable')));
        }
        return;
      }

      if (mounted) {
        DataManagementDialogs.showImportConfirmationDialog(
          context,
          file,
          dataVM,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection du fichier: $e')),
        );
      }
    }
  }
}
