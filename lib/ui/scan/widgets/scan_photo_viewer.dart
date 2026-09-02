import 'package:flutter/foundation.dart';

import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

class ScanPhotoViewer extends StatelessWidget {
  static const String title = 'Photo du ticket';

  static const double minScale = 1;
  static const double maxScale = 6;

  final Uint8List imageBytes;

  const ScanPhotoViewer({required this.imageBytes, super.key});

  static Future<void> show(BuildContext context, Uint8List imageBytes) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ScanPhotoViewer(imageBytes: imageBytes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: minScale,
              maxScale: maxScale,
              child: Image.memory(imageBytes, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(FrostedSpacing.sp2),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Symbols.close_rounded),
                      color: Colors.white,
                      tooltip: 'Fermer',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
