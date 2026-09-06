import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/formatting/money_formatter.dart';
import 'package:mybudget/models/account_model.dart';
import 'package:mybudget/models/transfer_model.dart';
import 'package:mybudget/ui/common/expense_frequency_date_section.dart';

class TransferBottomSheet extends StatefulWidget {
  final List<AccountModel> accounts;
  final TransferModel? transfer;
  final List<TransferModel> closedTransfers;
  final Function(TransferModel) onSubmit;
  final VoidCallback onCancel;

  const TransferBottomSheet({
    required this.accounts,
    required this.onSubmit,
    required this.onCancel,
    this.transfer,
    this.closedTransfers = const [],
    super.key,
  });

  static void show({
    required BuildContext context,
    required List<AccountModel> accounts,
    required Function(TransferModel) onSubmit,
    required VoidCallback onCancel,
    TransferModel? transfer,
    List<TransferModel> closedTransfers = const [],
  }) {
    showFrostedBottomSheet<void>(
      context: context,
      builder: (_) => FrostedBottomSheet(
        title: transfer == null
            ? 'Ajouter un virement'
            : 'Modifier le virement',
        child: TransferBottomSheet(
          accounts: accounts,
          onSubmit: onSubmit,
          onCancel: onCancel,
          transfer: transfer,
          closedTransfers: closedTransfers,
        ),
      ),
    );
  }

  @override
  State<TransferBottomSheet> createState() => _TransferBottomSheetState();
}

class _TransferBottomSheetState extends State<TransferBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  int? _selectedFromAccountId;
  int? _selectedToAccountId;
  DateTime _selectedDate = DateTime.now();
  String _selectedFrequency = 'Mensuel';
  String? _nameError;
  String? _fromAccountError;
  String? _toAccountError;
  String? _amountError;
  int? _parentId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.transfer?.name ?? '');
    _amountController = TextEditingController(
      text: widget.transfer?.amount.toString() ?? '',
    );

    _selectedFromAccountId =
        widget.transfer?.fromAccountId ??
        (widget.accounts.isNotEmpty ? widget.accounts.first.id : null);
    _selectedToAccountId = widget.transfer?.toAccountId;
    _selectedDate = widget.transfer?.startDate ?? DateTime.now();
    _selectedFrequency = widget.transfer?.frequency ?? 'Mensuel';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  List<AccountModel> get _availableDestinations =>
      widget.accounts.where((a) => a.id != _selectedFromAccountId).toList();

  bool _validateFields() {
    bool isValid = true;
    setState(() {
      if (_nameController.text.trim().isEmpty) {
        _nameError = 'Veuillez saisir un nom';
        isValid = false;
      } else {
        _nameError = null;
      }

      final amount =
          double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
      if (amount <= 0) {
        _amountError = 'Le montant doit être supérieur à 0';
        isValid = false;
      } else {
        _amountError = null;
      }

      if (_selectedFromAccountId == null) {
        _fromAccountError = 'Veuillez sélectionner un compte source';
        isValid = false;
      } else {
        _fromAccountError = null;
      }

      if (_selectedToAccountId == null) {
        _toAccountError = 'Veuillez sélectionner un compte destination';
        isValid = false;
      } else {
        _toAccountError = null;
      }

      if (_selectedFromAccountId != null &&
          _selectedToAccountId != null &&
          _selectedFromAccountId == _selectedToAccountId) {
        _toAccountError = 'Le compte destination doit être différent';
        isValid = false;
      }
    });
    return isValid;
  }

  void _fillFromClosedTransfer(TransferModel closed) {
    setState(() {
      _nameController.text = closed.name;
      _amountController.text = closed.amount.toString();
      _selectedFromAccountId = closed.fromAccountId;
      _selectedToAccountId = closed.toAccountId;
      _selectedFrequency = closed.frequency;
      _parentId = closed.parentId ?? closed.id;
      _selectedDate = DateTime.now();
    });
  }

  void _showClosedTransferPicker(BuildContext context) {
    showFrostedDialog<void>(
      context: context,
      builder: (_) => FrostedDialog(
        title: 'Reprendre un virement',
        body: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.closedTransfers.length,
            itemBuilder: (context, index) {
              final transfer = widget.closedTransfers[index];
              return FrostedListTile(
                title: transfer.name,
                subtitle: MoneyFormatter.format(transfer.amount),
                trailing: const Icon(Symbols.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(context);
                  _fillFromClosedTransfer(transfer);
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

  Future<void> _handleSubmit() async {
    if (!_validateFields()) {
      return;
    }

    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;

    final transfer = widget.transfer != null
        ? widget.transfer!.copyWith(
            name: _nameController.text.trim(),
            amount: amount,
            fromAccountId: _selectedFromAccountId!,
            toAccountId: _selectedToAccountId!,
            startDate: _selectedDate,
            frequency: _selectedFrequency,
          )
        : TransferModel.create(
            name: _nameController.text.trim(),
            amount: amount,
            fromAccountId: _selectedFromAccountId!,
            toAccountId: _selectedToAccountId!,
            startDate: _selectedDate,
            frequency: _selectedFrequency,
            parentId: _parentId,
          );

    widget.onSubmit(transfer);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.transfer == null && widget.closedTransfers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FrostedButton.text(
                label: 'Reprendre un ancien virement',
                icon: Symbols.history_rounded,
                onPressed: () => _showClosedTransferPicker(context),
              ),
            ),
          Text(
            'Informations',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          FrostedTextField(
            controller: _nameController,
            label: 'Nom',
            hintText: 'Ex: Épargne mensuelle',
            leadingIcon: Symbols.edit_rounded,
          ),
          if (_nameError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 12.0),
              child: Text(
                _nameError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 16),
          FrostedTextField(
            controller: _amountController,
            label: 'Montant',
            hintText: '0.00',
            leadingIcon: Symbols.euro_rounded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          if (_amountError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 12.0),
              child: Text(
                _amountError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),

          const SizedBox(height: 24),

          Text(
            'Comptes',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Compte source',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              FrostedDropdown<int>(
                value: _selectedFromAccountId,
                items: widget.accounts.map((account) {
                  return FrostedDropdownItem<int>(
                    value: account.id,
                    label: account.name,
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFromAccountId = value;
                    _fromAccountError = null;
                    if (_selectedToAccountId == value) {
                      _selectedToAccountId = null;
                    }
                  });
                },
              ),
              if (_fromAccountError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                  child: Text(
                    _fromAccountError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Compte destination',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              FrostedDropdown<int>(
                value: _selectedToAccountId,
                items: _availableDestinations.map((account) {
                  return FrostedDropdownItem<int>(
                    value: account.id,
                    label: account.name,
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedToAccountId = value;
                    _toAccountError = null;
                  });
                },
              ),
              if (_toAccountError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                  child: Text(
                    _toAccountError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          ExpenseFrequencyDateSection(
            frequency: _selectedFrequency,
            date: _selectedDate,
            onChanged: (freq, date) {
              setState(() {
                _selectedFrequency = freq;
                _selectedDate = date;
              });
            },
          ),

          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FrostedButton.text(
                label: 'Annuler',
                onPressed: () {
                  widget.onCancel();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(width: 16),
              FrostedButton.filled(
                label: widget.transfer == null ? 'Ajouter' : 'Enregistrer',
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
