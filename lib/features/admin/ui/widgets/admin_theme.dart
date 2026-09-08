import 'package:flutter/material.dart';

/// Admin-only colors based on fly-DESIGN.md; retain the app's typography.
abstract final class AdminTheme {
  static const ink = Color(0xFF281950);
  static const violet = Color(0xFF7C3AED);
  static const border = Color(0xFFD5CFEF);

  static ThemeData from(ThemeData base) {
    final dark = base.brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: violet,
          brightness: base.brightness,
        ).copyWith(
          primary: dark ? const Color(0xFFCDB5FF) : violet,
          onPrimary: dark ? ink : Colors.white,
          surface: dark ? const Color(0xFF241D34) : Colors.white,
          onSurface: dark ? const Color(0xFFF0E9FF) : ink,
          onSurfaceVariant: dark
              ? const Color(0xFFCBC0DF)
              : const Color(0xFF686082),
          outlineVariant: dark ? const Color(0xFF514264) : border,
        );
    final navigation = dark ? const Color(0xFF21182F) : const Color(0xFFEDE6FA);
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: dark
          ? const Color(0xFF191321)
          : const Color(0xFFF5F1FC),
      textTheme: base.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: ink,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: navigation,
        indicatorColor: violet,
        selectedIconTheme: const IconThemeData(color: Colors.white),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: base.textTheme.labelLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: base.textTheme.labelLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: navigation,
        indicatorColor: dark
            ? const Color(0xFF573A80)
            : const Color(0xFFDCD0F4),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: base.dividerTheme.copyWith(color: scheme.outlineVariant),
      dataTableTheme: base.dataTableTheme.copyWith(
        headingRowColor: WidgetStatePropertyAll(
          dark ? const Color(0xFF332644) : const Color(0xFFEEE7FA),
        ),
        headingTextStyle: base.textTheme.labelLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: scheme.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
    );
  }

  static ({Color background, Color foreground}) metric(String key, bool dark) =>
      switch (key) {
        'pending' => (background: ink, foreground: Colors.white),
        'reviewing' => (background: violet, foreground: Colors.white),
        'suspended' => (
          background: dark ? const Color(0xFF40304F) : const Color(0xFFE8DDF7),
          foreground: dark ? const Color(0xFFF0E9FF) : ink,
        ),
        _ => (
          background: dark ? const Color(0xFF44303E) : const Color(0xFFF0E2EE),
          foreground: dark ? const Color(0xFFFFE7F4) : const Color(0xFF663251),
        ),
      };
}
