import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

enum RealisticSurfaceKind { feed, photos, reader }

class RealisticSurface extends StatelessWidget {
  const RealisticSurface({required this.kind, super.key});

  final RealisticSurfaceKind kind;

  @override
  Widget build(BuildContext context) {
    switch (kind) {
      case RealisticSurfaceKind.feed:
        return const _FeedSurface();
      case RealisticSurfaceKind.photos:
        return const _PhotosSurface();
      case RealisticSurfaceKind.reader:
        return const _ReaderSurface();
    }
  }
}

class _FeedSurface extends StatelessWidget {
  const _FeedSurface();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<_FeedItem> items = _FeedItem.sample(cs);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        FrostedSpacing.sp4,
        FrostedSpacing.sp8,
        FrostedSpacing.sp4,
        260,
      ),
      itemCount: items.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: FrostedSpacing.sp4),
      itemBuilder: (BuildContext context, int index) {
        final _FeedItem item = items[index];
        return Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(FrostedRadius.lg),
          ),
          padding: const EdgeInsets.all(FrostedSpacing.sp4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(FrostedRadius.md),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: item.swatch,
                  ),
                ),
              ),
              const SizedBox(width: FrostedSpacing.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.tag.toUpperCase(),
                      style: FrostedTypeScale.labelSmall
                          .copyWith(color: cs.primary),
                    ),
                    const SizedBox(height: FrostedSpacing.sp1),
                    Text(
                      item.title,
                      style: FrostedTypeScale.titleSmall
                          .copyWith(color: cs.onSurface),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: FrostedSpacing.sp1),
                    Text(
                      item.subtitle,
                      style: FrostedTypeScale.bodySmall
                          .copyWith(color: cs.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FeedItem {
  const _FeedItem({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.swatch,
  });

  final String tag;
  final String title;
  final String subtitle;
  final List<Color> swatch;

  static List<_FeedItem> sample(ColorScheme cs) {
    return <_FeedItem>[
      _FeedItem(
        tag: 'Design',
        title: 'The case for opinionated systems',
        subtitle:
            'Why constraint-driven design produces better products than infinite flexibility.',
        swatch: <Color>[cs.primary, cs.tertiary],
      ),
      _FeedItem(
        tag: 'Engineering',
        title: 'Liquid Glass in production',
        subtitle:
            'Notes on shipping translucent chrome without tanking battery life.',
        swatch: <Color>[cs.secondary, cs.primaryContainer],
      ),
      _FeedItem(
        tag: 'Culture',
        title: 'On taste, in tools and otherwise',
        subtitle:
            'Software inherits the values of the people who build it. Mostly that\'s a problem.',
        swatch: <Color>[cs.tertiary, cs.secondary],
      ),
      _FeedItem(
        tag: 'Photography',
        title: 'A field guide to natural light',
        subtitle:
            'Mornings, magic hour, and the rare grace of overcast skies.',
        swatch: const <Color>[Color(0xFFFFB347), Color(0xFFFFD166)],
      ),
      _FeedItem(
        tag: 'Travel',
        title: 'Slow lanes through the Pyrenees',
        subtitle: 'Two weeks, a manual transmission, and no fixed itinerary.',
        swatch: const <Color>[Color(0xFF06D6A0), Color(0xFF118AB2)],
      ),
      _FeedItem(
        tag: 'Reading',
        title: 'Five short novels for a long flight',
        subtitle: 'Each fits in a coat pocket. None outstays its welcome.',
        swatch: const <Color>[Color(0xFFE5527A), Color(0xFF8338EC)],
      ),
      _FeedItem(
        tag: 'Music',
        title: 'Jazz for headphones',
        subtitle:
            'Records that fall apart on speakers and bloom on a good set of cans.',
        swatch: <Color>[cs.primary, cs.secondary],
      ),
      _FeedItem(
        tag: 'Finance',
        title: 'The boring index fund',
        subtitle:
            'A decade of underperforming on purpose, and why it still works.',
        swatch: <Color>[cs.tertiary, cs.primary],
      ),
    ];
  }
}

class _PhotosSurface extends StatelessWidget {
  const _PhotosSurface();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<List<Color>> swatches = <List<Color>>[
      <Color>[const Color(0xFFFF4D6D), const Color(0xFFFFB347)],
      <Color>[cs.primary, cs.tertiary],
      <Color>[const Color(0xFF06D6A0), const Color(0xFF118AB2)],
      <Color>[const Color(0xFF8338EC), const Color(0xFF3A86FF)],
      <Color>[const Color(0xFFFFD166), const Color(0xFFE5527A)],
      <Color>[cs.secondary, cs.tertiary],
      <Color>[const Color(0xFF1B998B), const Color(0xFF2E294E)],
      <Color>[const Color(0xFFE71D36), const Color(0xFFFF9F1C)],
      <Color>[const Color(0xFF011627), const Color(0xFF2EC4B6)],
    ];
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        FrostedSpacing.sp2,
        FrostedSpacing.sp8,
        FrostedSpacing.sp2,
        260,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: FrostedSpacing.sp1,
        mainAxisSpacing: FrostedSpacing.sp1,
        childAspectRatio: 0.85,
      ),
      itemCount: 16,
      itemBuilder: (BuildContext context, int index) {
        final List<Color> swatch = swatches[index % swatches.length];
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: swatch,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(FrostedRadius.sm),
          ),
        );
      },
    );
  }
}

class _ReaderSurface extends StatelessWidget {
  const _ReaderSurface();

  static const String _lorem =
      'Glass Expressive treats chrome as a separate material from content. '
      'Where the eye reads, the surface is opaque and confident. Where the '
      'system speaks, the surface is translucent and quiet. The two never '
      'swap roles.\n\n'
      'In practice this means a tab bar is glass, a list is not. A modal '
      'shell is glass, the form inside it is not. A toolbar is glass, the '
      'document under it is not. The distinction is the entire point.\n\n'
      'Restraint is the trick. Most attempts at glass over-do specular '
      'highlights, tint, and color washes; they end up looking like a 2010 '
      'widget skin. A real material is mostly transparent, mostly quiet, '
      'and only catches the eye at the very edge.';

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        FrostedSpacing.sp5,
        FrostedSpacing.sp8,
        FrostedSpacing.sp5,
        280,
      ),
      children: <Widget>[
        Text(
          'On materials',
          style: FrostedTypeScale.displaySmall.copyWith(color: cs.onSurface),
        ),
        const SizedBox(height: FrostedSpacing.sp3),
        Text(
          'A short essay on the layer rule',
          style: FrostedTypeScale.titleSmall
              .copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: FrostedSpacing.sp5),
        Text(
          _lorem,
          style: FrostedTypeScale.bodyLarge.copyWith(color: cs.onSurface),
        ),
        const SizedBox(height: FrostedSpacing.sp5),
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(FrostedRadius.lg),
            gradient: LinearGradient(
              colors: <Color>[cs.primary, cs.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        const SizedBox(height: FrostedSpacing.sp5),
        Text(
          _lorem,
          style: FrostedTypeScale.bodyLarge.copyWith(color: cs.onSurface),
        ),
      ],
    );
  }
}
