import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:permission_handler/permission_handler.dart';

class OnboardingUpdateSlide extends StatefulWidget {
  final bool initialEnabled;
  final int initialInterval;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<int> onIntervalChanged;

  const OnboardingUpdateSlide({
    super.key,
    this.initialEnabled = true,
    this.initialInterval = 24,
    required this.onEnabledChanged,
    required this.onIntervalChanged,
  });

  @override
  State<OnboardingUpdateSlide> createState() => _OnboardingUpdateSlideState();
}

class _OnboardingUpdateSlideState extends State<OnboardingUpdateSlide> {
  late bool _enabled;
  late int _interval;

  static const Map<int, String> _intervalOptions = {
    12: '12 heures',
    24: '24 heures',
    48: '48 heures',
    168: 'Hebdomadaire',
  };

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialEnabled;
    _interval = widget.initialInterval;
  }

  Future<void> _onToggleChanged(bool value) async {
    if (value) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        setState(() => _enabled = true);
        widget.onEnabledChanged(true);
      } else {
        setState(() => _enabled = false);
        widget.onEnabledChanged(false);
        if (mounted) {
          FrostedSnackbar.show(
            context,
            message: 'La permission de notification est requise pour les vérifications automatiques.',
          );
        }
      }
    } else {
      setState(() => _enabled = false);
      widget.onEnabledChanged(false);
    }
  }

  void _onIntervalChanged(int? value) {
    if (value == null) return;
    setState(() => _interval = value);
    widget.onIntervalChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FrostedCard(
            padding: const EdgeInsets.all(40),
            borderRadius: 40,
            child: Icon(
              CupertinoIcons.bell,
              size: 80,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            'Toujours à jour.',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Recevez une notification dès qu\'une nouvelle version est disponible.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FrostedCard(
            borderRadius: 16,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Vérification auto',
                        style: theme.textTheme.bodyLarge,
                      ),
                      Switch.adaptive(
                        value: _enabled,
                        onChanged: _onToggleChanged,
                      ),
                    ],
                  ),
                  if (_enabled) ...[
                    const FrostedDivider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Fréquence',
                          style: theme.textTheme.bodyLarge,
                        ),
                        DropdownButton<int>(
                          value: _interval,
                          underline: const SizedBox.shrink(),
                          items: _intervalOptions.entries
                              .map((e) => DropdownMenuItem<int>(
                                    value: e.key,
                                    child: Text(e.value),
                                  ))
                              .toList(),
                          onChanged: _onIntervalChanged,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
