import 'package:flutter/material.dart';
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
  };

  static const String defaultIcon = 'label';
  static const int defaultColor = 0xFF42A5F5;

  static const List<({String name, String icon, int color})> defaultCategories = [
    (name: 'Alimentation', icon: 'restaurant', color: 0xFFFFA726),
    (name: 'Logement', icon: 'home', color: 0xFF42A5F5),
    (name: 'Transport', icon: 'directions_car', color: 0xFF66BB6A),
    (name: 'Loisirs', icon: 'sports_esports', color: 0xFFAB47BC),
    (name: 'Santé', icon: 'medical_services', color: 0xFFEF5350),
    (name: 'Shopping', icon: 'shopping_bag', color: 0xFFEC407A),
    (name: 'Salaire', icon: 'account_balance_wallet', color: 0xFF26A69A),
    (name: 'Divers', icon: 'more_horiz', color: 0xFF9E9E9E),
  ];

  static IconData resolveIcon(String iconKey) {
    if (RegExp(r'^\d+$').hasMatch(iconKey)) {
      return IconData(int.parse(iconKey), fontFamily: 'MaterialIcons');
    }
    return icons[iconKey] ?? Symbols.category_rounded;
  }

  static List<String> get iconNames => icons.keys.toList();

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
