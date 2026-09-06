import 'package:flutter/widgets.dart';

const double kMainFlowGutter = 16;

const EdgeInsets kMainFlowTopBarPadding = EdgeInsets.fromLTRB(0, 8, 0, 12);

const double kMainFlowBottomClearance = 16;

double mainFlowBottomInset(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom + kMainFlowBottomClearance;
