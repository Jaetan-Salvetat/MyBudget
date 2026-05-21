import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:intl/intl.dart';

class DateSelector {
  static Future<DateTime?> showFullDatePicker({
    required BuildContext context,
    required DateTime initialDate,
  }) async {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('fr', 'FR'),
    );
  }

  static Future<DateTime?> showDayPicker({
    required BuildContext context,
    required DateTime initialDate,
  }) async {
    FocusScope.of(context).requestFocus(FocusNode());
    DateTime? selectedDate;
    await FrostedDialog.show(
      context: context,
      title: const Text('Choisir le jour du mois'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: 31,
          itemBuilder: (context, index) {
            final day = index + 1;
            final isSelected = initialDate.day == day;
            return _DateSelectionItem(
              label: '$day',
              isSelected: isSelected,
              onTap: () {
                selectedDate = DateTime(
                  initialDate.year,
                  initialDate.month,
                  day,
                );
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
      actions: [
        FrostedTextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ],
    );
    return selectedDate;
  }

  static Future<DateTime?> showMonthDayPicker({
    required BuildContext context,
    required DateTime initialDate,
  }) async {
    FocusScope.of(context).requestFocus(FocusNode());
    DateTime? selectedDate;
    int tempMonth = initialDate.month;
    int tempDay = initialDate.day;

    await FrostedDialog.show(
      context: context,
      title: const Text('Choisir la date'),
      content: StatefulBuilder(
        builder: (context, setStateDialog) {
          final daysInMonth = DateTime(initialDate.year, tempMonth + 1, 0).day;
          if (tempDay > daysInMonth) tempDay = daysInMonth;

          return SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mois',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 2.5,
                        ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final month = index + 1;
                      final isSelected = tempMonth == month;
                      final monthName = DateFormat(
                        'MMM',
                        'fr_FR',
                      ).format(DateTime(initialDate.year, month));
                      final label = monthName.replaceFirst(
                        monthName[0],
                        monthName[0].toUpperCase(),
                      );
                      return _DateSelectionItem(
                        label: label,
                        isSelected: isSelected,
                        onTap: () => setStateDialog(() => tempMonth = month),
                        fontSize: 12,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Jour',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                    itemCount: daysInMonth,
                    itemBuilder: (context, index) {
                      final day = index + 1;
                      final isSelected = tempDay == day;
                      return _DateSelectionItem(
                        label: '$day',
                        isSelected: isSelected,
                        onTap: () => setStateDialog(() => tempDay = day),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      actions: [
        FrostedTextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FrostedFilledButton(
          onPressed: () {
            selectedDate = DateTime(initialDate.year, tempMonth, tempDay);
            Navigator.pop(context);
          },
          child: const Text('Valider'),
        ),
      ],
    );
    return selectedDate;
  }

  static Future<DateTime?> showMonthYearPicker({
    required BuildContext context,
    required DateTime initialDate,
  }) async {
    FocusScope.of(context).requestFocus(FocusNode());
    DateTime? selectedDate;
    int tempYear = initialDate.year;
    int tempMonth = initialDate.month;
    final int firstYear = 2020;
    final int lastYear = 2100;

    await FrostedDialog.show(
      context: context,
      title: const Text('Choisir le mois'),
      content: StatefulBuilder(
        builder: (context, setStateDialog) {
          return SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Année',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FrostedIconButton(
                        icon: Symbols.chevron_left_rounded,
                        onPressed: tempYear > firstYear
                            ? () => setStateDialog(() => tempYear--)
                            : null,
                      ),
                      Text(
                        '$tempYear',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      FrostedIconButton(
                        icon: Symbols.chevron_right_rounded,
                        onPressed: tempYear < lastYear
                            ? () => setStateDialog(() => tempYear++)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Mois',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 2.5,
                        ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final month = index + 1;
                      final isSelected = tempMonth == month;
                      final monthName = DateFormat(
                        'MMM',
                        'fr_FR',
                      ).format(DateTime(tempYear, month));
                      final label = monthName.replaceFirst(
                        monthName[0],
                        monthName[0].toUpperCase(),
                      );
                      return _DateSelectionItem(
                        label: label,
                        isSelected: isSelected,
                        onTap: () => setStateDialog(() => tempMonth = month),
                        fontSize: 12,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      actions: [
        FrostedTextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FrostedFilledButton(
          onPressed: () {
            selectedDate = DateTime(tempYear, tempMonth);
            Navigator.pop(context);
          },
          child: const Text('Valider'),
        ),
      ],
    );
    return selectedDate;
  }
}

class _DateSelectionItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double fontSize;

  const _DateSelectionItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
}
