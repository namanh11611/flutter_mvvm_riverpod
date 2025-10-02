// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_theme_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AppThemeMode)
const appThemeModeProvider = AppThemeModeProvider._();

final class AppThemeModeProvider
    extends $AsyncNotifierProvider<AppThemeMode, ThemeMode> {
  const AppThemeModeProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'appThemeModeProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$appThemeModeHash();

  @$internal
  @override
  AppThemeMode create() => AppThemeMode();
}

String _$appThemeModeHash() => r'8833870cd9b956752a8eba72ba233889dfa104a7';

abstract class _$AppThemeMode extends $AsyncNotifier<ThemeMode> {
  FutureOr<ThemeMode> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<ThemeMode>, ThemeMode>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<ThemeMode>, ThemeMode>,
        AsyncValue<ThemeMode>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
