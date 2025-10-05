import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../authentication/repository/authentication_repository.dart';
import '../model/onboarding_state.dart';
import '../view_model/onboarding_view_model.dart';
import 'widgets/intro_pages_widget.dart';
import 'widgets/invite_code_screen.dart';
import 'widgets/username_screen.dart';
import 'widgets/account_type_screen.dart';

class OnboardingFlowScreen extends ConsumerWidget {
  const OnboardingFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingViewModelProvider);

    // Handle completion
    ref.listen<OnboardingState>(onboardingViewModelProvider, (previous, next) {
      if (next.currentStep == OnboardingStep.completed) {
        // Mark ompleted
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
      case OnboardingStep.accountType:
        return const AccountTypeScreen();
      case OnboardingStep.completed:
        return const SizedBox.shrink();
    }
  }
}
