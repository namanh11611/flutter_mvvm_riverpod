import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/authentication/ui/otp_screen.dart';
import '../features/authentication/ui/sign_in_screen.dart';
import '../features/authentication/ui/welcome_screen.dart';
import '../features/home/ui/home_screen.dart';
import '../features/onboarding/ui/onboarding_screen.dart';
import '../features/onboarding/ui/splash_screen.dart';
import '../features/profile/ui/appearances_screen.dart';
import '../features/profile/ui/lanaguages_screen.dart';
import '../routing/routes.dart';

class SlideRouteTransition extends CustomTransitionPage<void> {
  SlideRouteTransition({required super.child, required String routeName})
      : super(
          key: ValueKey(routeName),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            );
            final tween = Tween(begin: begin, end: end);
            final offsetAnimation = tween.animate(curve);

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
        );
}

final GoRouter router = GoRouter(
  initialLocation: Routes.splash,
  routes: [
    GoRoute(
      path: Routes.splash,
      pageBuilder: (context, state) => SlideRouteTransition(
        child: const SplashScreen(),
        routeName: Routes.splash,
      ),
    ),
    GoRoute(
      path: Routes.welcome,
      pageBuilder: (context, state) => SlideRouteTransition(
        child: const WelcomeScreen(),
        routeName: Routes.welcome,
      ),
    ),
    GoRoute(
      path: Routes.login,
      pageBuilder: (context, state) => SlideRouteTransition(
        child: const SignInScreen(),
        routeName: Routes.login,
      ),
    ),
    GoRoute(
        path: Routes.otp,
        pageBuilder: (context, state) {
          final map = state.extra as Map?;
          return SlideRouteTransition(
            child: OtpScreen(
              email: map?['email'],
              isRegister: map?['isRegister'],
            ),
            routeName: Routes.otp,
          );
        }),
    GoRoute(
      path: Routes.onboarding,
      pageBuilder: (context, state) => SlideRouteTransition(
        child: const OnboardingScreen(),
        routeName: Routes.onboarding,
      ),
    ),
    GoRoute(
      path: Routes.home,
      pageBuilder: (context, state) => SlideRouteTransition(
        child: const HomeScreen(),
        routeName: Routes.home,
      ),
    ),
    GoRoute(
      path: Routes.appearances,
      pageBuilder: (context, state) => SlideRouteTransition(
        child: const AppearancesScreen(),
        routeName: Routes.appearances,
      ),
    ),
    GoRoute(
      path: Routes.languages,
      pageBuilder: (context, state) => SlideRouteTransition(
        child: const LanguagesScreen(),
        routeName: Routes.languages,
      ),
    ),
  ],
);
