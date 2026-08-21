import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

class TopBarLargeDemo extends StatelessWidget {
  const TopBarLargeDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(FrostedRadius.lg),
      child: SizedBox(
        height: 360,
        child: ColoredBox(
          color: cs.surfaceContainerHigh,
          child: CustomScrollView(
            slivers: <Widget>[
              FrostedSliverTopBar(
                title: 'Library',
                leading: _IconBtn(icon: Icons.menu, onTap: () {}),
                actions: <Widget>[
                  _IconBtn(icon: Icons.search, onTap: () {}),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(FrostedSpacing.sp3),
                sliver: SliverList.separated(
                  itemCount: 20,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: FrostedSpacing.sp2),
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius:
                            BorderRadius.circular(FrostedRadius.md),
                      ),
                      padding: const EdgeInsets.all(FrostedSpacing.sp4),
                      child: Text(
                        'Row ${index + 1}',
                        style: FrostedTypeScale.titleSmall
                            .copyWith(color: cs.onSurface),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(child: Icon(icon, color: cs.onSurface, size: 22)),
      ),
    );
  }
}
