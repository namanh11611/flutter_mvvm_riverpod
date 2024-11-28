import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/constants/constants.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_theme_mode_provider.g.dart';

@riverpod
class AppThemeMode extends _$AppThemeMode {
  @override
  Future<ThemeMode> build() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final currentMode = sharedPreferences.getString(Constants.themeModeKey);
    return ThemeMode.values.firstWhere(
          (value) => currentMode == value.name,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> updateMode(ThemeMode mode) async {
    state = AsyncData(mode);
    final sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString(Constants.themeModeKey, mode.name);
  }
}
