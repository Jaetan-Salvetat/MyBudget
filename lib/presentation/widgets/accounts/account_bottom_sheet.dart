import 'package:flutter/material.dart';
import 'package:mybudget/data/models/account_model.dart';
import 'package:mybudget/presentation/widgets/common/app_text_field.dart';
import 'package:mybudget/presentation/widgets/common/modal_bottom_sheet.dart';

class AccountBottomSheet extends StatefulWidget {
  final AccountModel? account;
  final Function(String name, String bank) onSubmit;
  final Function() onCancel;

  const AccountBottomSheet({
    required this.onSubmit,
    required this.onCancel,
    this.account,
    super.key,
  });

  static Future<void> show({
    required BuildContext context,
    required Function(String name, String bank) onSubmit,
    required Function() onCancel,
    AccountModel? account,
  }) {
    return AppModalBottomSheet.show(
      context: context,
      title: account == null ? 'Ajouter un compte' : 'Modifier le compte',
      content: AccountBottomSheet(
        onSubmit: onSubmit,
        onCancel: onCancel,
        account: account,
      ),
      actions: const [], // Actions sont gérées dans le widget enfant
      isScrollable: false,
    );
  }

  @override
  State<AccountBottomSheet> createState() => _AccountBottomSheetState();
}

class _AccountBottomSheetState extends State<AccountBottomSheet> {
  final nameController = TextEditingController();
  final bankController = TextEditingController();
  String? nameError;
  String? bankError;
  final List<String> suggestedBanks = [
    'BNP Paribas',
    'Société Générale',
    'Crédit Agricole',
    'Caisse d\'Épargne',
    'Banque Populaire',
    'HSBC',
    'LCL',
    'Crédit Mutuel',
    'La Banque Postale',
    'Boursorama',
    'Fortuneo',
    'N26',
    'Revolut',
    'Lydia',
    'Trade Republic',
    'HelloBank',
    'ING',
    'Monabanq',
    'Orange Bank',
    'Ma French Bank',
    'C-zam',
  ];
  String? selectedBank;

  @override
  void initState() {
    super.initState();

    bankController.addListener(() {
      setState(() {
        if (selectedBank != null && bankController.text != selectedBank) {
          selectedBank = null;
        }
      });
    });

    if (widget.account != null) {
      nameController.text = widget.account!.name;
      bankController.text = widget.account!.bank;
      if (suggestedBanks.contains(widget.account!.bank)) {
        selectedBank = widget.account!.bank;
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    bankController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: nameController,
          label: 'Nom du compte',
          icon: Icons.account_balance_wallet_outlined,
          errorText: nameError,
          onChanged:
              (_) => setState(() {
                if (nameError != null) nameError = null;
              }),
        ),
        const SizedBox(height: 20),
        if (selectedBank == null) ...[
          AppTextField(
            controller: bankController,
            label: 'Banque',
            icon: Icons.account_balance_outlined,
            errorText: bankError,
            onChanged:
                (_) => setState(() {
                  if (bankError != null) bankError = null;
                }),
          ),
          const SizedBox(height: 16),
          _buildBankSuggestions(),
        ] else ...[
          _buildSelectedBank(),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: AppModalButton(
                label: 'Annuler',
                onPressed: widget.onCancel,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppModalButton(
                label: widget.account == null ? 'Ajouter' : 'Enregistrer',
                isPrimary: true,
                onPressed: () {
                  bool isValid = true;

                  setState(() {
                    if (nameController.text.isEmpty) {
                      nameError = 'Le nom du compte est requis';
                      isValid = false;
                    }

                    if (bankController.text.isEmpty && selectedBank == null) {
                      bankError = 'La banque est requise';
                      isValid = false;
                    }
                  });

                  if (isValid) {
                    widget.onSubmit(
                      nameController.text.trim(),
                      selectedBank ?? bankController.text.trim(),
                    );
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBankSuggestions() {
    final searchQuery = bankController.text.toLowerCase();

    // Filtrage des banques selon le texte saisi
    final filteredBanks =
        suggestedBanks
            .where((bank) => bank.toLowerCase().contains(searchQuery))
            .take(searchQuery.isEmpty ? 8 : 12)
            .toList();

    // On affiche "Voir tout" uniquement quand il y a plus de banques que celles affichées
    final hasMoreSuggestions =
        suggestedBanks
            .where((bank) => bank.toLowerCase().contains(searchQuery))
            .length >
        (searchQuery.isEmpty ? 8 : 12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Suggestions',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (hasMoreSuggestions)
                TextButton(
                  onPressed: () {
                    _showFullBankList(context);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 36),
                  ),
                  child: Text(
                    'Voir tout',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              filteredBanks.map((bank) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedBank = bank;
                      bankController.text = bank;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Chip(
                    label: Text(bank),
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  void _showFullBankList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _BankListBottomSheet(
          banks: suggestedBanks,
          initialSearchQuery: bankController.text,
          onBankSelected: (bank) {
            setState(() {
              selectedBank = bank;
              bankController.text = bank;
            });
          },
        );
      },
    );
  }

  Widget _buildSelectedBank() {
    return InkWell(
      onTap: () {
        setState(() {
          selectedBank = null;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Banque',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    selectedBank!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _BankListBottomSheet extends StatefulWidget {
  final List<String> banks;
  final Function(String) onBankSelected;
  final String initialSearchQuery;

  const _BankListBottomSheet({
    required this.banks,
    required this.onBankSelected,
    this.initialSearchQuery = '',
  });

  @override
  State<_BankListBottomSheet> createState() => _BankListBottomSheetState();
}

class _BankListBottomSheetState extends State<_BankListBottomSheet> {
  late List<String> filteredBanks;
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    searchController.text = widget.initialSearchQuery;
    filteredBanks =
        widget.initialSearchQuery.isEmpty
            ? widget.banks
            : widget.banks
                .where(
                  (bank) => bank.toLowerCase().contains(
                    widget.initialSearchQuery.toLowerCase(),
                  ),
                )
                .toList();
    searchController.addListener(_filterBanks);
  }

  @override
  void dispose() {
    searchController.removeListener(_filterBanks);
    searchController.dispose();
    super.dispose();
  }

  void _filterBanks() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredBanks =
          query.isEmpty
              ? widget.banks
              : widget.banks
                  .where((bank) => bank.toLowerCase().contains(query))
                  .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  'Toutes les banques',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher une banque',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child:
                filteredBanks.isEmpty
                    ? Center(
                      child: Text(
                        'Aucune banque trouvée',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                    : GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: filteredBanks.length,
                      itemBuilder: (context, index) {
                        final bank = filteredBanks[index];
                        return InkWell(
                          onTap: () {
                            widget.onBankSelected(bank);
                            Navigator.of(context).pop();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                bank,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
