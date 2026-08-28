import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:mybudget/ui/scan/scan_screen.dart';

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

/// Le ticket est lu sur l'appareil : la photo ne part nulle part et garde sa
/// définition. Les petits caractères ne survivent pas à une réduction, et
/// c'est exactement ce que la reconnaissance doit lire.
Future<void> _pickAndScan(BuildContext context, ImageSource source) async {
  final navigator = Navigator.of(context);

  final XFile? picked = await ImagePicker().pickImage(source: source);
  if (picked == null) return;

  final imageBytes = await picked.readAsBytes();

  await navigator.push(
    MaterialPageRoute(builder: (_) => ScanScreen(imageBytes: imageBytes)),
  );
}
