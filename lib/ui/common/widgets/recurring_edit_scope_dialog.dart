import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/contracts/filterable_transaction.dart';
import 'package:mybudget/core/enums/effective_month.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/rules/recurrence_rules.dart';
import 'package:mybudget/core/rules/transaction_change_rules.dart';
import 'package:mybudget/ui/common/widgets/effective_month_field.dart';

class RecurringEditScopeDialog {
  const RecurringEditScopeDialog._();

  static const String _title = 'Appliquer la modification';

  static const String _switchLabel = 'Appliquer dès ce mois-ci';

  static const String _dueLabel = 'Prise en compte';

  static Future<void> submit({
    required BuildContext context,
    required FilterableTransaction before,
    required FilterableTransaction after,
    required DateTime now,
    required Future<void> Function(EffectiveMonth? effectiveMonth) onConfirmed,
  }) async {
    if (!_needsChoice(before, after)) return onConfirmed(null);

    final scope = await _ask(context, after, now);
    if (scope == null) return;

    return onConfirmed(scope);
  }

  static bool _needsChoice(
    FilterableTransaction before,
    FilterableTransaction after,
  ) {
    return before.frequencyEnum != Frequency.oneTime &&
        offersEffectiveMonthChoice(after.frequencyEnum) &&
        TransactionChangeRules.changesTerms(before, after);
  }

  static Future<EffectiveMonth?> _ask(
    BuildContext context,
    FilterableTransaction after,
    DateTime now,
  ) {
    var scope = defaultEffectiveMonth(
      frequency: after.frequencyEnum,
      anchor: after.startDate,
      asOf: now,
    );

    return showFrostedDialog<EffectiveMonth>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setState) => FrostedDialog(
          title: _title,
          body: EffectiveMonthField(
            value: scope,
            frequency: after.frequencyEnum,
            anchor: after.startDate,
            now: now,
            label: _switchLabel,
            dueLabel: _dueLabel,
            onChanged: (value) => setState(() => scope = value),
          ),
          actions: [
            FrostedButton.text(
              label: 'Annuler',
              onPressed: () => Navigator.pop(dialogContext),
            ),
            FrostedButton.text(
              label: 'Enregistrer',
              onPressed: () => Navigator.pop(dialogContext, scope),
            ),
          ],
        ),
      ),
    );
  }
}
