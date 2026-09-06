import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';

Future<void> showQuickAddNoAccountDialog(BuildContext context) {
  return showFrostedDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => FrostedDialog(
      title: 'Aucun compte disponible',
      body: const Text(
        'Vous devez d\'abord créer un compte avant d\'ajouter une transaction.',
      ),
      actions: [
        FrostedButton.text(
          label: 'OK',
          onPressed: () => Navigator.pop(dialogContext),
        ),
      ],
    ),
  );
}
