import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

abstract final class CategoryDefaults {
  static const List<int> colors = [
    0xFFEF5350, // red
    0xFFEC407A, // pink
    0xFFAB47BC, // purple
    0xFF7E57C2, // deep purple
    0xFF5C6BC0, // indigo
    0xFF42A5F5, // blue
    0xFF29B6F6, // light blue
    0xFF26C6DA, // cyan
    0xFF26A69A, // teal
    0xFF66BB6A, // green
    0xFF9CCC65, // light green
    0xFFD4E157, // lime
    0xFFFFCA28, // amber
    0xFFFFA726, // orange
    0xFFFF7043, // deep orange
    0xFF8D6E63, // brown
    0xFF78909C, // blue grey
    0xFF9E9E9E, // grey
  ];

  static const Map<String, IconData> icons = {
    'home': Symbols.home_rounded,
    'restaurant': Symbols.restaurant_rounded,
    'local_cafe': Symbols.local_cafe_rounded,
    'local_bar': Symbols.local_bar_rounded,
    'shopping_cart': Symbols.shopping_cart_rounded,
    'shopping_bag': Symbols.shopping_bag_rounded,
    'directions_car': Symbols.directions_car_rounded,
    'directions_bus': Symbols.directions_bus_rounded,
    'two_wheeler': Symbols.two_wheeler_rounded,
    'local_gas_station': Symbols.local_gas_station_rounded,
    'flight_takeoff': Symbols.flight_takeoff_rounded,
    'hotel': Symbols.hotel_rounded,
    'medical_services': Symbols.medical_services_rounded,
    'local_pharmacy': Symbols.local_pharmacy_rounded,
    'fitness_center': Symbols.fitness_center_rounded,
    'sports_esports': Symbols.sports_esports_rounded,
    'movie': Symbols.movie_rounded,
    'music_note': Symbols.music_note_rounded,
    'menu_book': Symbols.menu_book_rounded,
    'school': Symbols.school_rounded,
    'child_care': Symbols.child_care_rounded,
    'pets': Symbols.pets_rounded,
    'checkroom': Symbols.checkroom_rounded,
    'dry_cleaning': Symbols.dry_cleaning_rounded,
    'wifi': Symbols.wifi_rounded,
    'phone_android': Symbols.phone_android_rounded,
    'subscriptions': Symbols.subscriptions_rounded,
    'account_balance_wallet': Symbols.account_balance_wallet_rounded,
    'account_balance': Symbols.account_balance_rounded,
    'savings': Symbols.savings_rounded,
    'card_giftcard': Symbols.card_giftcard_rounded,
    'volunteer_activism': Symbols.volunteer_activism_rounded,
    'build': Symbols.build_rounded,
    'handyman': Symbols.handyman_rounded,
    'local_laundry_service': Symbols.local_laundry_service_rounded,
    'spa': Symbols.spa_rounded,
    'self_improvement': Symbols.self_improvement_rounded,
    'label': Symbols.label_rounded,
    'more_horiz': Symbols.more_horiz_rounded,
    'health_and_safety': Symbols.health_and_safety_rounded,
    'local_activity': Symbols.local_activity_rounded,
    'category': Symbols.category_rounded,
    'paid': Symbols.paid_rounded,
    'swap_horiz': Symbols.swap_horiz_rounded,
    'trending_up': Symbols.trending_up_rounded,
    'local_grocery_store': Symbols.local_grocery_store_rounded,
    'storefront': Symbols.storefront_rounded,
    'local_convenience_store': Symbols.local_convenience_store_rounded,
    'bakery_dining': Symbols.bakery_dining_rounded,
    'dinner_dining': Symbols.dinner_dining_rounded,
    'fastfood': Symbols.fastfood_rounded,
    'delivery_dining': Symbols.delivery_dining_rounded,
    'local_taxi': Symbols.local_taxi_rounded,
    'local_parking': Symbols.local_parking_rounded,
    'toll': Symbols.toll_rounded,
    'car_repair': Symbols.car_repair_rounded,
    'apartment': Symbols.apartment_rounded,
    'receipt_long': Symbols.receipt_long_rounded,
    'bolt': Symbols.bolt_rounded,
    'water_drop': Symbols.water_drop_rounded,
    'stethoscope': Symbols.stethoscope_rounded,
    'content_cut': Symbols.content_cut_rounded,
    'devices': Symbols.devices_rounded,
    'chair': Symbols.chair_rounded,
    'atm': Symbols.atm_rounded,
    'request_quote': Symbols.request_quote_rounded,
    'gavel': Symbols.gavel_rounded,
    'shield': Symbols.shield_rounded,
    'car_crash': Symbols.car_crash_rounded,
    'credit_score': Symbols.credit_score_rounded,
    'backpack': Symbols.backpack_rounded,
    'cast_for_education': Symbols.cast_for_education_rounded,
    'lunch_dining': Symbols.lunch_dining_rounded,
    'toys': Symbols.toys_rounded,
    'family_restroom': Symbols.family_restroom_rounded,
    'flight': Symbols.flight_rounded,
    'car_rental': Symbols.car_rental_rounded,
    'museum': Symbols.museum_rounded,
    'casino': Symbols.casino_rounded,
    'payments': Symbols.payments_rounded,
    'workspace_premium': Symbols.workspace_premium_rounded,
    'work': Symbols.work_rounded,
    'elderly': Symbols.elderly_rounded,
    'work_history': Symbols.work_history_rounded,
    'home_work': Symbols.home_work_rounded,
    'groups': Symbols.groups_rounded,
    'sell': Symbols.sell_rounded,
    'key': Symbols.key_rounded,
    'cloud': Symbols.cloud_rounded,
    'apps': Symbols.apps_rounded,
    'smart_toy': Symbols.smart_toy_rounded,
    'dns': Symbols.dns_rounded,
    'hard_drive': Symbols.hard_drive_rounded,
  };

  static const String defaultIcon = 'label';
  static const int defaultColor = 0xFF42A5F5;

  static final Map<int, String> _keysByCodePoint = {
    for (final entry in icons.entries) entry.value.codePoint: entry.key,
  };

  /// The [icons] key [value] designates, or null when nothing matches.
  ///
  /// Accepts the codePoint strings written by the pre-taxonomy categories, so
  /// legacy overrides heal into keys the first time they are rewritten.
  /// Codepoints are not unique across the icon set, but colliding entries share
  /// the same glyph, so the key returned always renders what was stored.
  static String? canonicalIconKey(String? value) {
    if (value == null) return null;

    final codePoint = int.tryParse(value);
    if (codePoint != null) return _keysByCodePoint[codePoint];

    return icons.containsKey(value) ? value : null;
  }

  static IconData resolveIcon(String iconKey) =>
      icons[canonicalIconKey(iconKey)] ?? Symbols.category_rounded;

  static String colorToHex(int color) {
    return '#${(color & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  static int? hexToColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    final value = int.tryParse(clean, radix: 16);
    if (value == null) return null;
    return 0xFF000000 | value;
  }
}
