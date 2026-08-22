import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mybudget/core/entities/beneficiary.dart';
import 'package:mybudget/ui/common/widgets/beneficiary_avatar.dart';
import 'package:mybudget/ui/common/widgets/search_input.dart';
import 'package:mybudget/ui/settings/beneficiary_provider.dart';

/// Flat list of beneficiaries, mirroring the categories screen: plain rows on
/// the page surface, no dividers, and a search field once the list outgrows a
/// single glance.
class BeneficiariesScreen extends ConsumerStatefulWidget {
  const BeneficiariesScreen({super.key});

  @override
  ConsumerState<BeneficiariesScreen> createState() =>
      _BeneficiariesScreenState();
}

class _BeneficiariesScreenState extends ConsumerState<BeneficiariesScreen> {
  static const int _searchThreshold = 6;
  static const double _listBottomPadding = 24;

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FrostedScaffold(
      appBar: FrostedTopBar(
        title: 'Bénéficiaires',
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        actions: [
          Tooltip(
            message: 'Ajouter un bénéficiaire',
            child: FrostedIconButton.tonal(
              icon: Symbols.add_rounded,
              onPressed: _showAddDialog,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          FrostedTopBar.bodyTopPadding(context) + 12,
          16,
          0,
        ),
        child: ref
            .watch(beneficiaryProvider)
            .when(
              loading: () => const Center(child: FrostedCircularProgress()),
              error: (error, _) => Center(child: Text('Erreur : $error')),
              data: _content,
            ),
      ),
    );
  }

  Widget _content(List<Beneficiary> beneficiaries) {
    if (beneficiaries.isEmpty) return const _EmptyState();

    final usages = ref.read(beneficiaryProvider.notifier).usageCounts();
    final matches = _matching(beneficiaries);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (beneficiaries.length >= _searchThreshold) ...[
          SearchInput(
            controller: _searchController,
            hintText: 'Rechercher un bénéficiaire…',
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: matches.isEmpty
              ? const _EmptyState()
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: _listBottomPadding),
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final beneficiary = matches[index];
                    return _BeneficiaryTile(
                      beneficiary: beneficiary,
                      usageCount: usages[beneficiary.id] ?? 0,
                      onEdit: () => _showRenameDialog(beneficiary),
                      onDelete: () => _confirmDelete(beneficiary),
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<Beneficiary> _matching(List<Beneficiary> beneficiaries) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return beneficiaries;
    return beneficiaries
        .where((b) => b.name.toLowerCase().contains(query))
        .toList();
  }

  void _showAddDialog() => _showNameDialog(
    title: 'Nouveau bénéficiaire',
    confirmLabel: 'Ajouter',
    initialName: '',
    onConfirm: (name) =>
        ref.read(beneficiaryProvider.notifier).addBeneficiary(name),
  );

  void _showRenameDialog(Beneficiary beneficiary) => _showNameDialog(
    title: 'Modifier le bénéficiaire',
    confirmLabel: 'Renommer',
    initialName: beneficiary.name,
    onConfirm: (name) => ref
        .read(beneficiaryProvider.notifier)
        .renameBeneficiary(beneficiary.id, name),
  );

  void _showNameDialog({
    required String title,
    required String confirmLabel,
    required String initialName,
    required Future<String?> Function(String name) onConfirm,
  }) {
    final nameController = TextEditingController(text: initialName);

    showFrostedDialog<void>(
      context: context,
      builder: (_) => FrostedDialog(
        title: title,
        body: FrostedTextField(
          controller: nameController,
          label: 'Nom',
          hintText: 'Ex: Paul',
        ),
        actions: [
          FrostedButton.tonal(
            label: 'Annuler',
            onPressed: () => Navigator.pop(context),
          ),
          FrostedButton.filled(
            label: confirmLabel,
            onPressed: () => _submitName(nameController.text, onConfirm),
          ),
        ],
      ),
    );
  }

  Future<void> _submitName(
    String name,
    Future<String?> Function(String name) onConfirm,
  ) async {
    final error = await onConfirm(name);
    if (!mounted) return;
    if (error != null) {
      FrostedSnackbar.show(context, message: error);
      return;
    }
    Navigator.pop(context);
  }

  void _confirmDelete(Beneficiary beneficiary) {
    final usageCount = ref
        .read(beneficiaryProvider.notifier)
        .countUsages(beneficiary.id);

    if (usageCount > 0) {
      showFrostedDialog<void>(
        context: context,
        builder: (_) => FrostedDialog(
          title: 'Suppression impossible',
          body: Text(
            '${_transactionCount(usageCount)} ${usageCount > 1 ? 'sont associées' : 'est associée'} à "${beneficiary.name}". Réassignez-les avant de supprimer ce bénéficiaire.',
          ),
          actions: [
            FrostedButton.filled(
              label: 'Compris',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    showFrostedDialog<void>(
      context: context,
      builder: (_) => FrostedDialog(
        title: 'Supprimer le bénéficiaire',
        body: Text('Voulez-vous vraiment supprimer "${beneficiary.name}" ?'),
        actions: [
          FrostedButton.tonal(
            label: 'Annuler',
            onPressed: () => Navigator.pop(context),
          ),
          FrostedButton.filled(
            label: 'Supprimer',
            onPressed: () => _delete(beneficiary.id),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(int id) async {
    Navigator.pop(context);
    final error = await ref
        .read(beneficiaryProvider.notifier)
        .deleteBeneficiary(id);
    if (error != null && mounted) {
      FrostedSnackbar.show(context, message: error);
    }
  }
}

String _transactionCount(int count) =>
    '$count transaction${count > 1 ? 's' : ''}';

class _BeneficiaryTile extends StatelessWidget {
  final Beneficiary beneficiary;
  final int usageCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BeneficiaryTile({
    required this.beneficiary,
    required this.usageCount,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return FrostedListTile(
      title: beneficiary.name,
      subtitle: usageCount == 0
          ? 'Aucune transaction'
          : _transactionCount(usageCount),
      leading: BeneficiaryAvatar(
        name: beneficiary.name,
        initials: beneficiary.initials,
        avatarColor: beneficiary.color,
      ),
      trailing: Tooltip(
        message: 'Supprimer',
        child: FrostedIconButton.standard(
          icon: Symbols.delete_rounded,
          size: FrostedIconButtonSize.small,
          onPressed: onDelete,
        ),
      ),
      variant: FrostedListTileVariant.plain,
      onTap: onEdit,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Text(
        'Aucun bénéficiaire',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
