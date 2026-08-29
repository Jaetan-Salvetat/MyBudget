import 'package:flutter/widgets.dart';

/// Marge horizontale entre le contenu d'un écran du main flow et les bords de
/// l'écran. Les quatre onglets la partagent : leurs titres, leurs boutons et
/// leurs listes s'alignent d'un onglet à l'autre.
const double kMainFlowGutter = 16;

/// Marges verticales de la barre de titre d'un écran du main flow.
const EdgeInsets kMainFlowTopBarPadding = EdgeInsets.fromLTRB(0, 8, 0, 12);

/// Air laissé entre le dernier élément d'un écran scrollable et la barre du
/// bas.
const double kMainFlowBottomClearance = 16;

/// Espace à réserver en bas du contenu scrollable d'un écran du main flow pour
/// que son dernier élément ne finisse pas sous la barre du bas.
///
/// Le body passe derrière la barre : le scaffold rend l'empreinte exacte de
/// celle-ci — safe area et air porté compris — dans le padding bas du body. Le
/// contenu n'a que son air à y ajouter ; redonner à la barre une hauteur en
/// dur laissait une centaine de pixels de vide après le dernier élément.
double mainFlowBottomInset(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom + kMainFlowBottomClearance;
