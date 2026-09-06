import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';

class MissingTransactionView extends StatelessWidget {
  final String title;
  final String message;

  const MissingTransactionView({
    required this.title,
    required this.message,
    super.key,
  });

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
