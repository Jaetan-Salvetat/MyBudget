import 'package:flutter/material.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

import 'local_flow.dart';

/// Vue du résultat d'un flow local (scan caméra ou image de galerie) :
/// bandeau d'étage, entête, articles, somme vs total imprimé.
class ScanResultView extends StatelessWidget {
  const ScanResultView({super.key, required this.result});

  final LocalScanResult result;

  @override
  Widget build(BuildContext context) {
    final receipt = result.retry?.receipt ?? result.pass1.receipt;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
      children: [
        StageBanner(stage: result.outcome.stage, retryUsed: result.retryUsed),
        const SizedBox(height: 12),
        Text(
          receipt.store ?? 'Enseigne illisible',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text('Date : ${receipt.date ?? '—'}'),
        Text('Latence : ${result.totalLatencyMs} ms'),
        const Divider(),
        for (final item in result.outcome.items)
          ListTile(
            dense: true,
            title: Text(item.name),
            trailing: Text(
              item.discount > 0
                  ? '${item.amount.toStringAsFixed(2)} '
                        '(-${item.discount.toStringAsFixed(2)})'
                  : item.amount.toStringAsFixed(2),
            ),
          ),
        const Divider(),
        ListTile(
          title: const Text('Somme articles'),
          trailing: Text(receipt.itemsSum.toStringAsFixed(2)),
        ),
        ListTile(
          title: const Text('Total imprimé'),
          trailing: Text(receipt.total?.toStringAsFixed(2) ?? '—'),
        ),
      ],
    );
  }
}

class StageBanner extends StatelessWidget {
  const StageBanner({super.key, required this.stage, required this.retryUsed});

  final FlowStage stage;
  final bool retryUsed;

  @override
  Widget build(BuildContext context) {
    final (MaterialColor color, String label) = switch (stage) {
      FlowStage.local => (Colors.green, 'Vérifié — règles'),
      FlowStage.localRetry => (Colors.green, 'Vérifié — règles après retry'),
      FlowStage.localMl => (Colors.teal, 'Vérifié — classifieur'),
      FlowStage.localDp => (Colors.teal, 'Vérifié — décodage sous contrainte'),
      FlowStage.localFused => (Colors.teal, 'Vérifié — fusion des passes'),
      FlowStage.confirm => (
        Colors.orange,
        retryUsed
            ? 'Non vérifié (retry tenté) — à relire'
            : 'Non vérifié — à relire',
      ),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color.shade800)),
    );
  }
}

Color stageColor(FlowStage stage) => switch (stage) {
  FlowStage.local || FlowStage.localRetry => Colors.green,
  FlowStage.localMl || FlowStage.localDp || FlowStage.localFused => Colors.teal,
  FlowStage.confirm => Colors.orange,
};
