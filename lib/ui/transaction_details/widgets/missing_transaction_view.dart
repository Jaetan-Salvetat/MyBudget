import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';

class MissingTransactionView extends StatelessWidget {
  const MissingTransactionView({
    required this.title,
    required this.message,
    super.key,
  });
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FrostedScaffold(
      appBar: FrostedTopBar(
        title: title,
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: Center(
        child: Text(
          message,
          style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
