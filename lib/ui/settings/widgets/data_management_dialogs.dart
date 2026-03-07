import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/utils/app_utils.dart';
import 'package:provider/provider.dart';
import 'package:mybudget/ui/settings/data_viewmodel.dart';

class DataManagementDialogs {
  static void showImportConfirmationDialog(
    BuildContext context,
    File file,
    DataViewModel dataVM,
  ) {
    FrostedDialog.show(
      context: context,
      title: const Text('Importer des données'),
      content: const Text(
        'Voulez-vous importer ces données ? Cette action remplacera toutes vos données actuelles.',
      ),
      actions: [
        FrostedTonalButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FrostedFilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            showImportProgressDialog(context, file, dataVM);
          },
          child: const Text('Importer'),
        ),
      ],
    );
  }

  static Future<void> showImportProgressDialog(
    BuildContext context,
    File file,
    DataViewModel dataVM,
  ) async {
    FrostedDialog.show(
      context: context,
      title: const Text('Importation en cours'),
      content: Consumer<DataViewModel>(
        builder: (context, vm, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Veuillez ne pas quitter l\'application pendant l\'importation.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              FrostedLinearProgressIndicator(value: vm.importProgress),
              const SizedBox(height: 10),
              Text(
                vm.importStatus,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );

    await dataVM.importUserData(context, file);

    if (context.mounted) {
      Navigator.of(context).pop();
    }

    if (context.mounted) {
      if (dataVM.error.isNotEmpty) {
        FrostedDialog.show(
          context: context,
          title: const Text('Erreur d\'importation'),
          content: Text(dataVM.error),
          actions: [
            FrostedTonalButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      } else {
        FrostedDialog.show(
          context: context,
          title: const Text('Importation réussie'),
          content: const Text(
            'Les données ont été importées avec succès.\n\n'
            'L\'application va redémarrer pour prendre en compte les changements.',
          ),
          actions: [
            FrostedFilledButton(
              onPressed: () => AppUtils.restartApp(context),
              child: const Text('Redémarrer'),
            ),
          ],
        );
      }
    }
  }

  static Future<void> showDeleteDataConfirmationDialog(
    BuildContext context,
    DataViewModel dataVM,
  ) async {
    FrostedDialog.show(
      context: context,
      title: const Text('Supprimer toutes les données'),
      content: const Text(
        'Êtes-vous sûr de vouloir supprimer toutes vos données ? Cette action est irréversible.',
      ),
      actions: [
        FrostedTonalButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FrostedFilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            showDeleteProgressDialog(context, dataVM);
          },
          child: const Text('Supprimer'),
        ),
      ],
    );
  }

  static Future<void> showDeleteProgressDialog(
    BuildContext context,
    DataViewModel dataVM,
  ) async {
    FrostedDialog.show(
      context: context,
      title: const Text('Suppression en cours'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Veuillez patienter pendant la suppression des données...',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          FrostedCircularProgressIndicator(),
        ],
      ),
    );

    await dataVM.deleteAllUserData(context);

    if (context.mounted) {
      Navigator.of(context).pop();
    }

    if (context.mounted) {
      if (dataVM.error.isNotEmpty) {
        FrostedDialog.show(
          context: context,
          title: const Text('Erreur de suppression'),
          content: Text(dataVM.error),
          actions: [
            FrostedTonalButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      } else {
        FrostedDialog.show(
          context: context,
          title: const Text('Suppression réussie'),
          content: const Text(
            'Toutes les données ont été supprimées avec succès.\n\n'
            'L\'application va redémarrer pour prendre en compte les changements.',
          ),
          actions: [
            FrostedFilledButton(
              onPressed: () => AppUtils.restartApp(context),
              child: const Text('Redémarrer'),
            ),
          ],
        );
      }
    }
  }
}
