import 'package:flutter/widgets.dart';

/// Marge horizontale entre le contenu d'un écran du main flow et les bords de
/// l'écran. Les quatre onglets la partagent : leurs titres, leurs boutons et
/// leurs listes s'alignent d'un onglet à l'autre.
const double kMainFlowGutter = 16;

/// Marges verticales de la barre de titre d'un écran du main flow.
const EdgeInsets kMainFlowTopBarPadding = EdgeInsets.fromLTRB(0, 8, 0, 12);

/// Hauteur occupée par la nav pill flottante du main flow, sa marge basse
/// comprise et sa safe area exclue.
const double kNavPillFootprint = 68;

/// Air laissé entre le dernier élément d'un écran scrollable et la nav pill.
const double kNavPillClearance = 16;

/// Espace à réserver en bas du contenu scrollable d'un écran du main flow pour
/// que son dernier élément ne finisse pas sous la nav pill.
double mainFlowBottomInset(BuildContext context) =>
    kNavPillFootprint +
    kNavPillClearance +
    MediaQuery.paddingOf(context).bottom;
