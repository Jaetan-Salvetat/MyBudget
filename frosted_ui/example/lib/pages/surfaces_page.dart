import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../widgets/section.dart';

class SurfacesPage extends StatelessWidget {
  const SurfacesPage({super.key});

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
        Section(title: 'Hero', child: _HeroDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Cards', child: _CardsDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'List', child: _ListDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Expansion', child: _ExpansionDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Carousel · hero', child: _CarouselDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Carousel · multi-browse', child: _MultiBrowseDemo()),
        SizedBox(height: FrostedSpacing.sp6),
        Section(title: 'Banner', child: _BannerDemo()),
      ],
    );
  }
}

class _HeroDemo extends StatelessWidget {
  const _HeroDemo();

  @override
  Widget build(BuildContext context) {
    return FrostedHeroCard(
      label: 'Ce mois-ci',
      title: '1 240 €',
      subtitle: 'Solde prévisionnel après charges fixes.',
      actions: <Widget>[
        FrostedButton.filled(label: 'Détails', onPressed: () {}),
        FrostedButton.text(label: 'Historique', onPressed: () {}),
      ],
    );
  }
}

class _CardsDemo extends StatelessWidget {
  const _CardsDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Expanded(
                child: FrostedCard(
                  child: _CardBody(
                    title: 'Filled',
                    body: 'Surface opaque par défaut.',
                  ),
                ),
              ),
              const SizedBox(width: FrostedSpacing.sp3),
              const Expanded(
                child: FrostedCard(
                  variant: FrostedCardVariant.outlined,
                  child: _CardBody(
                    title: 'Outlined',
                    body: 'Groupe de contenu discret.',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: FrostedSpacing.sp3),
        FrostedCard(
          variant: FrostedCardVariant.accent,
          onTap: () {},
          child: const _CardBody(
            title: 'Accent · tappable',
            body: 'Primary container, ripple + morph au press.',
          ),
        ),
      ],
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(title, style: FrostedTypeScale.titleMedium),
        const SizedBox(height: FrostedSpacing.sp2),
        Text(body, style: FrostedTypeScale.bodySmall),
      ],
    );
  }
}

class _ListDemo extends StatefulWidget {
  const _ListDemo();

  @override
  State<_ListDemo> createState() => _ListDemoState();
}

class _ListDemoState extends State<_ListDemo> {
  bool _wifi = true;
  bool _bluetooth = false;
  int _selectedAccount = 0;
  int _selectedCategory = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FrostedListSection(
          label: 'Récents',
          tiles: <FrostedListTile>[
            FrostedListTile(
              leading: const FrostedListAvatar(icon: Icons.person_outline),
              title: 'Ada Lovelace',
              subtitle: 'Programs of the Analytical Engine',
              trailing: const Text('9:42'),
              onTap: () {},
            ),
            FrostedListTile(
              leading:
                  const FrostedListAvatar(icon: Icons.notifications_outlined),
              title: 'Notifications',
              subtitle: '3 mentions, 2 follows',
              trailing: const Text('5'),
              onTap: () {},
            ),
            FrostedListTile(
              leading: const FrostedListAvatar(icon: Icons.favorite_outline),
              title: 'Liquid Glass',
              subtitle: 'Épinglé · 12 éléments',
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: FrostedSpacing.sp5),

        FrostedListSection(
          label: 'Réseau',
          tiles: <FrostedListTile>[
            FrostedListTile(
              leading: const Icon(Icons.wifi),
              title: 'Wi-Fi',
              trailing: FrostedSwitch(
                value: _wifi,
                onChanged: (bool v) => setState(() => _wifi = v),
              ),
              onTap: () => setState(() => _wifi = !_wifi),
            ),
            FrostedListTile(
              leading: const Icon(Icons.bluetooth),
              title: 'Bluetooth',
              trailing: FrostedSwitch(
                value: _bluetooth,
                onChanged: (bool v) => setState(() => _bluetooth = v),
              ),
              onTap: () => setState(() => _bluetooth = !_bluetooth),
            ),
          ],
        ),
        const SizedBox(height: FrostedSpacing.sp5),

        FrostedListSection(
          label: 'Compte par défaut',
          tiles: <FrostedListTile>[
            for (int i = 0; i < _accounts.length; i++)
              FrostedListTile(
                title: _accounts[i],
                trailing: _selectedAccount == i
                    ? const Icon(Icons.check)
                    : null,
                selected: _selectedAccount == i,
                onTap: () => setState(() => _selectedAccount = i),
              ),
          ],
        ),
        const SizedBox(height: FrostedSpacing.sp5),

        FrostedListSection(
          tiles: <FrostedListTile>[
            FrostedListTile(
              leading: const Icon(Icons.logout),
              title: 'Se déconnecter',
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: FrostedSpacing.sp5),

        FrostedListSection(
          label: 'Catégories',
          tiles: <FrostedListTile>[
            for (int i = 0; i < _categories.length; i++)
              FrostedListTile(
                leading: const Icon(Icons.sell_outlined),
                title: _categories[i],
                variant: FrostedListTileVariant.plain,
                trailing: _selectedCategory == i
                    ? const Icon(Icons.check)
                    : null,
                selected: _selectedCategory == i,
                onTap: () => setState(() => _selectedCategory = i),
              ),
          ],
        ),
        const SizedBox(height: FrostedSpacing.sp5),

        FrostedListSection(
          label: 'Informations',
          tiles: const <FrostedListTile>[
            FrostedListTile(
              leading: Icon(Icons.tag),
              title: 'Version',
              trailing: Text('2.0.0'),
            ),
            FrostedListTile(
              leading: Icon(Icons.fingerprint),
              title: 'Build',
              trailing: Text('1042'),
            ),
          ],
        ),
      ],
    );
  }

  static const List<String> _accounts = <String>[
    'Compte courant',
    'Livret A',
    'Épargne',
  ];

  static const List<String> _categories = <String>[
    'Alimentation',
    'Transports',
    'Loisirs',
  ];
}

class _ExpansionDemo extends StatelessWidget {
  const _ExpansionDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FrostedExpansionTile(
          leading: const Icon(Icons.notifications_outlined),
          title: 'Notifications',
          subtitle: 'Push, e-mail, son',
          initiallyExpanded: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Choisissez comment vous êtes averti des nouvelles '
                'transactions et des dépassements de budget.',
                style: FrostedTypeScale.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: FrostedSpacing.sp3),
        const FrostedExpansionTile(
          leading: Icon(Icons.help_outline),
          title: 'Comment ça marche ?',
          child: Text(
            'Ajoutez vos revenus et charges fixes, MyBudget calcule '
            'votre solde prévisionnel mois par mois.',
          ),
        ),
      ],
    );
  }
}

class _CarouselDemo extends StatelessWidget {
  const _CarouselDemo();

  static const List<List<Color>> _gradients = <List<Color>>[
    <Color>[Color(0xFF7C5CFF), Color(0xFF3CC9D8)],
    <Color>[Color(0xFFFF6FA5), Color(0xFFE3B341)],
    <Color>[Color(0xFF4CC38A), Color(0xFF3CC9D8)],
  ];

  @override
  Widget build(BuildContext context) {
    return FrostedCarousel(
      items: <Widget>[
        for (int i = 0; i < _gradients.length; i++)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _gradients[i],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  BorderRadius.circular(FrostedRadius.lg),
            ),
            child: Center(
              child: Text(
                'Carte ${i + 1}',
                style: FrostedTypeScale.titleLarge
                    .copyWith(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

class _MultiBrowseDemo extends StatelessWidget {
  const _MultiBrowseDemo();

  static const List<Color> _colors = <Color>[
    Color(0xFF7C5CFF),
    Color(0xFFFF6FA5),
    Color(0xFF4CC38A),
    Color(0xFFE3B341),
    Color(0xFF3CC9D8),
    Color(0xFFC9BEFF),
  ];

  @override
  Widget build(BuildContext context) {
    return FrostedMultiBrowseCarousel(
      height: 160,
      items: <Widget>[
        for (int i = 0; i < _colors.length; i++)
          ColoredBox(
            color: _colors[i],
            child: Center(
              child: Text(
                '${i + 1}',
                style: FrostedTypeScale.headlineSmall
                    .copyWith(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

class _BannerDemo extends StatelessWidget {
  const _BannerDemo();

  @override
  Widget build(BuildContext context) {
    return FrostedBanner(
      icon: Icons.info_outline,
      message: 'Une mise à jour est disponible.',
      actionLabel: 'Mettre à jour',
      onAction: () {},
    );
  }
}
