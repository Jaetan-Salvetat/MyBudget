import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

import 'app_shell.dart';
import 'theme_controller.dart';

void main() {
  runApp(const FrostedExampleApp());
}

class FrostedExampleApp extends StatefulWidget {
  const FrostedExampleApp({super.key});

  @override
  State<FrostedExampleApp> createState() => _FrostedExampleAppState();
}

class _FrostedExampleAppState extends State<FrostedExampleApp> {
  final ThemeController _controller = ThemeController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (BuildContext context, _) {
        return MaterialApp(
          title: 'Frosted UI',
          themeMode: _controller.mode,
          theme: FrostedTheme.light(seedColor: _controller.seedColor),
          darkTheme: FrostedTheme.dark(seedColor: _controller.seedColor),
          debugShowCheckedModeBanner: false,
          home: AppShell(controller: _controller),
        );
      },
    );
  }
}
