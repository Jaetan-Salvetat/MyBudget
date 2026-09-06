import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/constants/banks_list.dart';
import 'package:mybudget/models/account_model.dart';

class AccountFormScreen extends StatefulWidget {
  const AccountFormScreen({this.account, super.key});
  final AccountModel? account;

  static Future<AccountModel?> push({
    required BuildContext context,
    AccountModel? account,
  }) {
    return Navigator.push<AccountModel>(
      context,
      MaterialPageRoute<AccountModel>(
        builder: (_) => AccountFormScreen(account: account),
      ),
    );
  }

  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bankController;
  late FocusNode _bankFocusNode;
  bool _isFormValid = false;

  bool get _isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _bankController = TextEditingController(text: widget.account?.bank ?? '');
    _bankFocusNode = FocusNode();

    _validateForm();

    _nameController.addListener(_validateForm);
    _bankController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _bankFocusNode.dispose();
    _nameController.dispose();
    _bankController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final isValid =
        _nameController.text.trim().isNotEmpty &&
        _bankController.text.trim().isNotEmpty;
    if (isValid != _isFormValid) {
      setState(() => _isFormValid = isValid);
    }
  }

  void _handleSubmit() {
    if (!_isFormValid) return;

    final name = _nameController.text.trim();
    final bank = _bankController.text.trim();
    final account = _isEditing
        ? widget.account!.copyWith(name: name, bank: bank)
        : AccountModel.create(name: name, bank: bank);

    Navigator.pop(context, account);
  }

  @override
  Widget build(BuildContext context) {
    return FrostedScaffold(
      appBar: FrostedTopBar(
        title: _isEditing ? 'Modifier le compte' : 'Ajouter un compte',
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
        FrostedTextField(
          controller: _nameController,
          label: 'Nom du compte',
          hintText: 'Ex: Compte Courant',
          leadingIcon: Symbols.account_balance_wallet_rounded,
          autofocus: !_isEditing,
        ),
        const SizedBox(height: 16),
        FrostedAutocomplete(
          options: BanksList.frenchBanks,
          onSelected: (String selection) => _validateForm(),
          controller: _bankController,
          focusNode: _bankFocusNode,
          label: 'Nom de la banque',
          hintText: 'Ex: Crédit Agricole',
          leadingIcon: Symbols.account_balance_rounded,
        ),
      ],
    );
  }

  Widget _actions(BuildContext context) {
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
              onPressed: _isFormValid ? _handleSubmit : null,
            ),
          ),
        ],
      ),
    );
  }
}
