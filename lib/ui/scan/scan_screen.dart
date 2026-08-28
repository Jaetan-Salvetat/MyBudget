import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';
import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/exceptions/scan_exception.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/models/receipt_scan_result_model.dart';
import 'package:mybudget/models/scanned_item_model.dart';
import 'package:mybudget/ui/accounts/accounts_provider.dart';
import 'package:mybudget/ui/common/widgets/frosted_container.dart';
import 'package:mybudget/ui/scan/scan_provider.dart';
import 'package:mybudget/ui/scan/screens/scan_inspector_screen.dart';
import 'package:mybudget/ui/scan/widgets/scanned_item_edit_bottom_sheet.dart';
import 'package:mybudget/ui/settings/category_override_provider.dart';

class ScanScreen extends ConsumerStatefulWidget {
  final Uint8List imageBytes;

  const ScanScreen({required this.imageBytes, super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with TickerProviderStateMixin {
  int? _selectedAccountId;
  late final AnimationController _scanLineController;
  late final AnimationController _pulseController;
  int _statusMessageIndex = 0;
  Timer? _statusTimer;

  static const _statusMessages = [
    'Analyse du ticket en cours...',
    'Identification des articles...',
    'Catégorisation en cours...',
    'Presque terminé...',
  ];

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(scanProvider, (_, next) {
        if (next is AsyncData && next.value != null) {
          _initSelectedAccount();
        }
      });
      ref.read(scanProvider.notifier).scanReceipt(widget.imageBytes);
      _startStatusRotation();
    });
  }

  void _startStatusRotation() {
    _statusTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_statusMessageIndex < _statusMessages.length - 1) {
        setState(() => _statusMessageIndex++);
      }
    });
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _pulseController.dispose();
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);
    final isLoading = scanState is AsyncLoading;
    final hasError = scanState is AsyncError;
    final result = scanState.value;
    final hasData = result != null && result.items.isNotEmpty;

    return FrostedScaffold(
      appBar: FrostedTopBar(
        title: 'Scanner un ticket',
        // Le détail de chaque étage du flow n'a d'intérêt que pour qui
        // développe le scan, et il montre des données brutes : il ne sort pas
        // des builds de debug.
        actions: [
          if (kDebugMode && !isLoading)
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
      bottomNavigationBar: hasData ? _buildBottomBar(context, result) : null,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: isLoading
            ? _buildLoadingView(context)
            : hasError
            ? _buildErrorView(context, scanState as AsyncError)
            : hasData
            ? _buildValidationView(context, result)
            : _buildEmptyView(context),
      ),
    );
  }

  Widget _buildLoadingView(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      key: const ValueKey('loading'),
      padding: const EdgeInsets.only(top: 120, left: 16, right: 16, bottom: 32),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Image.memory(
                widget.imageBytes,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _scanLineController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _ScanLinePainter(
                        progress: _scanLineController.value,
                        color: theme.colorScheme.primary,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FrostedLinearProgress(),
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _statusMessages[_statusMessageIndex],
            key: ValueKey(_statusMessageIndex),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(height: 32),
        ...List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final opacity = 0.3 + (_pulseController.value * 0.3);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: opacity,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildErrorView(BuildContext context, AsyncError error) {
    final theme = Theme.of(context);
    final scanError = error.error;

    final IconData icon;
    final String title;
    final String subtitle;

    switch (scanError) {
      case ScanUnreadableException():
        icon = Symbols.no_photography_rounded;
        title = scanError.message;
        subtitle = 'Reprenez la photo bien à plat, ticket entier dans le cadre';
      case ScanNoItemsException():
        icon = Symbols.receipt_long_rounded;
        title = scanError.message;
        subtitle = 'Vérifiez que la partie articles du ticket est visible';
      case ScanGenericException():
        icon = Symbols.error_rounded;
        title = scanError.message;
        subtitle = '';
      default:
        icon = Symbols.error_rounded;
        title = 'Une erreur est survenue';
        subtitle = '$scanError';
    }

    return Center(
      key: const ValueKey('error'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FrostedButton.filled(label: 'Réessayer', onPressed: _retry),
          ],
        ),
      ),
    );
  }

  void _initSelectedAccount() {
    if (_selectedAccountId != null) return;
    final accounts = ref.read(accountProvider).value ?? [];
    if (accounts.length == 1) {
      setState(() => _selectedAccountId = accounts.first.id);
    }
  }

  void _retry() {
    setState(() => _statusMessageIndex = 0);
    _statusTimer?.cancel();
    _startStatusRotation();
    ref.read(scanProvider.notifier).scanReceipt(widget.imageBytes);
  }

  Widget _buildEmptyView(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      key: const ValueKey('empty'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Symbols.receipt_long_rounded,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text('Aucun article détecté', style: theme.textTheme.titleMedium),
            const SizedBox(height: 24),
            FrostedButton.text(
              label: 'Retour',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationView(
    BuildContext context,
    ReceiptScanResultModel result,
  ) {
    final resolver = ref.watch(categoryDisplayResolverProvider).value;
    final categories = resolver == null
        ? const <CategoryDisplay>[]
        : resolver
              .groupsOfType(TransactionType.expense)
              .expand((group) => resolver.childrenOf(group.slug))
              .toList();
    final accounts = ref.watch(accountProvider).value ?? [];
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('d MMMM yyyy', 'fr_FR');

    final grouped = _groupItemsByCategory(result.items, categories);
    final uncategorized = result.items
        .where((i) => i.categorySlug == null)
        .toList();

    return ListView(
      key: const ValueKey('validation'),
      padding: const EdgeInsets.only(
        top: 120,
        left: 16,
        right: 16,
        bottom: 145,
      ),
      children: [
        _buildHeaderCard(context, result, dateFormat),
        if (!result.verified) ...[
          const SizedBox(height: 16),
          _buildUnverifiedBanner(context),
        ],
        const SizedBox(height: 16),
        if (accounts.isNotEmpty)
          FrostedDropdown<int>(
            value: _selectedAccountId,
            items: accounts.map((account) {
              return FrostedDropdownItem<int>(
                value: account.id,
                label: account.name,
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedAccountId = value);
            },
            hintText: 'Compte',
          ),
        const SizedBox(height: 16),
        ...grouped.entries.map((entry) {
          return _buildCategoryCard(
            context,
            entry.key,
            entry.value,
            formatter,
            categories,
          );
        }),
        if (uncategorized.isNotEmpty)
          _buildUncategorizedCard(
            context,
            uncategorized,
            formatter,
            categories,
          ),
      ],
    );
  }

  /// La somme des articles n'est retombée sur aucun montant imprimé : la
  /// lecture est partielle. On le dit franchement plutôt que de laisser
  /// valider un ticket incomplet en croyant qu'il est juste.
  Widget _buildUnverifiedBanner(BuildContext context) {
    final theme = Theme.of(context);

    return FrostedCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Symbols.rule_rounded,
              color: theme.colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Le total du ticket ne correspond pas aux articles lus : '
                'vérifiez les montants avant de valider.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    ReceiptScanResultModel result,
    DateFormat dateFormat,
  ) {
    final theme = Theme.of(context);
    final date = result.date ?? DateTime.now();

    return FrostedCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                widget.imageBytes,
                height: 60,
                width: 60,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (result.storeName != null)
                    Text(
                      result.storeName!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _pickDate(context, date),
                    child: Row(
                      children: [
                        Icon(
                          Symbols.calendar_today_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateFormat.format(date),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Symbols.edit_rounded,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    CategoryDisplay category,
    List<_IndexedItem> items,
    NumberFormat formatter,
    List<CategoryDisplay> categories,
  ) {
    final theme = Theme.of(context);
    final total = items.fold(0.0, (sum, i) => sum + i.item.effectiveAmount);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FrostedCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    CategoryDefaults.resolveIcon(category.icon),
                    color: Color(category.color),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      category.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    formatter.format(total),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...items.map((indexedItem) {
                return _buildItemRow(
                  context,
                  indexedItem,
                  formatter,
                  categories,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUncategorizedCard(
    BuildContext context,
    List<ScannedItemModel> items,
    NumberFormat formatter,
    List<CategoryDisplay> categories,
  ) {
    final theme = Theme.of(context);
    final total = items.fold(0.0, (sum, i) => sum + i.effectiveAmount);
    final result = ref.read(scanProvider).value;
    if (result == null) return const SizedBox.shrink();

    final indexedItems = items.map((item) {
      return _IndexedItem(index: result.items.indexOf(item), item: item);
    }).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FrostedCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Symbols.warning_amber_rounded,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Non catégorisé',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                  Text(
                    formatter.format(total),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...indexedItems.map((indexedItem) {
                return _buildItemRow(
                  context,
                  indexedItem,
                  formatter,
                  categories,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemRow(
    BuildContext context,
    _IndexedItem indexedItem,
    NumberFormat formatter,
    List<CategoryDisplay> categories,
  ) {
    final theme = Theme.of(context);

    final item = indexedItem.item;

    return InkWell(
      onTap: () => _openEditSheet(context, indexedItem.index, item, categories),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Text(
              '·',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(item.name, style: theme.textTheme.bodyMedium)),
            if (item.hasDiscount)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  '-${formatter.format(item.discount)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            Text(
              formatter.format(item.effectiveAmount),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Symbols.edit_rounded,
              size: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, ReceiptScanResultModel result) {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    );
    final total = result.items.fold(0.0, (sum, i) => sum + i.effectiveAmount);
    final hasUncategorized = result.items.any((i) => i.categorySlug == null);
    final categoryCount = _countCategories(result.items);

    return FrostedContainer(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  formatter.format(total),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FrostedButton.filled(
                label:
                    'Valider $categoryCount dépense${categoryCount > 1 ? 's' : ''}',
                onPressed: hasUncategorized || _selectedAccountId == null
                    ? null
                    : () => _validateAndCreate(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<CategoryDisplay, List<_IndexedItem>> _groupItemsByCategory(
    List<ScannedItemModel> items,
    List<CategoryDisplay> categories,
  ) {
    final Map<String, List<_IndexedItem>> grouped = {};
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.categorySlug != null) {
        grouped
            .putIfAbsent(item.categorySlug!, () => [])
            .add(_IndexedItem(index: i, item: item));
      }
    }

    final Map<CategoryDisplay, List<_IndexedItem>> result = {};
    for (final entry in grouped.entries) {
      final category = categories.firstWhere(
        (c) => c.slug == entry.key,
        orElse: () => categories.first,
      );
      result[category] = entry.value;
    }
    return result;
  }

  int _countCategories(List<ScannedItemModel> items) {
    return items
        .where((i) => i.categorySlug != null)
        .map((i) => i.categorySlug)
        .toSet()
        .length;
  }

  void _openEditSheet(
    BuildContext context,
    int index,
    ScannedItemModel item,
    List<CategoryDisplay> categories,
  ) {
    ScannedItemEditBottomSheet.show(
      context: context,
      item: item,
      categories: categories,
      onCategoryChanged: (categorySlug, categoryName) {
        ref
            .read(scanProvider.notifier)
            .updateItemCategory(index, categorySlug, categoryName);
      },
      onAmountChanged: (amount) {
        ref.read(scanProvider.notifier).updateItemAmount(index, amount);
      },
      onDiscountChanged: (discount) {
        ref.read(scanProvider.notifier).updateItemDiscount(index, discount);
      },
      onDelete: () {
        ref.read(scanProvider.notifier).removeItem(index);
      },
    );
  }

  Future<void> _pickDate(BuildContext context, DateTime currentDate) async {
    final picked = await showFrostedDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ref.read(scanProvider.notifier).updateDate(picked);
    }
  }

  Future<void> _validateAndCreate(BuildContext context) async {
    if (_selectedAccountId == null) return;

    try {
      final count = await ref
          .read(scanProvider.notifier)
          .validateAndCreate(_selectedAccountId!, widget.imageBytes);

      if (context.mounted) {
        FrostedSnackbar.show(
          context,
          message:
              '$count dépense${count > 1 ? 's' : ''} ajoutée${count > 1 ? 's' : ''}',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        FrostedSnackbar.show(
          context,
          message: 'Erreur lors de la création : $e',
        );
      }
    }
  }
}

class _IndexedItem {
  final int index;
  final ScannedItemModel item;

  const _IndexedItem({required this.index, required this.item});
}

class _ScanLinePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ScanLinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.6),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, y - 2, size.width, 4));

    canvas.drawRect(Rect.fromLTWH(0, y - 2, size.width, 4), paint);
  }

  @override
  bool shouldRepaint(_ScanLinePainter oldDelegate) =>
      progress != oldDelegate.progress;
}
