import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_mvvm_riverpod/core/environment/env.dart';
import 'package:flutter_mvvm_riverpod/core/notifications/push_notification_service.dart';
import 'package:flutter_mvvm_riverpod/core/permissions/app_permission_service.dart';
import 'package:flutter_mvvm_riverpod/core/routing/router.dart';
import 'package:flutter_mvvm_riverpod/core/routing/routes.dart';
import 'package:flutter_mvvm_riverpod/core/theme/app_theme.dart';
import 'package:flutter_mvvm_riverpod/features/common/ui/providers/app_theme_mode_provider.dart';
import 'package:flutter_mvvm_riverpod/features/collaboration/ui/global_incoming_call_listener.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  if (!Env.hasSupabase) {
    runApp(const _ConfigurationErrorApp());
    return;
  }
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('vi')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const ProviderScope(child: GoBuddyApp()),
    ),
  );

  unawaited(_initializeAppServices());
}

Future<void> _initializeAppServices() async {
  try {
    // Keep native permission dialogs sequential so one request cannot obscure
    // another during startup.
    await PushNotificationService.initialize();
  } catch (error, stack) {
    debugPrint('Notification setup failed: $error\n$stack');
  }

  try {
    await const AppPermissionService().requestStartupPermissions();
  } catch (error, stack) {
    debugPrint('Startup permission setup failed: $error\n$stack');
  }
}

class _ConfigurationErrorApp extends StatelessWidget {
  const _ConfigurationErrorApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.settings_outlined, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Supabase configuration is missing',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Set SUPABASE_URL and SUPABASE_ANON_KEY in the local '
                    '.env file, regenerate the Envied configuration, and '
                    'restart the app.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class GoBuddyApp extends ConsumerStatefulWidget {
  const GoBuddyApp({super.key});

  @override
  ConsumerState<GoBuddyApp> createState() => _GoBuddyAppState();
}

class _GoBuddyAppState extends ConsumerState<GoBuddyApp> {
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (state) {
        if (state.event == AuthChangeEvent.passwordRecovery &&
            state.session != null) {
          router.go(Routes.resetPassword);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (error is AuthException) {
          final message = error.message.toLowerCase();
          if (message.contains('expired') ||
              message.contains('invalid') ||
              message.contains('otp')) {
            router.go(Routes.resetPassword);
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(appThemeModeProvider).value ?? ThemeMode.system;
    return MaterialApp.router(
      title: 'GoBuddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.materialTheme,
      darkTheme: AppTheme.darkMaterialTheme,
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      builder: (context, child) =>
          GlobalIncomingCallListener(child: child ?? const SizedBox.shrink()),
    );
  }
}
