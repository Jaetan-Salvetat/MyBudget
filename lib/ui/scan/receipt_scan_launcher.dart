import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:mybudget/core/services/ai/ai_chat_client.dart';
import 'package:mybudget/ui/scan/scan_screen.dart';

/// La photo part vers un modèle distant : elle est réduite avant de quitter
/// l'appareil, ce qui borne à la fois le coût et ce qui est envoyé.
const double _maxImageWidth = 1920;
const int _imageQuality = 85;

/// Propose l'appareil photo ou la galerie, puis ouvre l'écran de scan sur
/// l'image retenue. Ne fait rien si l'utilisateur renonce.
Future<void> showReceiptScanSourceSheet(BuildContext context) {
  return showFrostedBottomSheet<void>(
    context: context,
    builder: (sheetContext) => FrostedBottomSheet(
      title: 'Scanner un ticket',
      child: FrostedListSection(
        tiles: [
          FrostedListTile(
            title: 'Prendre une photo',
            leading: const Icon(Symbols.camera_alt_rounded),
            onTap: () {
              Navigator.pop(sheetContext);
              _pickAndScan(context, ImageSource.camera);
            },
          ),
          FrostedListTile(
            title: 'Choisir depuis la galerie',
            leading: const Icon(Symbols.photo_library_rounded),
            onTap: () {
              Navigator.pop(sheetContext);
              _pickAndScan(context, ImageSource.gallery);
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> _pickAndScan(BuildContext context, ImageSource source) async {
  final navigator = Navigator.of(context);

  final XFile? picked = await ImagePicker().pickImage(
    source: source,
    maxWidth: _maxImageWidth,
    imageQuality: _imageQuality,
  );
  if (picked == null) return;

  // Une qualité de compression donnée force le ré-encodage en JPEG, quel que
  // soit le format d'origine.
  final image = AiImageAttachment.jpeg(await picked.readAsBytes());

  await navigator.push(
    MaterialPageRoute(builder: (_) => ScanScreen(image: image)),
  );
}
