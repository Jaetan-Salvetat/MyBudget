import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/models/beneficiary_model.dart';

/// Widget réutilisable pour sélectionner ou créer un bénéficiaire.
/// - Switch ON/OFF pour activer la sélection
/// - Mode dropdown : sélection parmi les bénéficiaires existants
/// - Mode création : champ texte + "Confirmer" qui crée immédiatement en base
///
/// [onChanged] est appelé avec l'id sélectionné (ou null si switch OFF).
/// [onCreateBeneficiary] crée le bénéficiaire en base et retourne son id (ou null si erreur).
class BeneficiarySelector extends StatefulWidget {
  final List<BeneficiaryModel> beneficiaries;
  final int? initialBeneficiaryId;
  final ValueChanged<int?> onChanged;
  final Future<int?> Function(String name) onCreateBeneficiary;

  const BeneficiarySelector({
    required this.beneficiaries,
    required this.onChanged,
    required this.onCreateBeneficiary,
    this.initialBeneficiaryId,
    super.key,
  });

  @override
  State<BeneficiarySelector> createState() => _BeneficiarySelectorState();
}

class _BeneficiarySelectorState extends State<BeneficiarySelector> {
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

  void _onToggle(bool value) {
    setState(() {
      _enabled = value;
      if (!value) {
        _selectedId = null;
        _isCreating = false;
        _newNameController.clear();
        _createError = null;
        widget.onChanged(null);
      } else if (widget.beneficiaries.isEmpty) {
        _isCreating = true;
      }
    });
  }

  void _onDropdownChanged(int? value) {
    setState(() => _selectedId = value);
    widget.onChanged(value);
  }

  Future<void> _confirmCreate() async {
    final name = _newNameController.text.trim();
    if (name.isEmpty) {
      setState(() => _createError = 'Le nom ne peut pas être vide');
      return;
    }
    final duplicate = widget.beneficiaries.any(
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

    final newId = await widget.onCreateBeneficiary(name);

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
            Switch(
              value: _enabled,
              onChanged: _onToggle,
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
                if (widget.beneficiaries.isNotEmpty)
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
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
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
                    items: widget.beneficiaries
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
