import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/constants/assets.dart';
import '/constants/constants.dart';
import '/extensions/build_context_extension.dart';
import '/main.dart';
import '/routing/routes.dart';
import '/theme/app_theme.dart';
import '/utils/global_loading.dart';
import '/utils/validator.dart';
import '../../common/ui/widgets/common_text_form_field.dart';
import '../../common/ui/widgets/primary_button.dart';
import '../../profile/ui/view_model/profile_view_model.dart';
import 'view_model/authentication_view_model.dart';
import 'widgets/horizontal_divider.dart';
import 'widgets/sign_in_agreement.dart';
import 'widgets/social_sign_in.dart';

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
        context.go(Routes.main);
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

      if (next is AsyncError) {
        context.showErrorSnackBar(next.error.toString());
      }

      if (next is AsyncData) {
        debugPrint(
            '${Constants.tag} [WelcomeScreen.build] isRegisterSuccessfully = ${next.value?.isRegisterSuccessfully}, isSignInSuccessfully = ${next.value?.isSignInSuccessfully}');
        if (next.value?.isRegisterSuccessfully == true) {
          context.pushReplacement(Routes.onboarding);
        } else if (next.value?.isSignInSuccessfully == true) {
          context.pushReplacement(Routes.main);
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
                style: AppTheme.title32,
              ),
              const SizedBox(height: 24),
              CommonTextFormField(
                label: 'Email',
                controller: _emailController,
                validator: notEmptyEmailValidator,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                isEnable: _isEmailValid,
                text: 'continue'.tr(),
                onPressed: () {
                  ref
                      .read(authenticationViewModelProvider.notifier)
                      .signInWithMagicLink(_emailController.text);
                  context.push(
                    Routes.otp,
                    extra: {
                      'email': _emailController.text,
                      'isRegister': true,
                    },
                  );
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'already_have_account'.tr(),
                    style: AppTheme.body14,
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () {
                      context.push(Routes.login);
                    },
                    child: Text(
                      'sign_in'.tr(),
                      style: AppTheme.title14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const HorizontalDivider(),
              const SizedBox(height: 16),
              const SocialSignIn(),
              const SizedBox(height: 16),
              const SignInAgreement(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
