import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/expense_model.dart';

abstract final class ExpensePromptBuilder {
  static String build(
    List<CategoryModel> categories,
    List<ExpenseModel> recurringExpenses,
  ) {
    final categoriesJson = categories
        .map((c) =>
            '{"id": ${c.id}, "name": "${c.name}", "icon": "${c.icon}", "color": "${CategoryDefaults.colorToHex(c.color)}"}')
        .join(', ');

    final availableIcons = CategoryDefaults.iconNames.join(', ');

    final availableColors =
        CategoryDefaults.colors.map(CategoryDefaults.colorToHex).join(', ');

    final buffer = StringBuffer()
      ..writeln('Tu es un assistant de catégorisation de dépenses.')
      ..writeln('Catégories existantes : [$categoriesJson]')
      ..writeln('Icônes disponibles : [$availableIcons]')
      ..writeln('Couleurs disponibles (hex) : [$availableColors]');

    if (recurringExpenses.isNotEmpty) {
      final recurringJson = recurringExpenses
          .map((e) => '{"name": "${e.name}", "frequency": "${e.frequency}"}')
          .join(', ');
      buffer.writeln(
        'Dépenses récurrentes de l\'utilisateur : [$recurringJson]',
      );
    }

    buffer
      ..writeln('Règles :')
      ..writeln('1. Extrais le nom, le montant et la fréquence')
      ..writeln(
        '2. Si une catégorie existante correspond → categoryId (et newCategory/newCategoryIcon/newCategoryColor = null)',
      )
      ..writeln(
        '3. Sinon → newCategory = "<nom>", newCategoryIcon = icône la plus pertinente, newCategoryColor = couleur hex la plus pertinente (et categoryId = null)',
      )
      ..writeln(
        '4. Si le nom correspond à une dépense récurrente connue, utilise la même fréquence',
      )
      ..write(
        '5. Sinon, fréquence = "Ponctuel" sauf si "mensuel" ou "annuel" précisé explicitement',
      );

    return buffer.toString();
  }

  static String buildForLocalModel(
    List<CategoryModel> categories,
    List<ExpenseModel> recurringExpenses,
  ) {
    final base = build(categories, recurringExpenses);
    return '$base\n\n'
        'Réponds UNIQUEMENT avec un objet JSON valide ayant cette structure exacte : '
        '{"name": string, "amount": number, "categoryId": int|null, '
        '"newCategory": string|null, "newCategoryIcon": string|null, '
        '"newCategoryColor": string|null, "frequency": "Ponctuel"|"Mensuel"|"Annuel"}. '
        'Aucun texte en dehors du JSON.';
  }
}
