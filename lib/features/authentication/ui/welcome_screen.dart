import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

import '../../../constants/assets.dart';
import '../../../constants/constants.dart';
import '../../../extensions/build_context_extension.dart';
import '../../../features/authentication/ui/view_models/authentication_view_model.dart';
import '../../../features/authentication/ui/widgets/horizontal_divider.dart';
import '../../../features/profile/ui/view_models/profile_view_model.dart';
import '../../../main.dart';
import '../../../routing/routes.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/global_loading.dart';
import '../../../utils/validator.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  late final TextEditingController _emailController;
  late final StreamSubscription<AuthState> _authSubscription;
  bool _isEmailValid = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _emailController.addListener(_validateEmail);

    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      debugPrint(
          '${Constants.tag} [WelcomeScreen.initState] Auth change: $event, session: $session');

      if (event == AuthChangeEvent.signedIn && session != null) {
        ref
            .read(profileViewModelProvider.notifier)
            .updateProfile(email: session.user.email ?? '');
        context.go(Routes.home);
      }
    });
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateEmail);
    _emailController.dispose();
    _authSubscription.cancel();
    super.dispose();
  }

  void _validateEmail() {
    setState(() {
      _isEmailValid = isValidEmail(_emailController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authenticationViewModelProvider, (previous, next) {
      if (next.isLoading != previous?.isLoading) {
        if (next.isLoading) {
          Global.showLoading(context);
        } else {
          Global.hideLoading();
        }
      }

      if (next.hasError) {
        context.showErrorSnackBar(next.error.toString());
      }

      if (next.hasValue) {
        debugPrint(
            '${Constants.tag} [WelcomeScreen.build] isRegisterSuccessfully = ${next.value?.isRegisterSuccessfully}, isSignInSuccessfully = ${next.value?.isSignInSuccessfully}');
        if (next.value?.isRegisterSuccessfully == true) {
          context.pushReplacement(Routes.onboarding);
        } else if (next.value?.isSignInSuccessfully == true) {
          context.pushReplacement(Routes.home);
        }
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SvgPicture.asset(
                  Assets.welcome,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.bottomCenter,
                  semanticsLabel: 'Welcome',
                ),
              ),
              Text(
                'register'.tr(),
                style: AppTheme.headLineLarge32,
              ),
              const SizedBox(height: 24),
              SupaMagicAuth(
                localization: SupaMagicAuthLocalization(
                  continueWithMagicLink: 'continue'.tr(),
                ),
                onSuccess: (session) {},
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'already_have_account'.tr(),
                    style: AppTheme.bodyMedium14,
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () {
                      context.push(Routes.login);
                    },
                    child: Text(
                      'sign_in'.tr(),
                      style: AppTheme.titleExtraSmall14,
                    ),
                  ),
                ],
              ),
              HorizontalDivider(),
              const SizedBox(height: 8),
              SupaSocialsAuth(
                socialProviders: [
                  OAuthProvider.apple,
                  OAuthProvider.google,
                ],
                onSuccess: (session) {},
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
