import 'package:mybudget/core/enums/transaction_type.dart';
import 'package:mybudget/core/services/quick_add/category_taxonomy_service.dart';
import 'package:mybudget/core/utils/text_normalizer.dart';

class LegacyCategoryMapper {
  static const String fallback = 'divers.autre';

  static const Map<String, String> _defaultCategorySlugs = {
    'alimentation': 'alimentation.supermarche',
    'logement': 'logement.loyer',
    'transport': 'transport.essence',
    'loisirs': 'loisirs.cinema_sortie',
    'sante': 'sante_beaute.medecin',
    'shopping': 'shopping.vetements',
    'divers': fallback,
  };

  final CategoryTaxonomyService _taxonomy;

  const LegacyCategoryMapper(this._taxonomy);

  String expenseSlugFor(String legacyName) {
    final normalized = TextNormalizer.normalize(legacyName);
    final slug = _defaultCategorySlugs[normalized] ?? _leafLabelled(normalized);

    if (slug == null) return fallback;

    final group = _taxonomy.groupOfSlug(slug);
    return group?.type == TransactionType.expense ? slug : fallback;
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
