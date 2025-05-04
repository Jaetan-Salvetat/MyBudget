import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemeController extends GetxController {
  final RxInt themeModeIndex = ThemeMode.system.index.obs;

  ThemeMode get themeMode => ThemeMode.values[themeModeIndex.value];

  void changeTheme(ThemeMode mode) {
    themeModeIndex.value = mode.index;
    Get.changeThemeMode(mode);
  }
}
