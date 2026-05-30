import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

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

class _ListDemo extends StatelessWidget {
  const _ListDemo();

  @override
  Widget build(BuildContext context) {
    return FrostedListSection(
      children: <Widget>[
        FrostedListTile(
          leading: const FrostedListAvatar(icon: Icons.person_outline),
          title: 'Ada Lovelace',
          subtitle: 'Programs of the Analytical Engine',
          trailing: const Text('9:42'),
          onTap: () {},
        ),
        FrostedListTile(
          leading: const FrostedListAvatar(icon: Icons.notifications_outlined),
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
          selected: true,
          onTap: () {},
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
