import 'package:material_ui/material_ui.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../widgets/section.dart';

class OverlaysPage extends StatelessWidget {
  const OverlaysPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        FrostedSpacing.sp4,
        FrostedTopBar.bodyTopPadding(context) + FrostedSpacing.sp2,
        FrostedSpacing.sp4,
        FrostedSpacing.sp7,
      ),
      children: const <Widget>[
        Section(title: 'Dialog', child: _DialogDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Bottom sheet', child: _SheetDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Snackbar', child: _SnackbarDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Tooltip', child: _TooltipDemo()),
      ],
    );
  }
}

class _DialogDemo extends StatelessWidget {
  const _DialogDemo();

  @override
  Widget build(BuildContext context) {
    return FrostedButton.tonal(
      label: 'Ouvrir le dialog',
      onPressed: () => showFrostedDialog<void>(
        context: context,
        builder: (BuildContext context) => FrostedDialog(
          title: 'Supprimer cette dépense ?',
          body: const Text(
            'Cette action est irréversible. La dépense sera retirée '
            'définitivement.',
          ),
          actions: <Widget>[
            FrostedButton.text(
              label: 'Annuler',
              onPressed: () => Navigator.of(context).pop(),
            ),
            FrostedButton.filled(
              label: 'Supprimer',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetDemo extends StatelessWidget {
  const _SheetDemo();

  @override
  Widget build(BuildContext context) {
    return FrostedButton.tonal(
      label: 'Ouvrir la sheet',
      onPressed: () => showFrostedBottomSheet<void>(
        context: context,
        builder: (BuildContext context) => FrostedBottomSheet(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Trier par', style: FrostedTypeScale.titleMedium),
              const SizedBox(height: FrostedSpacing.sp3),
              FrostedListSection(
                tiles: <FrostedListTile>[
                  FrostedListTile(
                    leading: const Icon(Icons.schedule),
                    title: 'Plus récent',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  FrostedListTile(
                    leading: const Icon(Icons.euro),
                    title: 'Montant',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  FrostedListTile(
                    leading: const Icon(Icons.sort_by_alpha),
                    title: 'Alphabétique',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SnackbarDemo extends StatelessWidget {
  const _SnackbarDemo();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: FrostedSpacing.sp2,
      runSpacing: FrostedSpacing.sp2,
      children: <Widget>[
        FrostedButton.tonal(
          label: 'Simple',
          onPressed: () => FrostedSnackbar.show(
            context,
            message: 'Transaction ajoutée.',
          ),
        ),
        FrostedButton.tonal(
          label: 'Avec action',
          onPressed: () => FrostedSnackbar.show(
            context,
            message: 'Dépense supprimée.',
            actionLabel: 'Annuler',
            onAction: () {},
          ),
        ),
      ],
    );
  }
}

class _TooltipDemo extends StatelessWidget {
  const _TooltipDemo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        FrostedTooltip(
          message: 'Ajouter une dépense',
          child: FrostedIconButton.filled(
            icon: Icons.add,
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}
