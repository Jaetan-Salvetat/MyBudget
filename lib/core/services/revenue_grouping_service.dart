import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/revenue_group_by.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/core/entities/beneficiary.dart';
import 'package:mybudget/models/revenue_model.dart';

/// What a revenue is grouped under, and how that bucket is rendered.
///
/// [rank] orders the buckets before their weight is looked at: a calendar axis
/// wants its own order, and a fallback bucket ("Non catégorisé") stays last
/// however much money it holds.
class RevenueGroupIdentity {
  static const int leadingRank = 0;
  static const int trailingRank = 1 << 20;

  final String key;
  final String label;

  /// Taxonomy icon key, when the axis carries one. Axes with no icon of their
  /// own leave it null and let the view pick one.
  final String? icon;
  final int? color;
  final int rank;

  const RevenueGroupIdentity({
    required this.key,
    required this.label,
    this.icon,
    this.color,
    this.rank = leadingRank,
  });
}

class RevenueGroup {
  final RevenueGroupIdentity identity;
  final List<RevenueModel> items;
  final double total;

  /// Weight of the group in the grouped set, in `[0, 1]`.
  final double share;

  const RevenueGroup({
    required this.identity,
    required this.items,
    required this.total,
    required this.share,
  });

  String get key => identity.key;

  String get label => identity.label;

  String? get icon => identity.icon;

  int? get color => identity.color;
}

/// Maps a revenue to its bucket along one axis.
abstract class RevenueGrouper {
  const RevenueGrouper();

  RevenueGroupIdentity identify(RevenueModel revenue);
}

class FlatRevenueGrouper extends RevenueGrouper {
  static const String key = '__all__';

  const FlatRevenueGrouper();

  @override
  RevenueGroupIdentity identify(RevenueModel revenue) =>
      const RevenueGroupIdentity(key: key, label: '');
}

class FrequencyRevenueGrouper extends RevenueGrouper {
  const FrequencyRevenueGrouper();

  @override
  RevenueGroupIdentity identify(RevenueModel revenue) {
    final frequency = revenue.frequencyEnum;
    return RevenueGroupIdentity(
      key: frequency.name,
      label: switch (frequency) {
        Frequency.monthly => 'Mensuels',
        Frequency.annual => 'Annuels',
        Frequency.oneTime => 'Ponctuels',
      },
      rank: frequency.index,
    );
  }
}

class CategoryRevenueGrouper extends RevenueGrouper {
  final CategoryDisplayResolver _resolver;

  const CategoryRevenueGrouper(this._resolver);

  @override
  RevenueGroupIdentity identify(RevenueModel revenue) {
    final slug = revenue.categorySlug;
    final group = slug == null ? null : _resolver.resolveGroupOfSlug(slug);
    if (group == null) {
      final fallback = _resolver.uncategorized(TransactionType.income);
      return RevenueGroupIdentity(
        key: fallback.groupKey,
        label: fallback.label,
        icon: fallback.icon,
        color: fallback.color,
        rank: RevenueGroupIdentity.trailingRank,
      );
    }
    return RevenueGroupIdentity(
      key: group.groupKey,
      label: group.label,
      icon: group.icon,
      color: group.color,
    );
  }
}

class BeneficiaryRevenueGrouper extends RevenueGrouper {
  static const String unassignedKey = '__no_beneficiary__';
  static const String unassignedLabel = 'Sans bénéficiaire';

  final Map<int, Beneficiary> _byId;

  BeneficiaryRevenueGrouper(List<Beneficiary> beneficiaries)
    : _byId = {for (final b in beneficiaries) b.id: b};

  @override
  RevenueGroupIdentity identify(RevenueModel revenue) {
    final beneficiary = _byId[revenue.beneficiaryId];
    if (beneficiary == null) {
      return const RevenueGroupIdentity(
        key: unassignedKey,
        label: unassignedLabel,
        rank: RevenueGroupIdentity.trailingRank,
      );
    }
    return RevenueGroupIdentity(
      key: '${beneficiary.id}',
      label: beneficiary.name,
      color: beneficiary.color == 0 ? null : beneficiary.color,
    );
  }
}

class AccountRevenueGrouper extends RevenueGrouper {
  static const String unknownKey = '__unknown_account__';
  static const String unknownLabel = 'Compte inconnu';

  final Map<int, AccountModel> _byId;

  AccountRevenueGrouper(List<AccountModel> accounts)
    : _byId = {for (final a in accounts) a.id: a};

  @override
  RevenueGroupIdentity identify(RevenueModel revenue) {
    final account = _byId[revenue.accountId];
    if (account == null) {
      return const RevenueGroupIdentity(
        key: unknownKey,
        label: unknownLabel,
        rank: RevenueGroupIdentity.trailingRank,
      );
    }
    return RevenueGroupIdentity(key: '${account.id}', label: account.name);
  }
}

class RevenueGroupingService {
  const RevenueGroupingService._();

  /// The grouper backing [axis], flat while the taxonomy is still loading:
  /// a category axis with no taxonomy would label every revenue "Non
  /// catégorisé", which reads as data loss rather than as a loading state.
  static RevenueGrouper grouperFor(
    RevenueGroupBy axis, {
    required CategoryDisplayResolver? categoryResolver,
    required List<Beneficiary> beneficiaries,
    required List<AccountModel> accounts,
  }) {
    switch (axis) {
      case RevenueGroupBy.frequency:
        return const FrequencyRevenueGrouper();
      case RevenueGroupBy.category:
        return categoryResolver == null
            ? const FlatRevenueGrouper()
            : CategoryRevenueGrouper(categoryResolver);
      case RevenueGroupBy.beneficiary:
        return BeneficiaryRevenueGrouper(beneficiaries);
      case RevenueGroupBy.account:
        return AccountRevenueGrouper(accounts);
      case RevenueGroupBy.none:
        return const FlatRevenueGrouper();
    }
  }

  static List<RevenueGroup> group(
    List<RevenueModel> revenues,
    RevenueGrouper grouper,
  ) {
    final identities = <String, RevenueGroupIdentity>{};
    final buckets = <String, List<RevenueModel>>{};

    for (final revenue in revenues) {
      final identity = grouper.identify(revenue);
      identities.putIfAbsent(identity.key, () => identity);
      buckets.putIfAbsent(identity.key, () => []).add(revenue);
    }

    final overall = revenues.fold<double>(0, (sum, r) => sum + r.amount);

    final groups = buckets.entries.map((entry) {
      final total = entry.value.fold<double>(0, (sum, r) => sum + r.amount);
      return RevenueGroup(
        identity: identities[entry.key]!,
        items: entry.value,
        total: total,
        share: overall == 0 ? 0 : total / overall,
      );
    }).toList();

    groups.sort((a, b) {
      final byRank = a.identity.rank.compareTo(b.identity.rank);
      if (byRank != 0) return byRank;
      final byTotal = b.total.compareTo(a.total);
      if (byTotal != 0) return byTotal;
      return a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });

    return groups;
  }
}
