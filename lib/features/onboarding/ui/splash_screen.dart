import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/constants.dart';
import '../../../routing/routes.dart';
import '../../authentication/repository/authentication_repository.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF3F0FF), // Light purple
              Color(0xFFFFFFFF), // White
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: const Center(child: _AuthentickLogo()),
      ),
    );
  }

  Future<void> _checkLoginStatus() async {
    final authRepo = ref.read(authenticationRepositoryProvider);
    final isLoggedIn = await authRepo.isLogin();
    final hasCompletedOnboarding = await authRepo.hasCompletedOnboarding();

    debugPrint(
      '${Constants.tag} [SplashScreen._checkLoginStatus] isLoggedIn = $isLoggedIn, hasCompletedOnboarding = $hasCompletedOnboarding',
    );

    await authRepo.setHasCompletedOnboarding(false);

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    if (!hasCompletedOnboarding) {
      debugPrint(
        '${Constants.tag} [SplashScreen] Navigating to onboarding flow (onboarding not completed)',
      );
      context.pushReplacement(Routes.onboardingFlow);
    } else if (isLoggedIn) {
      debugPrint(
        '${Constants.tag} [SplashScreen] Navigating to main (user is logged in)',
      );
      context.pushReplacement(Routes.main);
    } else {
      debugPrint(
        '${Constants.tag} [SplashScreen] Navigating to register (onboarding completed, not logged in)',
      );
      context.pushReplacement(Routes.register);
    }
  }
}

class _AuthentickLogo extends StatefulWidget {
  const _AuthentickLogo();

  @override
  State<_AuthentickLogo> createState() => _AuthentickLogoState();
}

class _AuthentickLogoState extends State<_AuthentickLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: SvgPicture.asset(
              'assets/images/authentick_logo.svg',
              width: 200,
              height: 60,
              fit: BoxFit.contain,
              placeholderBuilder: (context) => const SizedBox(
                width: 200,
                height: 60,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF6A4FFB),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
