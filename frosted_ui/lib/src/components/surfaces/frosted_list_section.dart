import 'package:material_ui/material_ui.dart';

import '../../foundations/frosted_spacing.dart';
import '../../foundations/frosted_type_scale.dart';
import 'frosted_list_tile.dart';

class FrostedListSection extends StatelessWidget {
  const FrostedListSection({required this.tiles, this.label, super.key});

  final List<FrostedListTile> tiles;
  final String? label;

  static const double _gap = FrostedSpacing.sp05;

  FrostedTilePosition _positionFor(int index) {
    final bool isFirst = index == 0;
    final bool isLast = index == tiles.length - 1;
    if (isFirst && isLast) return FrostedTilePosition.single;
    if (isFirst) return FrostedTilePosition.first;
    if (isLast) return FrostedTilePosition.last;
    return FrostedTilePosition.middle;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (label != null) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: FrostedSpacing.sp3),
            child: Text(
              label!,
              style: FrostedTypeScale.titleSmall.copyWith(color: cs.onSurface),
            ),
          ),
        ],
        for (int i = 0; i < tiles.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: _gap),
          tiles[i].withPosition(_positionFor(i)),
        ],
      ],
    );
  }
}
