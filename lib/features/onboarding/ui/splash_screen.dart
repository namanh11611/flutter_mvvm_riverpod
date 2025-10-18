import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/constants.dart';
import '../../../routing/routes.dart';
import '../../authentication/repository/authentication_repository.dart';
import '../../common/ui/widgets/loading.dart';

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
      body: Center(
        child: Loading(),
      ),
    );
  }

  Future<void> _checkLoginStatus() async {
    final authRepo = ref.read(authenticationRepositoryProvider);
    final isLoggedIn = await authRepo.isLogin();
    final hasCompletedOnboarding = await authRepo.hasCompletedOnboarding();
    
    debugPrint('${Constants.tag} [SplashScreen._checkLoginStatus] isLoggedIn = $isLoggedIn, hasCompletedOnboarding = $hasCompletedOnboarding');
    
    await authRepo.setHasCompletedOnboarding(false);
    
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    
    if (!hasCompletedOnboarding) {
      debugPrint('${Constants.tag} [SplashScreen] Navigating to onboarding flow (onboarding not completed)');
      context.pushReplacement(Routes.onboardingFlow);
    } else if (isLoggedIn) {
      debugPrint('${Constants.tag} [SplashScreen] Navigating to main (user is logged in)');
      context.pushReplacement(Routes.main);
    } else {
      debugPrint('${Constants.tag} [SplashScreen] Navigating to register (onboarding completed, not logged in)');
      context.pushReplacement(Routes.register);
    }
  }
}
