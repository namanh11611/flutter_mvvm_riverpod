import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/constants.dart';
import '../../../routing/routes.dart';
import '../../authentication/repository/authentication_repository.dart';
import '../../authentication/ui/view_model/authentication_view_model.dart';
import '../model/onboarding_state.dart';
import '../view_model/onboarding_view_model.dart';
import 'widgets/intro_pages_widget.dart';
import 'widgets/invite_code_screen.dart';
import 'widgets/username_screen.dart';
import 'widgets/google_connect_screen.dart';

class OnboardingFlowScreen extends ConsumerWidget {
  const OnboardingFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingViewModelProvider);

    // Listen to authentication state for Google sign-in
    ref.listen(authenticationViewModelProvider, (previous, next) {
      debugPrint('${Constants.tag} [OnboardingFlowScreen] Auth state changed: $next');
      
      if (next is AsyncData) {
        final value = next.value;
        debugPrint('${Constants.tag} [OnboardingFlowScreen] isSignInSuccessfully: ${value?.isSignInSuccessfully}');
        debugPrint('${Constants.tag} [OnboardingFlowScreen] authResponse: ${value?.authResponse?.user?.email}');
        
        if (value?.isSignInSuccessfully == true) {
          // User signed in with Google, mark onboarding complete and go to main app
          debugPrint('${Constants.tag} [OnboardingFlowScreen] Navigating to main app');
          ref.read(authenticationRepositoryProvider).setHasCompletedOnboarding(true);
          context.pushReplacement(Routes.main);
        }
      } else if (next is AsyncError) {
        debugPrint('${Constants.tag} [OnboardingFlowScreen] Auth error: ${next.error}');
      }
    });

    // Handle completion (for users who skip Google sign-in)
    ref.listen<OnboardingState>(onboardingViewModelProvider, (previous, next) {
      if (next.currentStep == OnboardingStep.completed) {
        // Check if user is already authenticated
        final authState = ref.read(authenticationViewModelProvider);
        if (authState is AsyncData && authState.value?.isSignInSuccessfully == true) {
          // Already handled by auth listener above
          return;
        }
        
        // Mark completed and go to register screen for email/password auth
        ref.read(authenticationRepositoryProvider).setHasCompletedOnboarding(true);
        context.pushReplacement(Routes.register);
      }
    });

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildCurrentScreen(state.currentStep),
      ),
    );
  }

  Widget _buildCurrentScreen(OnboardingStep step) {
    switch (step) {
      case OnboardingStep.intro:
        return const IntroPagesWidget();
      case OnboardingStep.inviteCode:
        return const InviteCodeScreen();
      case OnboardingStep.username:
        return const UsernameScreen();
      case OnboardingStep.googleAuth:
        return const GoogleConnectScreen();
      case OnboardingStep.completed:
        return const SizedBox.shrink();
    }
  }
}
