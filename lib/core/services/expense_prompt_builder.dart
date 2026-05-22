import 'package:mybudget/core/constants/category_defaults.dart';
import 'package:mybudget/models/category_model.dart';
import 'package:mybudget/models/expense_model.dart';

abstract final class ExpensePromptBuilder {
  static String buildParse(
    List<CategoryModel> categories,
    List<ExpenseModel> recurringExpenses,
  ) {
    final categoriesJson = categories
        .map((c) => '{"id":${c.id},"name":"${c.name}"}')
        .join(',');

    final buffer = StringBuffer()
      ..writeln('You are an expense parser for a French finance app.')
      ..writeln('Parse the user\'s French input into a structured expense.')
      ..writeln()
      ..writeln('# Categories')
      ..writeln('[$categoriesJson]')
      ..writeln()
      ..writeln('# Rules')
      ..writeln(
        '1. name: clean concise French label, first letter uppercase, no slang',
      )
      ..writeln(
        '2. amount: extract numeric value. '
        'French slang for euros: "balles", "balle"',
      )
      ..writeln(
        '3. frequency: "Ponctuel" (default). '
        '"Mensuel" if mensuel/par mois/chaque mois. '
        '"Annuel" if annuel/par an/chaque année',
      )
      ..writeln(
        '4. Match the expense to the most fitting existing category → '
        'categoryId=id, newCategory=null. '
        'Always prefer an existing category over creating a new one.',
      )
      ..writeln(
        '5. Only if no category fits at all → categoryId=null, '
        'newCategory=broad French theme name (never an item name)',
      );

    if (recurringExpenses.isNotEmpty) {
      final recurringJson = recurringExpenses
          .map((e) => '{"name":"${e.name}","frequency":"${e.frequency}"}')
          .join(',');
      buffer.writeln(
        '6. If expense matches a known recurring, '
        'reuse its frequency: [$recurringJson]',
      );
    }

    final alimentation =
        categories.where((c) => c.name == 'Alimentation').firstOrNull;
    final alimentationId = alimentation?.id ?? 1;
    final sport =
        categories.where((c) => c.name == 'Sport').firstOrNull;
    final sportId = sport?.id;
    final abonnements =
        categories.where((c) => c.name == 'Abonnements').firstOrNull;
    final abonnementsId = abonnements?.id;

    buffer
      ..writeln()
      ..writeln('# Examples')
      ..writeln(
        '"café 3.50" → '
        '{"name":"Café","amount":3.5,"frequency":"Ponctuel",'
        '"categoryId":$alimentationId,"newCategory":null}',
      );

    if (sportId != null) {
      buffer.writeln(
        '"salle de sport 40€/mois" → '
        '{"name":"Salle de sport","amount":40.0,"frequency":"Mensuel",'
        '"categoryId":$sportId,"newCategory":null}',
      );
    }

    if (abonnementsId != null) {
      buffer.write(
        '"netflix 17.99/mois" → '
        '{"name":"Netflix","amount":17.99,"frequency":"Mensuel",'
        '"categoryId":$abonnementsId,"newCategory":null}',
      );
    }

    return buffer.toString();
  }

  static String buildParseLocal(
    List<CategoryModel> categories,
    List<ExpenseModel> recurringExpenses,
  ) {
    final base = buildParse(categories, recurringExpenses);
    return '$base\n\n'
        'IMPORTANT: Respond with ONLY a valid JSON object. '
        'Schema: {"name":string,"amount":number,"frequency":"Ponctuel"|"Mensuel"|"Annuel",'
        '"categoryId":int|null,"newCategory":string|null}. '
        'No text outside the JSON.';
  }

  static String buildParseCloud(
    List<CategoryModel> categories,
    List<ExpenseModel> recurringExpenses,
  ) {
    final base = buildParse(categories, recurringExpenses);
    final availableIcons = CategoryDefaults.iconNames.join(', ');
    final availableColors =
        CategoryDefaults.colors.map(CategoryDefaults.colorToHex).join(', ');

    return '$base\n\n'
        '# New category styling (only when newCategory is set)\n'
        'If categoryId=null, also pick icon and color for the new category.\n'
        'Icons: $availableIcons\n'
        'Colors: $availableColors';
  }

  static String buildCategorize(String categoryName) {
    final availableIcons = CategoryDefaults.iconNames.join(', ');
    final availableColors =
        CategoryDefaults.colors.map(CategoryDefaults.colorToHex).join(', ');

    final examples = CategoryDefaults.defaultCategories
        .take(3)
        .map(
          (c) =>
              '"${c.name}" → {"icon":"${c.icon}",'
              '"color":"${CategoryDefaults.colorToHex(c.color)}"}',
        )
        .join('\n');

    return 'Pick the best icon and color for this French expense category.\n'
        '\n'
        'Category: "$categoryName"\n'
        '\n'
        '# Icons\n'
        '$availableIcons\n'
        '\n'
        '# Colors\n'
        '$availableColors\n'
        '\n'
        '# Examples\n'
        '$examples\n'
        '\n'
        'Respond with ONLY a valid JSON object: {"icon":"...","color":"#..."}';
  }
}
