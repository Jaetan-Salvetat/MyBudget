import 'package:flutter/material.dart';
import 'package:mybudget/models/revenue_model.dart';
import 'package:mybudget/models/account_model.dart';

class RevenueBottomSheet extends StatefulWidget {
  final List<AccountModel> accounts;
  final RevenueModel? revenue;
  final Function(RevenueModel) onSubmit;
  final VoidCallback onCancel;

  const RevenueBottomSheet({
    required this.accounts,
    required this.onSubmit,
    required this.onCancel,
    this.revenue,
    super.key,
  });

  static void show({
    required BuildContext context,
    required List<AccountModel> accounts,
    required Function(RevenueModel) onSubmit,
    required VoidCallback onCancel,
    RevenueModel? revenue,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: RevenueBottomSheet(
              accounts: accounts,
              onSubmit: onSubmit,
              onCancel: onCancel,
              revenue: revenue,
            ),
          ),
    );
  }

  @override
  State<RevenueBottomSheet> createState() => _RevenueBottomSheetState();
}

class _RevenueBottomSheetState extends State<RevenueBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  bool _isRegular = true;
  DateTime _selectedDate = DateTime.now();
  int? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.revenue?.name ?? '');
    _amountController = TextEditingController(
      text: widget.revenue?.amount.toString() ?? '',
    );

    _isRegular = widget.revenue?.isRegular ?? true;
    _selectedDate = widget.revenue?.date ?? DateTime.now();
    _selectedAccountId =
        widget.revenue?.accountId ??
        (widget.accounts.isNotEmpty ? widget.accounts.first.id : null);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_nameController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _selectedAccountId == null) {
      return;
    }

    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;

    final revenue =
        widget.revenue != null
            ? widget.revenue!.copyWith(
              name: _nameController.text.trim(),
              amount: amount,
              isRegular: _isRegular,
              date: _selectedDate,
              accountId: _selectedAccountId!,
            )
            : RevenueModel.create(
              name: _nameController.text.trim(),
              amount: amount,
              isRegular: _isRegular,
              date: _selectedDate,
              accountId: _selectedAccountId!,
            );

    widget.onSubmit(revenue);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.revenue == null ? 'Ajouter un revenu' : 'Modifier le revenu',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

           
          Text(
            'Informations',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Montant',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.euro),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),

          const SizedBox(height: 24),
           
          Text(
            'Planification',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
           
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
              ),
            ),
          ),

          const SizedBox(height: 24),
           
          Text(
            'Compte',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _selectedAccountId,
            decoration: const InputDecoration(
              labelText: 'Compte associé',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.account_balance),
            ),
            items:
                widget.accounts.map((account) {
                  return DropdownMenuItem<int>(
                    value: account.id,
                    child: Text(account.name),
                  );
                }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedAccountId = value;
                });
              }
            },
          ),

          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  widget.onCancel();
                  Navigator.pop(context);
                },
                child: const Text('Annuler'),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: _handleSubmit,
                child: Text(widget.revenue == null ? 'Ajouter' : 'Enregistrer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
