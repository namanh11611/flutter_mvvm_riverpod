import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../constants/constants.dart';

part 'app_theme_mode_provider.g.dart';

@riverpod
class AppThemeMode extends _$AppThemeMode {
  @override
  Future<ThemeMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    final currentMode = prefs.getString(Constants.themeModeKey);
    return ThemeMode.values.firstWhere(
          (value) => currentMode == value.name,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> updateMode(ThemeMode mode) async {
    state = AsyncData(mode);
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(Constants.themeModeKey, mode.name);
  }
}
