import 'package:material_ui/material_ui.dart';
import 'package:mybudget/models/scan_read_progress_model.dart';
import 'package:mybudget/ui/scan/widgets/scan_reading_thread.dart';
import 'package:mybudget/ui/scan/widgets/scan_receipt_header.dart';
import 'package:mybudget/ui/scan/widgets/scan_reveal.dart';

class ScanReadingView extends StatelessWidget {
  final Animation<double> reveal;
  final ScanReadProgress progress;

  const ScanReadingView({
    required this.reveal,
    this.progress = const ScanReadProgress(),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Padding(
        padding: EdgeInsets.only(
          top: ScanReveal.headerOffsetOf(constraints.maxHeight, reveal.value),
        ),
        child: Column(
          children: [
            ScanReceiptHeader(
              result: null,
              progress: progress,
              reveal: reveal,
              onStoreChanged: (_) {},
              onPickDate: () {},
              onFillGap: () {},
            ),
            const Spacer(),
            const ScanReadingThread(),
          ],
        ),
      ),
    );
  }
}
