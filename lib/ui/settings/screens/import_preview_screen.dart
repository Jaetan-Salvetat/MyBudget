import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart' hide FrostedContainer;
import 'package:intl/intl.dart';
import 'package:mybudget/core/services/data/import_validation_result.dart';
import 'package:mybudget/ui/common/widgets/frosted_container.dart';
import 'package:mybudget/ui/settings/widgets/data_management_dialogs.dart';

class ImportPreviewScreen extends ConsumerWidget {
  final ImportValidationResult validationResult;
  final String jsonContent;

  const ImportPreviewScreen({
    super.key,
    required this.validationResult,
    required this.jsonContent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final analysis = _ImportAnalysis(validationResult);

    return FrostedScaffold(
      appBar: FrostedAppBar(
        title: 'Aperçu de l\'import',
      ),
      bottomNavigationBar: FrostedContainer(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: FrostedFilledButton(
              onPressed: () {
                DataManagementDialogs.showImportConfirmationDialog(
                  context,
                  ref,
                  jsonContent,
                );
              },
              child: Text(
                'Importer ${validationResult.totalItems} éléments',
              ),
            ),
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.only(top: 120, left: 16, right: 16, bottom: 145),
        children: [
          if (validationResult.errors.isNotEmpty)
            _ErrorBanner(
              parsingErrors: validationResult.errors.length,
              orphanedExpenses: analysis.orphanedExpenses,
              orphanedRevenues: analysis.orphanedRevenues,
              orphanedLoans: analysis.orphanedLoans,
            ),
          _SummaryCard(
            totalItems: validationResult.totalItems,
            hasErrors: validationResult.errors.isNotEmpty ||
                analysis.hasOrphanedItems,
          ),
          const SizedBox(height: 16),
          if (validationResult.accounts.isNotEmpty)
            _EntitySection(
              title: 'Comptes',
              icon: Icons.account_balance_wallet_outlined,
              count: validationResult.accounts.length,
              children: validationResult.accounts
                  .map((a) => _ItemTile(
                        title: a.model.name,
                        subtitle: a.model.bank,
                      ))
                  .toList(),
            ),
          if (validationResult.beneficiaries.isNotEmpty)
            _EntitySection(
              title: 'Bénéficiaires',
              icon: Icons.people_outline,
              count: validationResult.beneficiaries.length,
              children: validationResult.beneficiaries
                  .map((b) => _ItemTile(title: b.model.name))
                  .toList(),
            ),
          if (validationResult.categories.isNotEmpty)
            _EntitySection(
              title: 'Catégories',
              icon: Icons.category_outlined,
              count: validationResult.categories.length,
              children: validationResult.categories
                  .map((c) => _ItemTile(
                        title: c.model.name,
                        leading: Icon(
                          c.model.getIconData(),
                          size: 18,
                          color: Color(c.model.color),
                        ),
                      ))
                  .toList(),
            ),
          if (validationResult.expenses.isNotEmpty)
            _EntitySection(
              title: 'Dépenses',
              icon: Icons.arrow_downward,
              count: validationResult.expenses.length,
              warningCount: analysis.orphanedExpenses,
              children: validationResult.expenses
                  .map((e) {
                    final warning = analysis.getExpenseWarning(e);
                    return _ItemTile(
                      title: e.model.name,
                      subtitle: e.model.frequency,
                      warning: warning,
                      trailing: Text(
                        formatter.format(e.model.amount),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: warning != null
                              ? theme.colorScheme.error
                              : theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  })
                  .toList(),
            ),
          if (validationResult.revenues.isNotEmpty)
            _EntitySection(
              title: 'Revenus',
              icon: Icons.arrow_upward,
              count: validationResult.revenues.length,
              warningCount: analysis.orphanedRevenues,
              children: validationResult.revenues
                  .map((r) {
                    final warning = analysis.getRevenueWarning(r);
                    return _ItemTile(
                      title: r.model.name,
                      warning: warning,
                      trailing: Text(
                        formatter.format(r.model.amount),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  })
                  .toList(),
            ),
          if (validationResult.loans.isNotEmpty)
            _EntitySection(
              title: 'Emprunts',
              icon: Icons.account_balance,
              count: validationResult.loans.length,
              warningCount: analysis.orphanedLoans,
              children: validationResult.loans
                  .map((l) {
                    final warning = analysis.getLoanWarning(l);
                    return _ItemTile(
                      title: l.model.name,
                      subtitle:
                          '${l.model.duration} mois · ${l.model.interestRate}%',
                      warning: warning,
                      trailing: Text(
                        formatter.format(l.model.amount),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  })
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _ImportAnalysis {
  final Set<int> _accountIds;
  final Set<int> _categoryIds;
  final Set<int> _beneficiaryIds;
  final ImportValidationResult _result;

  _ImportAnalysis(this._result)
      : _accountIds = _result.accounts.map((a) => a.oldId).toSet(),
        _categoryIds = _result.categories.map((c) => c.oldId).toSet(),
        _beneficiaryIds = _result.beneficiaries.map((b) => b.oldId).toSet();

  bool _isMissingAccount(int? oldAccountId) =>
      oldAccountId != null && !_accountIds.contains(oldAccountId);

  bool _isMissingCategory(int? oldCategoryId) =>
      oldCategoryId != null && !_categoryIds.contains(oldCategoryId);

  bool _isMissingBeneficiary(int? oldBeneficiaryId) =>
      oldBeneficiaryId != null && !_beneficiaryIds.contains(oldBeneficiaryId);

  String? getExpenseWarning(ParsedExpense e) {
    final issues = <String>[];
    if (_isMissingAccount(e.oldAccountId)) issues.add('compte');
    if (_isMissingCategory(e.oldCategoryId)) issues.add('catégorie');
    if (_isMissingBeneficiary(e.oldBeneficiaryId)) issues.add('bénéficiaire');
    if (issues.isEmpty) return null;
    return 'Sera ignorée : ${issues.join(', ')} introuvable';
  }

  String? getRevenueWarning(ParsedRevenue r) {
    final issues = <String>[];
    if (_isMissingAccount(r.oldAccountId)) issues.add('compte');
    if (_isMissingBeneficiary(r.oldBeneficiaryId)) issues.add('bénéficiaire');
    if (issues.isEmpty) return null;
    return 'Sera ignoré : ${issues.join(', ')} introuvable';
  }

  String? getLoanWarning(ParsedLoan l) {
    if (!_isMissingAccount(l.oldAccountId)) return null;
    return 'Sera ignoré : compte introuvable';
  }

  int get orphanedExpenses => _result.expenses
      .where((e) => getExpenseWarning(e) != null)
      .length;

  int get orphanedRevenues => _result.revenues
      .where((r) => getRevenueWarning(r) != null)
      .length;

  int get orphanedLoans => _result.loans
      .where((l) => getLoanWarning(l) != null)
      .length;

  bool get hasOrphanedItems =>
      orphanedExpenses > 0 || orphanedRevenues > 0 || orphanedLoans > 0;
}

class _SummaryCard extends StatelessWidget {
  final int totalItems;
  final bool hasErrors;

  const _SummaryCard({required this.totalItems, required this.hasErrors});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FrostedCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            hasErrors ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
            color: hasErrors
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$totalItems éléments à importer',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final int parsingErrors;
  final int orphanedExpenses;
  final int orphanedRevenues;
  final int orphanedLoans;

  const _ErrorBanner({
    required this.parsingErrors,
    required this.orphanedExpenses,
    required this.orphanedRevenues,
    required this.orphanedLoans,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messages = <String>[];

    if (parsingErrors > 0) {
      messages.add('$parsingErrors élément${parsingErrors > 1 ? 's' : ''} '
          'n\'${parsingErrors > 1 ? 'ont' : 'a'} pas pu être lu${parsingErrors > 1 ? 's' : ''}');
    }
    if (orphanedExpenses > 0) {
      messages.add('$orphanedExpenses dépense${orphanedExpenses > 1 ? 's' : ''} '
          'sans compte ou catégorie valide');
    }
    if (orphanedRevenues > 0) {
      messages.add('$orphanedRevenues revenu${orphanedRevenues > 1 ? 's' : ''} '
          'sans compte valide');
    }
    if (orphanedLoans > 0) {
      messages.add('$orphanedLoans emprunt${orphanedLoans > 1 ? 's' : ''} '
          'sans compte valide');
    }

    if (messages.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FrostedCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: theme.colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Avertissements',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...messages.map((m) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: theme.colorScheme.error)),
                      Expanded(
                        child: Text(
                          m,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _EntitySection extends StatefulWidget {
  final String title;
  final IconData icon;
  final int count;
  final int warningCount;
  final List<Widget> children;

  const _EntitySection({
    required this.title,
    required this.icon,
    required this.count,
    required this.children,
    this.warningCount = 0,
  });

  @override
  State<_EntitySection> createState() => _EntitySectionState();
}

class _EntitySectionState extends State<_EntitySection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FrostedCard(
        padding: const EdgeInsets.all(12),
        onClick: () => setState(() => _expanded = !_expanded),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.count}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (widget.warningCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.warningCount} ignoré${widget.warningCount > 1 ? 's' : ''}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(children: widget.children),
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? warning;
  final Widget? leading;
  final Widget? trailing;

  const _ItemTile({
    required this.title,
    this.subtitle,
    this.warning,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasWarning = warning != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (hasWarning) ...[
            Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 6),
          ] else if (leading != null) ...[
            leading!,
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: hasWarning
                        ? theme.colorScheme.onSurfaceVariant
                        : null,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (hasWarning)
                  Text(
                    warning!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
