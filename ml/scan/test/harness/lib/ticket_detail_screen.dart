import 'dart:io';

import 'package:flutter/material.dart';

import 'local_flow.dart';
import 'result_view.dart';

/// Détail d'un ticket traité : image zoomable, verdict du flow, articles,
/// et le texte OCR brut de chaque passe pour comprendre une erreur.
class TicketDetailScreen extends StatelessWidget {
  const TicketDetailScreen({
    super.key,
    required this.name,
    required this.imageFile,
    required this.result,
  });

  final String name;
  final File imageFile;
  final LocalScanResult result;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(name, overflow: TextOverflow.ellipsis),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Résultat'),
              Tab(text: 'Image'),
              Tab(text: 'OCR'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ScanResultView(result: result),
            InteractiveViewer(
              maxScale: 8,
              child: Center(
                child: imageFile.existsSync()
                    ? Image.file(imageFile)
                    : const Text('Image introuvable'),
              ),
            ),
            _OcrText(result: result),
          ],
        ),
      ),
    );
  }
}

class _OcrText extends StatelessWidget {
  const _OcrText({required this.result});

  final LocalScanResult result;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(fontFamily: 'monospace');
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          'Passe 1 — ${result.pass1.latencyMs} ms',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        for (final line in result.pass1.lines) Text(line.text, style: style),
        if (result.retry case final retry?) ...[
          const Divider(),
          Text(
            'Retry — ${retry.latencyMs} ms',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          for (final line in retry.lines) Text(line.text, style: style),
        ],
      ],
    );
  }
}
