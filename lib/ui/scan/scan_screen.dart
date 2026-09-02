import 'package:flutter/foundation.dart';

import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/exceptions/scan_exception.dart';
import 'package:mybudget/models/receipt_scan_result_model.dart';
import 'package:mybudget/models/scanned_item_model.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/common/widgets/category_picker_sheet.dart';
import 'package:mybudget/ui/common/widgets/date_selector.dart';
import 'package:mybudget/ui/scan/scan_provider.dart';
import 'package:mybudget/ui/scan/screens/scan_inspector_screen.dart';
import 'package:mybudget/ui/scan/widgets/scan_commit_bar.dart';
import 'package:mybudget/ui/scan/widgets/scan_item_list.dart';
import 'package:mybudget/ui/scan/widgets/scan_item_row.dart';
import 'package:mybudget/ui/scan/widgets/scan_photo_viewer.dart';
import 'package:mybudget/ui/scan/widgets/scan_reading_view.dart';
import 'package:mybudget/ui/scan/widgets/scan_review_view.dart';
import 'package:mybudget/ui/scan/widgets/scan_reveal.dart';
import 'package:mybudget/ui/scan/widgets/scan_saved_view.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';

class ScanScreen extends ConsumerStatefulWidget {
  static const String missingLineName = 'Ligne manquante';
  static const String removedMessage = 'Article retiré';
  static const String undoLabel = 'Annuler';

  final Future<Uint8List> image;

  const ScanScreen({required this.image, super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _revealController = AnimationController(
    vsync: this,
    duration: ScanReveal.duration,
  );
  late final Animation<double> _reveal = CurvedAnimation(
    parent: _revealController,
    curve: Curves.easeOutCubic,
  );
  final ScrollController _scroll = ScrollController();

  int? _selectedAccountId;
  bool _revealed = false;
  int? _highlightedIndex;
  List<int>? _createdIds;
  Uint8List? _imageBytes;
  Object? _imageError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(scanProvider, (_, next) {
        if (next is AsyncData && next.value != null) _onResultReady();
      });
      _readThenScan();
    });
  }

  Future<void> _readThenScan() async {
    try {
      final bytes = await widget.image;
      if (!mounted) return;
      _imageBytes = bytes;
      await ref.read(scanProvider.notifier).scanReceipt(bytes);
    } catch (error, stackTrace) {
      debugPrint('[scan] photo illisible : $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _imageError = const ScanUnreadableException());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _revealController.dispose();
    super.dispose();
  }

  void _onResultReady() {
    _initSelectedAccount();
    if (_revealed) return;
    _revealed = true;

    Future<void>.delayed(ScanReveal.settle, () {
      if (mounted) _revealController.forward();
    });
  }

  void _initSelectedAccount() {
    if (_selectedAccountId != null) return;
    final accounts = ref.read(accountProvider).value ?? const [];
    if (accounts.isEmpty) return;
    setState(() => _selectedAccountId = accounts.first.id);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scanProvider);
    final result = state.value;
    final saved = _createdIds != null;
    final hasItems = result != null && result.items.isNotEmpty;

    return FrostedScaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopRow(
              loading: state is AsyncLoading,
              hideActions: saved,
              onShowPhoto: _imageBytes == null
                  ? null
                  : () => ScanPhotoViewer.show(context, _imageBytes!),
            ),
            Expanded(
              child: saved
                  ? _buildSaved(result!)
                  : _buildStage(context, state, result, hasItems),
            ),
            if (hasItems && !saved) _buildCommitBar(result),
          ],
        ),
      ),
    );
  }

  Widget _buildStage(
    BuildContext context,
    AsyncValue<ReceiptScanResultModel?> state,
    ReceiptScanResultModel? result,
    bool hasItems,
  ) {
    final failure = _imageError ?? (state is AsyncError ? state.error : null);
    if (failure != null) return _ErrorView(error: failure, onRetry: _retry);
    if (result == null) {
      return ScanReadingView(
        reveal: _reveal,
        progress: ref.watch(scanProgressProvider),
      );
    }
    if (!hasItems) return _EmptyView(onRetry: _retry);

    final resolver = ref.watch(categoryDisplayResolverProvider).value;

    return ScanReviewView(
      result: result,
      resolve: (slug) => slug == null ? null : resolver?.resolve(slug),
      reveal: _reveal,
      highlightedIndex: _highlightedIndex,
      controller: _scroll,
      onStoreChanged: ref.read(scanProvider.notifier).updateStoreName,
      onPickDate: () => _pickDate(result),
      onFillGap: () => _fillGap(result),
      onFocusPending: () => _focusPending(result),
      onPickCategory: (index) => _pickCategory(index, result),
      onNameChanged: ref.read(scanProvider.notifier).updateItemName,
      onAmountChanged: ref.read(scanProvider.notifier).updateItemAmount,
      onRemove: (index) => _removeItem(index, result),
    );
  }

  Widget _buildSaved(ReceiptScanResultModel result) {
    return ScanSavedView(
      result: result,
      resolve: (slug) => slug == null
          ? null
          : ref.watch(categoryDisplayResolverProvider).value?.resolve(slug),
      onDone: () => Navigator.pop(context),
      onDiscard: _discardCreated,
    );
  }

  Widget _buildCommitBar(ReceiptScanResultModel result) {
    return ScanCommitBar(
      pendingCount: result.pendingCount,
      total: result.itemsTotal,
      accounts: ref.watch(accountProvider).value ?? const [],
      selectedAccountId: _selectedAccountId,
      onSelectAccount: (id) => setState(() => _selectedAccountId = id),
      onFocusPending: () => _focusPending(result),
      onCommit: _validateAndCreate,
    );
  }

  void _retry() {
    _revealed = false;
    _revealController.value = 0;
    setState(() => _imageError = null);

    final bytes = _imageBytes;
    if (bytes == null) {
      _readThenScan();
      return;
    }
    ref.read(scanProvider.notifier).scanReceipt(bytes);
  }

  Future<void> _pickDate(ReceiptScanResultModel result) async {
    final picked = await DateSelector.showFullDatePicker(
      context: context,
      initialDate: result.date,
    );
    if (picked == null) return;
    ref.read(scanProvider.notifier).updateDate(picked);
  }

  Future<void> _pickCategory(
    int index,
    ReceiptScanResultModel result,
  ) async {
    if (index < 0 || index >= result.items.length) return;
    final item = result.items[index];

    final proposed = item.categorySlug;
    final slug = await CategoryPickerSheet.show(
      context,
      selectedSlug: proposed,
      suggestions: [?proposed],
    );
    if (slug == null) return;

    final label = ref
        .read(categoryDisplayResolverProvider)
        .value
        ?.resolve(slug)
        ?.label;
    if (label == null) return;

    ref.read(scanProvider.notifier).updateItemCategory(index, slug, label);
  }

  void _fillGap(ReceiptScanResultModel result) {
    final gap = result.gap;
    if (gap == null || !result.hasGap) return;

    ref
        .read(scanProvider.notifier)
        .addItem(
          ScannedItemModel(
            name: ScanScreen.missingLineName,
            amount: gap,
          ),
        );
    _focusIndex(result.items.length);
  }

  void _focusPending(ReceiptScanResultModel result) {
    final index = result.items.indexWhere((item) => item.needsAttention);
    if (index < 0) return;
    _focusIndex(index);
  }

  void _focusIndex(int index) {
    setState(() => _highlightedIndex = index);
    Future<void>.delayed(ScanItemRow.highlightFade, () {
      if (mounted) setState(() => _highlightedIndex = null);
    });

    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    final target = ScanItemList.offsetOf(index, position.viewportDimension);

    _scroll.animateTo(
      target.clamp(position.minScrollExtent, position.maxScrollExtent),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _removeItem(int index, ReceiptScanResultModel result) {
    if (index < 0 || index >= result.items.length) return;
    final removed = result.items[index];
    ref.read(scanProvider.notifier).removeItem(index);

    FrostedSnackbar.show(
      context,
      message: ScanScreen.removedMessage,
      actionLabel: ScanScreen.undoLabel,
      onAction: () =>
          ref.read(scanProvider.notifier).insertItem(index, removed),
    );
  }

  Future<void> _validateAndCreate() async {
    final accountId = _selectedAccountId;
    final bytes = _imageBytes;
    if (accountId == null || bytes == null) return;

    try {
      final created = await ref
          .read(scanProvider.notifier)
          .validateAndCreate(accountId, bytes);

      if (!mounted) return;
      setState(() => _createdIds = created);
    } catch (error, stackTrace) {
      debugPrint('[scan] création des dépenses impossible : $error\n$stackTrace');
      if (!mounted) return;
      FrostedSnackbar.show(
        context,
        message: 'Les dépenses n\'ont pas pu être enregistrées',
      );
    }
  }

  Future<void> _discardCreated() async {
    final ids = _createdIds;
    if (ids == null) return;

    setState(() => _createdIds = null);
    try {
      await ref.read(scanProvider.notifier).discardCreated(ids);
    } catch (error, stackTrace) {
      debugPrint('[scan] annulation impossible : $error\n$stackTrace');
      if (!mounted) return;
      FrostedSnackbar.show(
        context,
        message: 'L\'enregistrement n\'a pas pu être défait',
      );
    }
  }
}

class _TopRow extends StatelessWidget {
  static const String photoLabel = 'Photo';

  final bool loading;
  final bool hideActions;
  final VoidCallback? onShowPhoto;

  const _TopRow({
    required this.loading,
    this.hideActions = false,
    this.onShowPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FrostedSpacing.sp2),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Symbols.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Retour',
          ),
          const Spacer(),
          if (onShowPhoto != null && !hideActions)
            TextButton(onPressed: onShowPhoto, child: const Text(photoLabel)),
          if (kDebugMode && !loading && !hideActions)
            IconButton(
              icon: const Icon(Symbols.bug_report_rounded),
              tooltip: 'Inspecter le scan',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ScanInspectorScreen(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scanError = error;

    final (IconData icon, String title, String subtitle) = switch (scanError) {
      ScanUnreadableException() => (
        Symbols.no_photography_rounded,
        scanError.message,
        'Reprenez la photo bien à plat, ticket entier dans le cadre',
      ),
      ScanNoItemsException() => (
        Symbols.receipt_long_rounded,
        scanError.message,
        'Vérifiez que la partie articles du ticket est visible',
      ),
      ScanUnavailableException() => (
        Symbols.neurology_rounded,
        scanError.message,
        'Activez Gemini Nano ou renseignez une clé personnelle dans les réglages',
      ),
      ScanGenericException() => (
        Symbols.error_rounded,
        scanError.message,
        '',
      ),
      _ => (
        Symbols.error_rounded,
        'Une erreur est survenue',
        '$scanError',
      ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FrostedSpacing.sp6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: FrostedSpacing.sp4),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: FrostedSpacing.sp2),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: FrostedSpacing.sp5),
            FrostedButton.filled(label: 'Réessayer', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  static const String message = 'Aucun article lu sur ce ticket';

  final VoidCallback onRetry;

  const _EmptyView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FrostedSpacing.sp6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Symbols.receipt_long_rounded,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: FrostedSpacing.sp4),
            Text(message, style: theme.textTheme.titleMedium),
            const SizedBox(height: FrostedSpacing.sp5),
            FrostedButton.text(label: 'Réessayer', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
