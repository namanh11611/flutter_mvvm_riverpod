import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/constants.dart';
import '../../../routing/routes.dart';
import '../../authentication/ui/view_model/authentication_view_model.dart';
import '../../common/ui/widgets/loading.dart';
import '../../premium/ui/premium_navigation.dart';
import '../../profile/ui/view_model/profile_view_model.dart';

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
    final isLoggedIn =
        await ref.read(authenticationViewModelProvider.notifier).isLogin();
    final isGuestMode =
        await ref.read(authenticationViewModelProvider.notifier).isGuestMode();
    debugPrint(
        '${Constants.tag} [SplashScreen._checkLoginStatus] isLoggedIn = $isLoggedIn, isGuestMode = $isGuestMode');
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    if (isLoggedIn || isGuestMode) {
      final shouldShow = await ref
          .read(profileViewModelProvider.notifier)
          .shouldShowPremium();
      if (!mounted) return;
      if (shouldShow) {
        final offer = PremiumNavigation.pickSplashOffer();
        await PremiumNavigation.open(
          context,
          screen: offer,
          isGoToMain: true,
          replace: true,
        );
      } else {
        context.pushReplacement(Routes.main);
      }
    } else {
      context.pushReplacement(Routes.welcome);
    }
  }
}
