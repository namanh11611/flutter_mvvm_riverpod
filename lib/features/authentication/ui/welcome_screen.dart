import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../constants/assets.dart';
import '../../../constants/constants.dart';
import '../../../extensions/build_context_extension.dart';
import '../../../generated/locale_keys.g.dart';
import '../../../main.dart';
import '../../../routing/routes.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/global_loading.dart';
import '../../profile/ui/view_model/profile_view_model.dart';
import 'view_model/authentication_view_model.dart';
import 'widgets/continue_as_guest.dart';
import 'widgets/sign_in_agreement.dart';
import 'widgets/social_sign_in.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription =
        supabase.auth.onAuthStateChange.listen(_onAuthStateChange);
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  void _onAuthStateChange(AuthState data) async {
    final AuthChangeEvent event = data.event;
    final Session? session = data.session;
    debugPrint(
        '${Constants.tag} [WelcomeScreen._onAuthStateChange] Auth change: $event, session: $session');

    if (event == AuthChangeEvent.signedIn && session != null) {
      await ref
          .read(authenticationViewModelProvider.notifier)
          .updateProfile(session.user);
      _goToNextScreen();
    }
  }

  void _logInAsGuest() async {
    await ref.read(authenticationViewModelProvider.notifier).setIsGuestMode();
    _goToNextScreen();
  }

  void _goToNextScreen() async {
    Global.hideLoading();

    final wasShowOnboarding =
        await ref.read(profileViewModelProvider.notifier).wasShowOnboarding();
    if (!wasShowOnboarding) {
      if (mounted) context.go(Routes.onboarding);
      return;
    }

    final isShowPremium =
        await ref.read(profileViewModelProvider.notifier).isShowPremium();
    if (isShowPremium) {
      if (mounted) {
        context.go(
          Routes.premium,
          extra: { Constants.isGoToMain: true },
        );
      }
      return;
    }

    if (mounted) context.go(Routes.main);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authenticationViewModelProvider, (previous, next) {
      if (next is AsyncLoading) {
        Global.showLoading(context);
      } else {
        Global.hideLoading();
      }

      if (next is AsyncError) {
        context.showErrorSnackBar(next.error.toString());
      }

      // TODO: Remove this because we only observe social login
      if (next is AsyncData) {
        if (next.value?.isSignInSuccessfully == true) {
          _goToNextScreen();
        }
      }
      // END TODO
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 48),
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  LocaleKeys.welcome.tr(),
                  style: AppTheme.title32,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  LocaleKeys.welcomeDescription.tr(),
                  style: AppTheme.body16,
                ),
              ),
              Expanded(
                child: SvgPicture.asset(
                  Assets.welcome,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.center,
                  semanticsLabel: 'Welcome',
                ),
              ),
              const SizedBox(height: 16),
              const SocialSignIn(),
              const SizedBox(height: 8),
              ContinueAsGuest(onClick: _logInAsGuest),
              const SizedBox(height: 8),
              const SignInAgreement(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
