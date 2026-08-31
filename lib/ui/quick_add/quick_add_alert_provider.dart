import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quick_add_alert_provider.g.dart';

class QuickAddAlert {
  QuickAddAlert(this.message);

  final String message;
}

@Riverpod(keepAlive: true)
class QuickAddAlertNotifier extends _$QuickAddAlertNotifier {
  @override
  QuickAddAlert? build() => null;

  void report(String message) => state = QuickAddAlert(message);
}
