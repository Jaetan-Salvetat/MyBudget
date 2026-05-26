import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

import 'pages/foundations_page.dart';
import 'pages/glass_page.dart';
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
          home: _HomePage(controller: _controller),
        );
      },
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    final List<_ComponentEntry> entries = <_ComponentEntry>[
      _ComponentEntry(
        title: 'Foundations',
        subtitle: 'Tokens, type scale, glass primitive',
        builder: (BuildContext _) => FoundationsPage(controller: controller),
      ),
      _ComponentEntry(
        title: 'Glass',
        subtitle: 'FrostedGlass — level, tone, elevation',
        builder: (BuildContext _) => const GlassPage(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Frosted UI')),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(
          vertical: FrostedSpacing.sp4,
        ),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(height: FrostedSpacing.sp1),
        itemBuilder: (BuildContext context, int index) {
          final _ComponentEntry entry = entries[index];
          return ListTile(
            title: Text(
              entry.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              entry.subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: entry.builder),
            ),
          );
        },
      ),
    );
  }
}

class _ComponentEntry {
  const _ComponentEntry({
    required this.title,
    required this.subtitle,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final WidgetBuilder builder;
}
