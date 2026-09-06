import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/enums/effective_month.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/formatting/money_formatter.dart';
import 'package:mybudget/core/rules/recurrence_rules.dart';
import 'package:mybudget/data/model/account_model.dart';
import 'package:mybudget/data/model/revenue_model.dart';
import 'package:mybudget/data/provider/beneficiary_provider.dart';
import 'package:mybudget/data/provider/category_override_provider.dart';
import 'package:mybudget/data/provider/providers.dart';
import 'package:mybudget/ui/category_picker/category_picker_sheet.dart';
import 'package:mybudget/ui/common/expense_frequency_date_section.dart';
import 'package:mybudget/ui/common/widgets/beneficiary_selector.dart';
import 'package:mybudget/ui/common/widgets/category_field.dart';
import 'package:mybudget/ui/common/widgets/effective_month_field.dart';
import 'package:mybudget/ui/common/widgets/form_text.dart';

class RevenueFormScreen extends ConsumerStatefulWidget {
  const RevenueFormScreen({
    required this.accounts,
    this.revenue,
    this.closedRevenues = const [],
    super.key,
  });
  final List<AccountModel> accounts;
  final RevenueModel? revenue;
  final List<RevenueModel> closedRevenues;

  static Future<RevenueModel?> push({
    required BuildContext context,
    required List<AccountModel> accounts,
    RevenueModel? revenue,
    List<RevenueModel> closedRevenues = const [],
  }) {
    return Navigator.push<RevenueModel>(
      context,
      MaterialPageRoute<RevenueModel>(
        builder: (_) => RevenueFormScreen(
          accounts: accounts,
          revenue: revenue,
          closedRevenues: closedRevenues,
        ),
      ),
    );
  }

  @override
  ConsumerState<RevenueFormScreen> createState() => _RevenueFormScreenState();
}

class _RevenueFormScreenState extends ConsumerState<RevenueFormScreen> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  late Frequency _selectedFrequency;
  int? _selectedAccountId;
  String? _selectedCategorySlug;
  String? _categoryError;
  String? _accountError;
  String? _nameError;
  String? _amountError;

  int? _selectedBeneficiaryId;
  bool _beneficiaryEnabled = false;
  int? _parentId;
  EffectiveMonth _effectiveMonth = EffectiveMonth.thisMonth;

  bool get _isEditing => widget.revenue != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.revenue?.name ?? '');
    _amountController = TextEditingController(
      text: widget.revenue?.amount.toString() ?? '',
    );

    _selectedDate = widget.revenue?.startDate ?? _now;
    _selectedFrequency = widget.revenue?.frequencyEnum ?? Frequency.monthly;
    _selectedCategorySlug = widget.revenue?.categorySlug;
    _selectedAccountId =
        widget.revenue?.accountId ??
        (widget.accounts.isNotEmpty ? widget.accounts.first.id : null);
    _selectedBeneficiaryId = widget.revenue?.beneficiaryId;
    _beneficiaryEnabled = widget.revenue?.beneficiaryId != null;
    _resetEffectiveMonth();
  }

  DateTime get _now => ref.read(clockProvider)();

  Frequency get _frequency => _selectedFrequency;

  void _resetEffectiveMonth() {
    _effectiveMonth = defaultEffectiveMonth(
      frequency: _frequency,
      anchor: _selectedDate,
      asOf: _now,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FrostedScaffold(
      appBar: FrostedTopBar(
        title: _isEditing ? 'Modifier le revenu' : 'Ajouter un revenu',
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          Expanded(child: _fields(context)),
          _actions(context),
        ],
      ),
    );
  }

  Widget _fields(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        FrostedSpacing.sp4,
        FrostedTopBar.bodyTopPadding(context) + FrostedSpacing.sp2,
        FrostedSpacing.sp4,
        FrostedSpacing.sp4,
      ),
      children: [
        if (!_isEditing && widget.closedRevenues.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FrostedButton.text(
              label: 'Reprendre un ancien revenu',
              icon: Symbols.history_rounded,
              onPressed: _showClosedRevenuePicker,
            ),
          ),
        const FormSectionTitle('Informations'),
        const SizedBox(height: 12),
        FrostedTextField(
          controller: _nameController,
          label: 'Nom',
          hintText: 'Ex: Salaire',
          leadingIcon: Symbols.edit_rounded,
        ),
        FormFieldError(_nameError),
        const SizedBox(height: 16),
        FrostedTextField(
          controller: _amountController,
          label: 'Montant',
          hintText: '0.00',
          leadingIcon: Symbols.euro_rounded,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        FormFieldError(_amountError),
        const SizedBox(height: 24),
        const FormSectionTitle('Compte'),
        const SizedBox(height: 12),
        const FormFieldLabel('Catégorie'),
        const SizedBox(height: 8),
        CategoryField(
          category: _selectedCategorySlug == null
              ? null
              : ref
                    .watch(categoryDisplayResolverProvider)
                    .value
                    ?.resolve(_selectedCategorySlug!),
          onTap: _pickCategory,
        ),
        FormFieldError(_categoryError),
        const SizedBox(height: 16),
        const FormFieldLabel('Compte associé'),
        const SizedBox(height: 8),
        FrostedDropdown<int>(
          value: _selectedAccountId,
          items: widget.accounts
              .map(
                (account) => FrostedDropdownItem<int>(
                  value: account.id,
                  label: account.name,
                ),
              )
              .toList(),
          onChanged: (value) => setState(() {
            _selectedAccountId = value;
            _accountError = null;
          }),
        ),
        FormFieldError(_accountError),
        const SizedBox(height: 24),
        ExpenseFrequencyDateSection(
          frequency: _selectedFrequency,
          date: _selectedDate,
          onChanged: (frequency, date) => setState(() {
            _selectedFrequency = frequency;
            _selectedDate = date;
            _resetEffectiveMonth();
          }),
        ),
        if (!_isEditing && offersEffectiveMonthChoice(_frequency)) ...[
          const SizedBox(height: 16),
          EffectiveMonthField(
            now: _now,
            value: _effectiveMonth,
            frequency: _frequency,
            anchor: _selectedDate,
            label: 'Compter dès ce mois-ci',
            dueLabel: 'Première échéance',
            onChanged: (value) => setState(() => _effectiveMonth = value),
          ),
        ],
        const SizedBox(height: 24),
        BeneficiarySelector(
          beneficiaries: ref.watch(beneficiaryProvider).value ?? const [],
          onCreate: (name) =>
              ref.read(beneficiaryProvider.notifier).createBeneficiary(name),
          initialBeneficiaryId: widget.revenue?.beneficiaryId,
          onChanged: (id) => setState(() {
            _selectedBeneficiaryId = id;
            _beneficiaryEnabled = id != null;
          }),
        ),
      ],
    );
  }

  Widget _actions(BuildContext context) {
    final bool awaitingBeneficiary =
        _beneficiaryEnabled && _selectedBeneficiaryId == null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        FrostedSpacing.sp4,
        0,
        FrostedSpacing.sp4,
        MediaQuery.of(context).padding.bottom + FrostedSpacing.sp4,
      ),
      child: Row(
        children: [
          Expanded(
            child: FrostedButton.text(
              label: 'Annuler',
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: FrostedSpacing.sp3),
          Expanded(
            child: FrostedButton.filled(
              label: _isEditing ? 'Enregistrer' : 'Ajouter',
              onPressed: awaitingBeneficiary ? null : _handleSubmit,
            ),
          ),
        ],
      ),
    );
  }

  void _fillFromClosedRevenue(RevenueModel closed) {
    setState(() {
      _nameController.text = closed.name;
      _amountController.text = closed.amount.toString();
      _selectedFrequency = closed.frequencyEnum;
      _selectedAccountId = closed.accountId;
      _selectedCategorySlug = closed.categorySlug;
      _selectedBeneficiaryId = closed.beneficiaryId;
      _beneficiaryEnabled = closed.beneficiaryId != null;
      _parentId = closed.parentId ?? closed.id;
      _selectedDate = _now;
      _resetEffectiveMonth();
    });
  }

  void _showClosedRevenuePicker() {
    showFrostedDialog<void>(
      context: context,
      builder: (_) => FrostedDialog(
        title: 'Reprendre un revenu',
        body: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.closedRevenues.length,
            itemBuilder: (context, index) {
              final revenue = widget.closedRevenues[index];
              return FrostedListTile(
                title: revenue.name,
                subtitle: MoneyFormatter.format(revenue.amount),
                trailing: const Icon(Symbols.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(context);
                  _fillFromClosedRevenue(revenue);
                },
              );
            },
          ),
        ),
        actions: [
          FrostedButton.text(
            label: 'Annuler',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  DateTime _createStartDate() => startDateFor(
    frequency: _frequency,
    anchor: _selectedDate,
    asOf: _now,
    scope: _effectiveMonth,
  );

  void _handleSubmit() {
    setState(() {
      _nameError = _nameController.text.trim().isEmpty
          ? 'Veuillez saisir un nom'
          : null;
      _amountError = _amountController.text.isEmpty
          ? 'Veuillez saisir un montant'
          : null;
      _accountError = _selectedAccountId == null
          ? 'Veuillez sélectionner un compte'
          : null;
      _categoryError = _selectedCategorySlug == null
          ? 'Veuillez sélectionner une catégorie'
          : null;
    });

    if (_nameError != null ||
        _amountError != null ||
        _accountError != null ||
        _categoryError != null) {
      return;
    }

    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;

    if (amount <= 0) {
      setState(() => _amountError = 'Le montant doit être supérieur à 0');
      return;
    }

    final revenue = _isEditing
        ? widget.revenue!.copyWith(
            name: _nameController.text.trim(),
            amount: amount,
            startDate: _selectedDate,
            accountId: _selectedAccountId!,
            frequency: _selectedFrequency,
            beneficiaryId: _selectedBeneficiaryId,
            categorySlug: _selectedCategorySlug,
          )
        : RevenueModel.create(
            name: _nameController.text.trim(),
            amount: amount,
            startDate: _createStartDate(),
            accountId: _selectedAccountId!,
            frequency: _selectedFrequency,
            beneficiaryId: _selectedBeneficiaryId,
            parentId: _parentId,
            categorySlug: _selectedCategorySlug,
          );

    Navigator.pop(context, revenue);
  }

  Future<void> _pickCategory() async {
    final slug = await CategoryPickerSheet.show(
      context,
      type: TransactionType.income,
      selectedSlug: _selectedCategorySlug,
    );
    if (slug == null || !mounted) return;
    setState(() {
      _selectedCategorySlug = slug;
      _categoryError = null;
    });
  }
}
