import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/enums/effective_month.dart';
import 'package:mybudget/core/enums/frequency.dart';
import 'package:mybudget/core/formatting/money_formatter.dart';
import 'package:mybudget/core/rules/recurrence_rules.dart';
import 'package:mybudget/data/model/account_model.dart';
import 'package:mybudget/data/model/expense_model.dart';
import 'package:mybudget/data/provider/beneficiary_provider.dart';
import 'package:mybudget/data/provider/category_override_provider.dart';
import 'package:mybudget/data/provider/providers.dart';
import 'package:mybudget/ui/category_picker/category_picker_sheet.dart';
import 'package:mybudget/ui/common/expense_frequency_date_section.dart';
import 'package:mybudget/ui/common/widgets/beneficiary_selector.dart';
import 'package:mybudget/ui/common/widgets/category_field.dart';
import 'package:mybudget/ui/common/widgets/effective_month_field.dart';
import 'package:mybudget/ui/common/widgets/form_text.dart';

const Frequency _defaultFrequency = Frequency.monthly;

class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({
    required this.accounts,
    this.expense,
    this.closedExpenses = const [],
    super.key,
  });
  final List<AccountModel> accounts;
  final ExpenseModel? expense;
  final List<ExpenseModel> closedExpenses;

  static Future<ExpenseModel?> push({
    required BuildContext context,
    required List<AccountModel> accounts,
    ExpenseModel? expense,
    List<ExpenseModel> closedExpenses = const [],
  }) {
    return Navigator.push<ExpenseModel>(
      context,
      MaterialPageRoute<ExpenseModel>(
        builder: (_) => ExpenseFormScreen(
          accounts: accounts,
          expense: expense,
          closedExpenses: closedExpenses,
        ),
      ),
    );
  }

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  String? _selectedCategorySlug;
  late DateTime _selectedDate;
  Frequency _selectedFrequency = _defaultFrequency;
  int? _selectedAccountId;
  String? _nameError;
  String? _categoryError;
  String? _accountError;
  String? _amountError;

  int? _selectedBeneficiaryId;
  bool _beneficiaryEnabled = false;
  int? _parentId;
  EffectiveMonth _effectiveMonth = EffectiveMonth.thisMonth;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.expense?.name ?? '');
    _amountController = TextEditingController(
      text: widget.expense?.amount.toString() ?? '',
    );

    _selectedCategorySlug = widget.expense?.categorySlug;
    _selectedDate = widget.expense?.startDate ?? _now;
    _selectedFrequency = widget.expense?.frequencyEnum ?? _defaultFrequency;
    _selectedAccountId =
        widget.expense?.accountId ??
        (widget.accounts.isNotEmpty ? widget.accounts.first.id : null);
    _selectedBeneficiaryId = widget.expense?.beneficiaryId;
    _beneficiaryEnabled = widget.expense?.beneficiaryId != null;
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

  double get _parsedAmount =>
      double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;

  @override
  Widget build(BuildContext context) {
    return FrostedScaffold(
      appBar: FrostedTopBar(
        title: _isEditing ? 'Modifier la dépense' : 'Ajouter une dépense',
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
        if (!_isEditing && widget.closedExpenses.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FrostedButton.text(
              label: 'Reprendre une ancienne dépense',
              icon: Symbols.history_rounded,
              onPressed: _showClosedExpensePicker,
            ),
          ),
        const FormSectionTitle('Informations'),
        const SizedBox(height: 12),
        FrostedTextField(
          controller: _nameController,
          label: 'Nom',
          hintText: 'Ex: Loyer',
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
        const SizedBox(height: 16),
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
        const FormSectionTitle('Compte'),
        const SizedBox(height: 12),
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
        BeneficiarySelector(
          beneficiaries: ref.watch(beneficiaryProvider).value ?? const [],
          onCreate: (name) =>
              ref.read(beneficiaryProvider.notifier).createBeneficiary(name),
          initialBeneficiaryId: widget.expense?.beneficiaryId,
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

  bool _validateFields() {
    bool isValid = true;
    setState(() {
      if (_nameController.text.trim().isEmpty) {
        _nameError = 'Veuillez saisir un nom';
        isValid = false;
      } else {
        _nameError = null;
      }

      if (_parsedAmount <= 0) {
        _amountError = 'Le montant doit être supérieur à 0';
        isValid = false;
      } else {
        _amountError = null;
      }

      if (_selectedCategorySlug == null) {
        _categoryError = 'Veuillez sélectionner une catégorie';
        isValid = false;
      } else {
        _categoryError = null;
      }

      if (_selectedAccountId == null) {
        _accountError = 'Veuillez sélectionner un compte';
        isValid = false;
      } else {
        _accountError = null;
      }
    });
    return isValid;
  }

  DateTime _createStartDate() => startDateFor(
    frequency: _frequency,
    anchor: _selectedDate,
    asOf: _now,
    scope: _effectiveMonth,
  );

  void _handleSubmit() {
    if (!_validateFields()) return;

    final expense = _isEditing
        ? widget.expense!.copyWith(
            name: _nameController.text.trim(),
            amount: _parsedAmount,
            categorySlug: _selectedCategorySlug,
            startDate: _selectedDate,
            frequency: _selectedFrequency,
            accountId: _selectedAccountId!,
            beneficiaryId: _selectedBeneficiaryId,
          )
        : ExpenseModel.create(
            name: _nameController.text.trim(),
            amount: _parsedAmount,
            categorySlug: _selectedCategorySlug,
            startDate: _createStartDate(),
            frequency: _selectedFrequency,
            accountId: _selectedAccountId!,
            beneficiaryId: _selectedBeneficiaryId,
            parentId: _parentId,
          );

    Navigator.pop(context, expense);
  }

  void _fillFromClosedExpense(ExpenseModel closed) {
    setState(() {
      _nameController.text = closed.name;
      _amountController.text = closed.amount.toString();
      _selectedCategorySlug = closed.categorySlug;
      _selectedFrequency = closed.frequencyEnum;
      _selectedAccountId = closed.accountId;
      _selectedBeneficiaryId = closed.beneficiaryId;
      _beneficiaryEnabled = closed.beneficiaryId != null;
      _parentId = closed.parentId ?? closed.id;
      _selectedDate = _now;
      _resetEffectiveMonth();
    });
  }

  void _showClosedExpensePicker() {
    showFrostedDialog<void>(
      context: context,
      builder: (_) => FrostedDialog(
        title: 'Reprendre une dépense',
        body: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.closedExpenses.length,
            itemBuilder: (context, index) {
              final expense = widget.closedExpenses[index];
              return FrostedListTile(
                title: expense.name,
                subtitle: MoneyFormatter.format(expense.amount),
                trailing: const Icon(Symbols.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(context);
                  _fillFromClosedExpense(expense);
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

  Future<void> _pickCategory() async {
    final slug = await CategoryPickerSheet.show(
      context,
      selectedSlug: _selectedCategorySlug,
    );
    if (slug == null || !mounted) return;
    setState(() {
      _selectedCategorySlug = slug;
      _categoryError = null;
    });
  }
}
