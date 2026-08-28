import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path_provider/path_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

import 'package:mybudget/ui/scan/scan_provider.dart';
import 'package:mybudget/ui/scan/screens/scan_trace_report.dart';

/// Ce que chaque étage du scan a produit, lecture par lecture.
///
/// Un article manquant ne se diagnostique pas depuis l'écran de validation :
/// il faut voir ce que l'OCR a lu, quel rôle le tagger a donné à chaque ligne,
/// et ce que le décodeur en a fait. Les trois sont ici, côte à côte, sur les
/// données du scan qui vient d'avoir lieu — pas sur une reconstitution.
class ScanInspectorScreen extends ConsumerWidget {
  const ScanInspectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trace = ref.watch(scanTraceProvider);
    return FrostedScaffold(
      appBar: FrostedTopBar(
        title: 'Inspecteur de scan',
        // Un écran ne se relit pas hors du téléphone : le rapport part au
        // presse-papier et au log, d'où il se récupère par `adb logcat`.
        actions: [
          IconButton(
            icon: const Icon(Symbols.content_copy_rounded),
            tooltip: 'Copier le rapport',
            onPressed: () => _export(context, trace),
          ),
        ],
      ),
      body: trace.isEmpty
          ? const Center(child: Text('Aucune lecture à inspecter'))
          : ListView(
              padding: EdgeInsets.only(
                top: FrostedTopBar.bodyTopPadding(context) + 8,
                left: 12,
                right: 12,
                bottom: 24,
              ),
              children: [for (final read in trace) _ReadCard(read: read)],
            ),
    );
  }

  /// Le presse-papier pour le relire tout de suite, un fichier pour le sortir
  /// du téléphone : le stockage externe de l'app se récupère par `adb pull`
  /// sans rien installer.
  Future<void> _export(BuildContext context, List<ReadTrace> trace) async {
    final report = scanTraceReport(trace);
    await Clipboard.setData(ClipboardData(text: report));
    final directory = await getExternalStorageDirectory();
    String? path;
    if (directory != null) {
      final file = File('${directory.path}/$reportFileName');
      await file.writeAsString(report, flush: true);
      await File(
        '${directory.path}/$wordsFileName',
      ).writeAsString(scanTraceWords(trace), flush: true);
      path = file.path;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(path == null ? 'Rapport copié' : 'Rapport → $path')),
    );
  }
}

/// Une lecture tentée : passe 1, retry ou fusion.
class _ReadCard extends StatelessWidget {
  const _ReadCard({required this.read});

  final ReadTrace read;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FrostedExpansionTile(
        title: sourceName(read.source),
        subtitle: read.proved
            ? 'somme prouvée — total ${_amount(read.decoding.receipt?.verifiedTotal)}'
            : 'somme non prouvée',
        initiallyExpanded: read.proved,
        child: Column(
          children: [
            _StepSection(
              title: '1 · OCR',
              subtitle: '${read.lines.length} lignes physiques',
              child: _LinesTable(read: read),
            ),
            _StepSection(
              title: '2 · Tagger de rôles',
              subtitle: _roleSummary(read),
              child: _RolesTable(read: read),
            ),
            _StepSection(
              title: '3 · Décodeur',
              subtitle: _decodingSummary(read),
              child: _DecodingTable(read: read),
            ),
          ],
        ),
      ),
    );
  }
}

String _roleSummary(ReadTrace read) {
  final counts = <String, int>{};
  for (final role in predictedRoles(read.roles)) {
    counts[role] = (counts[role] ?? 0) + 1;
  }
  final ordered = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return [for (final entry in ordered) '${entry.key} ${entry.value}'].join(' · ');
}

String _decodingSummary(ReadTrace read) {
  final decoding = read.decoding;
  final hypothesis = decoding.hypothesis;
  final reference = hypothesis == null
      ? 'aucune référence'
      : 'référence ${_amount(hypothesis.referenceCents / 100)}';
  return '${decoding.priced.length} lignes chiffrées · '
      '${decoding.laxRanks.length} ouvertes à la lecture lâche · $reference';
}

/// Un étage, replié par défaut : les trois tiennent alors sur un écran.
class _StepSection extends StatelessWidget {
  const _StepSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: FrostedExpansionTile(
        title: title,
        subtitle: subtitle,
        child: child,
      ),
    );
  }
}

/// Les lignes telles que l'OCR les a rendues, mots et boîtes compris : c'est
/// là qu'on voit deux lignes du ticket fusionnées en une seule.
class _LinesTable extends StatelessWidget {
  const _LinesTable({required this.read});

  final ReadTrace read;

  @override
  Widget build(BuildContext context) {
    return _Scrollable(
      rows: [
        for (final (index, line) in read.lines.indexed)
          _Row(
            leading: '$index',
            title: line.text,
            trailing: '${line.words.length} mots',
            detail: [
              for (final word in line.words)
                '${word.text} '
                    '[${word.left.round()},${word.top.round()}→'
                    '${word.right.round()},${word.bottom.round()}]'
                    '${word.confidence == null ? '' : ' ${word.confidence!.toStringAsFixed(2)}'}',
            ].join('  '),
          ),
      ],
    );
  }
}

/// Le rôle retenu par ligne, et sa probabilité. Les rôles qui suivent disent
/// ce que le modèle hésitait à répondre.
class _RolesTable extends StatelessWidget {
  const _RolesTable({required this.read});

  final ReadTrace read;

  @override
  Widget build(BuildContext context) {
    final roles = predictedRoles(read.roles);
    return _Scrollable(
      rows: [
        for (final (index, row) in read.roles.indexed)
          _Row(
            leading: '$index',
            title: roles[index],
            trailing: row[argmax(row)].toStringAsFixed(3),
            detail: _distribution(row),
          ),
      ],
    );
  }

  String _distribution(List<double> row) {
    final ranked = [
      for (final (column, name) in roleNames.indexed) (name, row[column]),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return [
      for (final (name, probability) in ranked.take(4))
        '$name ${probability.toStringAsFixed(3)}',
    ].join('  ');
  }
}

/// Ce que le décodeur a fait de chaque ligne chiffrée : ses candidats de prix,
/// si la laxité l'a ouverte, et l'étiquette retenue.
class _DecodingTable extends StatelessWidget {
  const _DecodingTable({required this.read});

  final ReadTrace read;

  static const Map<int, String> _labels = {
    labelItem: 'article',
    labelDiscount: 'remise',
    labelTotal: 'total',
    labelPayment: 'paiement',
    labelIgnore: 'ignorée',
  };

  @override
  Widget build(BuildContext context) {
    final decoding = read.decoding;
    final hypothesis = decoding.hypothesis;
    if (decoding.priced.isEmpty) {
      return const _Row(
        leading: '',
        title: 'Aucune ligne chiffrée',
        trailing: '',
        detail: 'le décodeur n\'a rien eu à combiner',
      );
    }
    return _Scrollable(
      rows: [
        for (final (rank, priced) in decoding.priced.indexed)
          _Row(
            leading: '${priced.index}',
            title: priced.line.text,
            trailing: hypothesis == null
                ? '—'
                : _labels[hypothesis.labels[rank]] ?? '—',
            detail: _detailOf(decoding, hypothesis, rank, priced),
          ),
      ],
    );
  }

  String _detailOf(
    ReceiptDecoding decoding,
    Hypothesis? hypothesis,
    int rank,
    PricedLine priced,
  ) {
    final candidates = [for (final c in priced.candidates) _amount(c)].join(', ');
    final lax = decoding.laxRanks.contains(priced.index)
        ? ' · lecture lâche autorisée'
        : '';
    final chosen = hypothesis == null || hypothesis.cents.isEmpty
        ? ''
        : ' · retenu ${_amount(hypothesis.cents[rank] / 100)}';
    return 'candidats $candidates$lax$chosen';
  }
}

/// Une ligne du tableau : rang, texte, verdict, et le détail en dessous.
class _Row extends StatelessWidget {
  const _Row({
    required this.leading,
    required this.title,
    required this.trailing,
    required this.detail,
  });

  final String leading;
  final String title;
  final String trailing;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodySmall?.copyWith(
      fontFamily: 'monospace',
      fontSize: 11,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  leading,
                  style: mono?.copyWith(color: theme.colorScheme.outline),
                ),
              ),
              Expanded(child: Text(title, style: mono)),
              if (trailing.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    trailing,
                    style: mono?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 28, top: 2),
            child: Text(
              detail,
              style: mono?.copyWith(
                color: theme.colorScheme.outline,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Un ticket a plus de lignes qu'un écran n'en montre : le tableau défile dans
/// sa propre boîte, sans jamais pousser la page.
class _Scrollable extends StatelessWidget {
  const _Scrollable({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 360),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows,
        ),
      ),
    );
  }
}

String _amount(double? value) =>
    value == null ? '—' : '${value.toStringAsFixed(2)} €';
