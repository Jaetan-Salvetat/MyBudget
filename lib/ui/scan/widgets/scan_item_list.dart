import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/models/receipt_scan_result_model.dart';
import 'package:mybudget/ui/common/widgets/eyebrow.dart';
import 'package:mybudget/ui/scan/widgets/scan_item_row.dart';
import 'package:mybudget/ui/scan/widgets/scan_motion.dart';
import 'package:mybudget/ui/scan/widgets/scan_reveal.dart';

class ScanItemList extends StatelessWidget {
  static const String allConfirmedLabel = 'tous confirmés';
  static const String swipeHint =
      'Glisser une ligne vers la gauche pour la retirer';
  static const double headerHeight = 42;

  static String pendingLabelOf(int count) => '$count à confirmer';

  static String countLabelOf(int count) =>
      count > 1 ? '$count articles · ordre du ticket' : '$count article';

  static double offsetOf(int index, double viewportHeight) {
    final target =
        headerHeight +
        index * ScanItemRow.extent -
        (viewportHeight - ScanItemRow.extent) / 2;
    return target < 0 ? 0 : target;
  }

  final ReceiptScanResultModel result;
  final CategoryDisplay? Function(String? slug) resolve;
  final Animation<double> reveal;
  final int? highlightedIndex;
  final ScrollController? controller;
  final VoidCallback onFocusPending;
  final void Function(int index) onPickCategory;
  final void Function(int index, String name) onNameChanged;
  final void Function(int index, double amount) onAmountChanged;
  final void Function(int index) onRemove;
  final Widget trailing;

  const ScanItemList({
    required this.result,
    required this.resolve,
    required this.reveal,
    this.highlightedIndex,
    required this.onFocusPending,
    required this.onPickCategory,
    required this.onNameChanged,
    required this.onAmountChanged,
    required this.onRemove,
    required this.trailing,
    this.controller,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _HeaderDelegate(
            pending: result.pendingCount,
            count: result.items.length,
            reveal: reveal,
            onFocusPending: onFocusPending,
          ),
        ),
        SliverFixedExtentList(
          itemExtent: ScanItemRow.extent,
          delegate: SliverChildBuilderDelegate(childCount: result.items.length, (
            context,
            index,
          ) {
            final item = result.items[index];
            return _CascadeIn(
              reveal: reveal,
              index: index,
              child: Dismissible(
                key: ValueKey('${item.name}-$index'),
                direction: DismissDirection.endToStart,
                background: const _RemoveBackground(),
                onDismissed: (_) => onRemove(index),
                child: ScanItemRow(
                  item: item,
                  category: resolve(item.categorySlug),
                  highlighted: index == highlightedIndex,
                  onPickCategory: () => onPickCategory(index),
                  onNameChanged: (name) => onNameChanged(index, name),
                  onAmountChanged: (amount) => onAmountChanged(index, amount),
                ),
              ),
            );
          }),
        ),
        SliverToBoxAdapter(
          child: _ListPhase(
            reveal: reveal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    FrostedSpacing.sp5,
                    FrostedSpacing.sp3,
                    FrostedSpacing.sp5,
                    0,
                  ),
                  child: Text(
                    swipeHint,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CascadeIn extends StatelessWidget {
  final Animation<double> reveal;
  final int index;
  final Widget child;

  const _CascadeIn({
    required this.reveal,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: reveal,
      child: child,
      builder: (context, settled) {
        final entrance = ScanReveal.rowProgressOf(reveal.value, index);
        return Opacity(
          opacity: entrance,
          child: Transform.translate(
            offset: Offset(
              0,
              (1 - entrance) * ScanItemRow.extent * ScanReveal.rowRise,
            ),
            child: settled,
          ),
        );
      },
    );
  }
}

class _ListPhase extends StatelessWidget {
  final Animation<double> reveal;
  final Widget child;

  const _ListPhase({required this.reveal, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: reveal,
      child: child,
      builder: (context, settled) => Opacity(
        opacity: ScanReveal.listProgressOf(reveal.value),
        child: settled,
      ),
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final int pending;
  final int count;
  final Animation<double> reveal;
  final VoidCallback onFocusPending;

  const _HeaderDelegate({
    required this.pending,
    required this.count,
    required this.reveal,
    required this.onFocusPending,
  });

  @override
  double get minExtent => ScanItemList.headerHeight;

  @override
  double get maxExtent => ScanItemList.headerHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);

    return _ListPhase(
      reveal: reveal,
      child: Container(
        height: ScanItemList.headerHeight,
        color: theme.colorScheme.surface,
        padding: const EdgeInsets.fromLTRB(
          FrostedSpacing.sp5,
          FrostedSpacing.sp2,
          FrostedSpacing.sp4,
          FrostedSpacing.sp2,
        ),
        child: Row(
          children: [
            Eyebrow(ScanItemList.countLabelOf(count)),
            const Spacer(),
            ScanSwap(
              child: pending > 0
                  ? InkWell(
                      key: ValueKey(pending),
                      onTap: onFocusPending,
                      borderRadius: BorderRadius.circular(FrostedRadius.xs),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: FrostedSpacing.sp2,
                          vertical: 2,
                        ),
                        child: Text(
                          ScanItemList.pendingLabelOf(pending),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  : Padding(
                      key: const ValueKey('done'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: FrostedSpacing.sp2,
                      ),
                      child: Text(
                        ScanItemList.allConfirmedLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_HeaderDelegate oldDelegate) =>
      pending != oldDelegate.pending ||
      count != oldDelegate.count ||
      reveal != oldDelegate.reveal;
}

class _RemoveBackground extends StatelessWidget {
  const _RemoveBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: FrostedSpacing.sp5),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Icon(
        Icons.delete_outline_rounded,
        size: 20,
        color: Theme.of(context).colorScheme.onErrorContainer,
      ),
    );
  }
}
