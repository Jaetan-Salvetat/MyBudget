import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/services/category_display_resolver.dart';
import 'package:mybudget/models/receipt_scan_result_model.dart';
import 'package:mybudget/ui/scan/widgets/scan_item_list.dart';
import 'package:mybudget/ui/scan/widgets/scan_output_summary.dart';
import 'package:mybudget/ui/scan/widgets/scan_receipt_header.dart';
import 'package:mybudget/ui/scan/widgets/scan_reveal.dart';

class ScanReviewView extends StatelessWidget {
  const ScanReviewView({
    required this.result,
    required this.resolve,
    required this.reveal,
    required this.now,
    this.highlightedIndex,
    required this.onStoreChanged,
    required this.onPickDate,
    required this.onFillGap,
    required this.onFocusPending,
    required this.onPickCategory,
    required this.onNameChanged,
    required this.onAmountChanged,
    required this.onRemove,
    this.controller,
    super.key,
  });
  final ReceiptScanResultModel result;
  final CategoryDisplay? Function(String? slug) resolve;
  final Animation<double> reveal;
  final DateTime now;
  final int? highlightedIndex;
  final ScrollController? controller;
  final ValueChanged<String> onStoreChanged;
  final VoidCallback onPickDate;
  final VoidCallback onFillGap;
  final VoidCallback onFocusPending;
  final void Function(int index) onPickCategory;
  final void Function(int index, String name) onNameChanged;
  final void Function(int index, double amount) onAmountChanged;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => AnimatedBuilder(
        animation: reveal,
        builder: (context, child) => Padding(
          padding: EdgeInsets.only(
            top: ScanReveal.headerOffsetOf(constraints.maxHeight, reveal.value),
          ),
          child: child,
        ),
        child: _content(context),
      ),
    );
  }

  Widget _content(BuildContext context) {
    return Column(
      children: [
        ScanReceiptHeader(
          result: result,
          now: now,
          reveal: reveal,
          onStoreChanged: onStoreChanged,
          onPickDate: onPickDate,
          onFillGap: onFillGap,
        ),
        Expanded(
          child: ScanItemList(
            result: result,
            resolve: resolve,
            reveal: reveal,
            highlightedIndex: highlightedIndex,
            controller: controller,
            onFocusPending: onFocusPending,
            onPickCategory: onPickCategory,
            onNameChanged: onNameChanged,
            onAmountChanged: onAmountChanged,
            onRemove: onRemove,
            trailing: ScanOutputSummary(result: result, resolve: resolve),
          ),
        ),
      ],
    );
  }
}
