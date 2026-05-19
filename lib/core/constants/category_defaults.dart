import 'package:flutter/material.dart';

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
    'home': Icons.home,
    'restaurant': Icons.restaurant,
    'local_cafe': Icons.local_cafe,
    'local_bar': Icons.local_bar,
    'shopping_cart': Icons.shopping_cart,
    'shopping_bag': Icons.shopping_bag,
    'directions_car': Icons.directions_car,
    'directions_bus': Icons.directions_bus,
    'two_wheeler': Icons.two_wheeler,
    'local_gas_station': Icons.local_gas_station,
    'flight_takeoff': Icons.flight_takeoff,
    'hotel': Icons.hotel,
    'medical_services': Icons.medical_services,
    'local_pharmacy': Icons.local_pharmacy,
    'fitness_center': Icons.fitness_center,
    'sports_esports': Icons.sports_esports,
    'movie': Icons.movie,
    'music_note': Icons.music_note,
    'menu_book': Icons.menu_book,
    'school': Icons.school,
    'child_care': Icons.child_care,
    'pets': Icons.pets,
    'checkroom': Icons.checkroom,
    'dry_cleaning': Icons.dry_cleaning,
    'wifi': Icons.wifi,
    'phone_android': Icons.phone_android,
    'subscriptions': Icons.subscriptions,
    'account_balance_wallet': Icons.account_balance_wallet,
    'account_balance': Icons.account_balance,
    'savings': Icons.savings,
    'card_giftcard': Icons.card_giftcard,
    'volunteer_activism': Icons.volunteer_activism,
    'build': Icons.build,
    'handyman': Icons.handyman,
    'local_laundry_service': Icons.local_laundry_service,
    'spa': Icons.spa,
    'self_improvement': Icons.self_improvement,
    'label': Icons.label,
    'more_horiz': Icons.more_horiz,
  };

  static const String defaultIcon = 'label';
  static const int defaultColor = 0xFF42A5F5;

  static IconData resolveIcon(String iconKey) {
    if (RegExp(r'^\d+$').hasMatch(iconKey)) {
      return IconData(int.parse(iconKey), fontFamily: 'MaterialIcons');
    }
    return icons[iconKey] ?? Icons.category;
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
