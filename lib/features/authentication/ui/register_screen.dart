import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/assets.dart';
import '../../../constants/constants.dart';
import '../../../features/authentication/repository/authentication_repository.dart';
import '../../../routing/routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import 'view_model/authentication_view_model.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
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
    final authState = ref.watch(authenticationViewModelProvider);

    // Listen to authentication state for navigation
    ref.listen(authenticationViewModelProvider, (previous, next) {
      debugPrint('${Constants.tag} [RegisterScreen] Auth state changed: $next');

      if (next is AsyncData) {
        final value = next.value;
        debugPrint(
          '${Constants.tag} [RegisterScreen] isSignInSuccessfully: ${value?.isSignInSuccessfully}',
        );

        if (value?.isSignInSuccessfully == true) {
          // User signed in successfully, navigate to onboarding flow
          debugPrint(
            '${Constants.tag} [RegisterScreen] Navigating to onboarding flow',
          );
          context.pushReplacement(Routes.onboardingFlow);
        }
      } else if (next is AsyncError) {
        debugPrint(
          '${Constants.tag} [RegisterScreen] Auth error: ${next.error}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: ${next.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    final isLoading = authState.isLoading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF), // White
              Color(0xFFF8F7FF), // Light purple
              Color(0xFFFFFFFF), // White
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with animation
                AnimatedBuilder(
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
                ),

                const SizedBox(height: 32),

                // Tagline
                Text(
                  'A social network where every moment is\nreal, every location is verified and every\nthought is authentic',
                  textAlign: TextAlign.center,
                  style: AppTheme.body16.copyWith(
                    color: AppColors.mono100,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 48),

                // Login/Signup Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A4FFB), // Purple
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isLoading
                        ? null
                        : () {
                            ref
                                .read(authenticationViewModelProvider.notifier)
                                .signInWithGoogle();
                          },
                    icon: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : SizedBox(
                            width: 24,
                            height: 24,
                            child: SvgPicture.asset(
                              Assets.googleLogo,
                              fit: BoxFit.contain,
                            ),
                          ),
                    label: Text(
                      'Login/Signup',
                      style: AppTheme.title16.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
