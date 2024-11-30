import 'package:flutter_mvvm_riverpod/features/home/ui/home_screen.dart';
import 'package:flutter_mvvm_riverpod/features/onboarding/ui/splash_screen.dart';
import 'package:flutter_mvvm_riverpod/features/authentication/ui/welcome_screen.dart';
import 'package:flutter_mvvm_riverpod/features/profile/ui/appearances_screen.dart';
import 'package:flutter_mvvm_riverpod/features/profile/ui/lanaguages_screen.dart';
import 'package:flutter_mvvm_riverpod/routing/routes.dart';
import 'package:go_router/go_router.dart';

GoRouter router() {
  return GoRouter(
    initialLocation: Routes.home,
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: Routes.appearances,
        builder: (context, state) => const AppearancesScreen(),
      ),
      GoRoute(
        path: Routes.languages,
        builder: (context, state) => const LanguagesScreen(),
      ),
    ],
  );
}