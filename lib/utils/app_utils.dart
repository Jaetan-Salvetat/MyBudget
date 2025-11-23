import 'package:flutter/material.dart';
import 'package:mybudget/utils/restart_widget.dart';

class AppUtils {
  /// Redémarre l'application en utilisant le RestartWidget (Phoenix pattern)
  static void restartApp(BuildContext context) {
    RestartWidget.restartApp(context);
  }
}
