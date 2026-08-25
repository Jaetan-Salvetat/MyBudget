import 'package:flutter/material.dart';
import 'package:receipt_pipeline/receipt_pipeline.dart';

import 'result_view.dart';
import 'session_stats.dart';

/// Stats globales de la session, en direct pendant un run.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats de session'),
        actions: [
          IconButton(
            tooltip: 'Remettre à zéro',
            onPressed: sessionStats.reset,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: sessionStats,
        builder: (context, _) => StatsBody(snapshot: sessionStats.snapshot),
      ),
    );
  }
}

class StatsBody extends StatelessWidget {
  const StatsBody({required this.snapshot, super.key});

  final SessionSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final stats = snapshot;
    final total = stats.total;
    if (stats.isEmpty) {
      return const Center(child: Text('Aucun ticket traité pour l\'instant.'));
    }
    final percent = (stats.verifiedRate * 100).toStringAsFixed(1);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Vérifiés : ${stats.verified}/$total ($percent %)',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        for (final stage in FlowStage.values)
          _StageRow(stage: stage, count: stats.byStage[stage]!, total: total),
        const Divider(),
        ListTile(
          dense: true,
          title: const Text('Retry tentés'),
          trailing: Text('${stats.retries}'),
        ),
        ListTile(
          dense: true,
          title: const Text('Échecs techniques'),
          trailing: Text('${stats.failures}'),
        ),
        ListTile(
          dense: true,
          title: const Text('Latence médiane'),
          trailing: Text(_ms(stats.medianLatencyMs)),
        ),
        ListTile(
          dense: true,
          title: const Text('Latence p95'),
          trailing: Text(_ms(stats.p95LatencyMs)),
        ),
      ],
    );
  }

  String _ms(int? value) => value == null ? '—' : '$value ms';
}

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.stage,
    required this.count,
    required this.total,
  });

  final FlowStage stage;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.circle, color: stageColor(stage), size: 12),
          const SizedBox(width: 8),
          SizedBox(width: 96, child: Text(stageName(stage))),
          Expanded(
            child: LinearProgressIndicator(
              value: fraction,
              color: stageColor(stage),
              backgroundColor: Colors.grey.shade200,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 88,
            child: Text(
              '$count (${(fraction * 100).toStringAsFixed(0)} %)',
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
