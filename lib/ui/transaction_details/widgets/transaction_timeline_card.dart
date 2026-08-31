import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/entities/transaction_change_entry.dart';
import 'package:mybudget/core/enums/transaction_change.dart';
import 'package:mybudget/core/theme/text_styles.dart';
import 'package:mybudget/ui/common/widgets/detail/detail_section.dart';

const String _title = 'Historique';
const String _missingValue = '—';
const double _railWidth = 18;
const double _dotSize = 7;

class TransactionTimelineCard extends StatelessWidget {
  final List<TransactionChangeEntry> entries;

  const TransactionTimelineCard({required this.entries, super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('d MMM yyyy', 'fr_FR');

    return DetailSection(
      title: _title,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Column(
        children: [
          for (var index = 0; index < entries.length; index++)
            _TimelineRow(
              entry: entries[index],
              date: dateFormatter.format(entries[index].at),
              isLast: index == entries.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final TransactionChangeEntry entry;
  final String date;
  final bool isLast;

  const _TimelineRow({
    required this.entry,
    required this.date,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = _tone(scheme);
    final detail = _detail();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _railWidth,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  width: _dotSize,
                  height: _dotSize,
                  decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: scheme.onSurface.withValues(alpha: 0.10),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 8 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.change.label,
                          style: TextStyle(
                            fontSize: 14,
                            height: 18 / 14,
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        date,
                        style: AppTextStyles.mono(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: TextStyle(
                        fontSize: 13,
                        height: 17 / 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _tone(ColorScheme scheme) {
    return switch (entry.change) {
      TransactionChange.created => scheme.primary,
      TransactionChange.closed => scheme.onSurfaceVariant,
      _ => scheme.secondary,
    };
  }

  String? _detail() {
    if (entry.from == null && entry.to == null) return null;
    return '${entry.from ?? _missingValue} → ${entry.to ?? _missingValue}';
  }
}
