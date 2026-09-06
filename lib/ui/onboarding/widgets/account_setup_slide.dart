import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/constants/banks_list.dart';
import 'package:mybudget/core/theme/text_styles.dart';

class AccountSetupSlide extends StatelessWidget {
  const AccountSetupSlide({
    required this.nameController,
    required this.bankController,
    required this.bankFocusNode,
    super.key,
  });
  static const String title = 'Un compte,\net c\'est parti.';
  static const String body =
      'C\'est là que tes dépenses atterrissent. Tu pourras en ajouter '
      'd\'autres et faire circuler l\'argent entre eux.';
  static const String privacy =
      'Tout reste sur ton téléphone : aucune connexion bancaire, aucun '
      'compte à créer, et l\'analyse tourne hors ligne.';

  final TextEditingController nameController;
  final TextEditingController bankController;
  final FocusNode bankFocusNode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        FrostedSpacing.sp5,
        FrostedSpacing.sp5,
        FrostedSpacing.sp5,
        FrostedSpacing.sp4,
      ),
      children: [
        Text(
          title,
          style: AppTextStyles.displaySerifItalic(
            fontSize: 34,
            height: 38 / 34,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: FrostedSpacing.sp3),
        Text(
          body,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: FrostedSpacing.sp5),
        FrostedTextField(
          controller: nameController,
          label: 'Nom du compte',
          leadingIcon: Symbols.account_balance_wallet_rounded,
        ),
        const SizedBox(height: FrostedSpacing.sp3),
        FrostedAutocomplete(
          options: BanksList.frenchBanks,
          controller: bankController,
          focusNode: bankFocusNode,
          label: 'Nom de la banque',
          hintText: 'Ex: Crédit Agricole',
          leadingIcon: Symbols.account_balance_rounded,
        ),
        const SizedBox(height: FrostedSpacing.sp4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Symbols.lock_rounded,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: FrostedSpacing.sp2),
            Expanded(
              child: Text(
                privacy,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
