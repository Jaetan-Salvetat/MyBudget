import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/entities/beneficiary.dart';
import 'package:mybudget/ui/settings/beneficiary_provider.dart';

class BeneficiarySelector extends ConsumerStatefulWidget {
  final int? initialBeneficiaryId;
  final ValueChanged<int?> onChanged;

  const BeneficiarySelector({
    required this.onChanged,
    this.initialBeneficiaryId,
    super.key,
  });

  @override
  ConsumerState<BeneficiarySelector> createState() => _BeneficiarySelectorState();
}

class _BeneficiarySelectorState extends ConsumerState<BeneficiarySelector> {
  bool _enabled = false;
  int? _selectedId;
  bool _isCreating = false;
  bool _isLoading = false;
  final _newNameController = TextEditingController();
  String? _createError;

  @override
  void initState() {
    super.initState();
    if (widget.initialBeneficiaryId != null) {
      _enabled = true;
      _selectedId = widget.initialBeneficiaryId;
    }
  }

  @override
  void dispose() {
    _newNameController.dispose();
    super.dispose();
  }

  void _onToggle(bool value, List<Beneficiary> beneficiaries) {
    setState(() {
      _enabled = value;
      if (!value) {
        _selectedId = null;
        _isCreating = false;
        _newNameController.clear();
        _createError = null;
        widget.onChanged(null);
      } else if (beneficiaries.isEmpty) {
        _isCreating = true;
      }
    });
  }

  void _onDropdownChanged(int? value) {
    setState(() => _selectedId = value);
    widget.onChanged(value);
  }

  Future<void> _confirmCreate() async {
    final beneficiaryNotifier = ref.read(beneficiaryProvider.notifier);
    final beneficiaries = ref.read(beneficiaryProvider).value ?? [];
    final name = _newNameController.text.trim();
    if (name.isEmpty) {
      setState(() => _createError = 'Le nom ne peut pas être vide');
      return;
    }
    final duplicate = beneficiaries.any(
      (b) => b.name.toLowerCase() == name.toLowerCase(),
    );
    if (duplicate) {
      setState(() => _createError = 'Ce bénéficiaire existe déjà');
      return;
    }

    setState(() {
      _isLoading = true;
      _createError = null;
    });

    final newId = await beneficiaryNotifier.createBeneficiary(name);

    if (!mounted) return;

    if (newId != null) {
      setState(() {
        _selectedId = newId;
        _isCreating = false;
        _isLoading = false;
        _newNameController.clear();
      });
      widget.onChanged(newId);
    } else {
      setState(() {
        _isLoading = false;
        _createError = 'Erreur lors de la création du bénéficiaire';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final beneficiaries = ref.watch(beneficiaryProvider).value ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bénéficiaire',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            FrostedSwitch(
              value: _enabled,
              onChanged: (v) => _onToggle(v, beneficiaries),
            ),
          ],
        ),
        if (_enabled) ...[
          const SizedBox(height: 12),
          if (_isCreating) ...[
            FrostedTextField(
              controller: _newNameController,
              labelText: 'Nom du bénéficiaire',
              hintText: 'Ex: Paul',
              prefixIcon: const Icon(Icons.person_outline),
            ),
            if (_createError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                child: Text(
                  _createError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (beneficiaries.isNotEmpty)
                  FrostedTextButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() {
                              _isCreating = false;
                              _newNameController.clear();
                              _createError = null;
                            }),
                    child: const Text('Annuler'),
                  ),
                const Spacer(),
                _isLoading
                    ? const FrostedCircularProgressIndicator(strokeWidth: 2, size: 24)
                    : FrostedFilledButton(
                        onPressed: _confirmCreate,
                        child: const Text('Confirmer'),
                      ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: FrostedDropdown<int>(
                    value: _selectedId,
                    items: beneficiaries
                        .map(
                          (b) => DropdownMenuItem<int>(
                            value: b.id,
                            child: Text(b.name),
                          ),
                        )
                        .toList(),
                    onChanged: _onDropdownChanged,
                  ),
                ),
                const SizedBox(width: 8),
                FrostedIconButton(
                  icon: Icons.add,
                  onPressed: () => setState(() {
                    _isCreating = true;
                    _newNameController.clear();
                    _createError = null;
                  }),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}
