import 'package:mybudget/core/entities/beneficiary.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/transaction_filter_data.dart';
import 'package:mybudget/ui/common/widgets/active_filter_pills.dart';

class ActiveFilterPillsBuilder {
  const ActiveFilterPillsBuilder._();

  static const String _unknownLabel = '—';

  static List<ActiveFilterPill> build({
    required TransactionFilterData filter,
    required List<CategoryDisplay> categories,
    required List<AccountModel> accounts,
    required List<Beneficiary> beneficiaries,
    required void Function(TransactionFilterData filter) onChanged,
  }) {
    final pills = <ActiveFilterPill>[];

    for (final type in filter.types) {
      pills.add(
        ActiveFilterPill(
          id: 'type-${type.name}',
          label: type.label,
          onRemove: () => onChanged(
            filter.copyWith(
              types: filter.types.where((t) => t != type).toList(),
            ),
          ),
        ),
      );
    }

    for (final groupKey in filter.groupKeys) {
      final category = categories
          .where((c) => c.slug == groupKey)
          .firstOrNull;
      pills.add(
        ActiveFilterPill(
          id: 'cat-$groupKey',
          label: category?.label ?? _unknownLabel,
          onRemove: () => onChanged(
            filter.copyWith(
              groupKeys: filter.groupKeys.where((k) => k != groupKey).toList(),
            ),
          ),
        ),
      );
    }

    for (final id in filter.accountIds) {
      final account = accounts.where((a) => a.id == id).firstOrNull;
      pills.add(
        ActiveFilterPill(
          id: 'acc-$id',
          label: account?.name ?? _unknownLabel,
          onRemove: () => onChanged(
            filter.copyWith(
              accountIds: filter.accountIds.where((a) => a != id).toList(),
            ),
          ),
        ),
      );
    }

    for (final id in filter.beneficiaryIds) {
      final beneficiary = beneficiaries.where((b) => b.id == id).firstOrNull;
      pills.add(
        ActiveFilterPill(
          id: 'ben-$id',
          label: beneficiary?.name ?? _unknownLabel,
          onRemove: () => onChanged(
            filter.copyWith(
              beneficiaryIds: filter.beneficiaryIds
                  .where((b) => b != id)
                  .toList(),
            ),
          ),
        ),
      );
    }

    if (filter.minAmount != null || filter.maxAmount != null) {
      pills.add(
        ActiveFilterPill(
          id: 'amount',
          label: _amountLabel(filter),
          onRemove: () => onChanged(filter.clearAmounts()),
        ),
      );
    }

    return pills;
  }

  static String _amountLabel(TransactionFilterData filter) {
    final min = filter.minAmount?.round();
    final max = filter.maxAmount?.round();
    if (min != null && max != null) return '$min – $max €';
    if (min != null) return '≥ $min €';
    return '≤ $max €';
  }
}
