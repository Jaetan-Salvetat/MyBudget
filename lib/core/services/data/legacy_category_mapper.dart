import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/utils/text_normalizer.dart';

class LegacyCategoryMapper {
  static const String fallback = 'divers.autre';

  static const Map<String, String> _defaultCategorySlugs = {
    'alimentation': 'alimentation.courses',
    'logement': 'logement.loyer',
    'transport': 'transport.carburant',
    'loisirs': 'loisirs.sorties',
    'sante': 'sante_beaute.soins_medicaux',
    'shopping': 'shopping.vetements',
    'divers': fallback,
  };

  final CategoryTaxonomyService _taxonomy;

  const LegacyCategoryMapper(this._taxonomy);

  String expenseSlugFor(String legacyName) {
    final normalized = TextNormalizer.normalize(legacyName);
    final slug = _defaultCategorySlugs[normalized] ?? _leafLabelled(normalized);

    if (slug == null) return fallback;

    final node = _taxonomy.resolve(slug);
    if (node == null || node.group.type != TransactionType.expense) {
      return fallback;
    }
    return node.slug;
  }

  String? _leafLabelled(String normalizedLabel) {
    for (final leaf in _taxonomy.leaves) {
      if (TextNormalizer.normalize(leaf.label) == normalizedLabel) {
        return leaf.slug;
      }
    }
    return null;
  }
}
