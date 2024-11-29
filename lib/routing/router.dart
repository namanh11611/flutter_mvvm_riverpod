import 'package:flutter_mvvm_riverpod/features/home/presentation/screens/home_screen.dart';
import 'package:flutter_mvvm_riverpod/features/onboarding/presentation/splash_screen.dart';
import 'package:flutter_mvvm_riverpod/features/onboarding/presentation/welcome_screen.dart';
import 'package:flutter_mvvm_riverpod/routing/routes.dart';
import 'package:go_router/go_router.dart';

GoRouter router() {
  return GoRouter(
    initialLocation: Routes.splash,
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
    ],
  );
}