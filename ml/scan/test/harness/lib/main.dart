import 'package:flutter/material.dart';

import 'gallery_screen.dart';
import 'scan_screen.dart';
import 'suite_screen.dart';

void main() {
  runApp(const OcrHarnessApp());
}

class OcrHarnessApp extends StatelessWidget {
  const OcrHarnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomeScreen());
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Banc de test scan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.playlist_play),
              title: const Text('Suite complète'),
              subtitle: const Text(
                'Flow local sur tout le corpus (input/ via adb, sinon '
                'assets) ; résultats JSON pour le scoring Python.',
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SuiteScreen()),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Tester depuis la galerie'),
              subtitle: const Text(
                'Un lot de photos de tickets, flow local sur chacune, '
                'verdict par image et dumps pour analyse.',
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GalleryScreen()),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Scanner un ticket'),
              subtitle: const Text(
                'Photo d\'un vrai ticket, flow local complet, résultat '
                'structuré à l\'écran.',
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ScanScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
