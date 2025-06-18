import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/assets.dart';
import '../../../features/authentication/ui/view_model/authentication_view_model.dart';
import '../../../features/authentication/ui/widgets/horizontal_divider.dart';
import '../../../features/authentication/ui/widgets/social_sign_in.dart';
import '../../../features/common/ui/widgets/common_back_button.dart';
import '../../../features/common/ui/widgets/common_text_form_field.dart';
import '../../../features/common/ui/widgets/primary_button.dart';
import '../../../routing/routes.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/validator.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  late final TextEditingController _emailController;
  bool _isEmailValid = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _emailController.addListener(_validateEmail);
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateEmail);
    _emailController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    setState(() {
      _isEmailValid = isValidEmail(_emailController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SvgPicture.asset(
                      Assets.login,
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.bottomCenter,
                      semanticsLabel: 'Sign in',
                    ),
                  ),
                  Text(
                    'sign_in'.tr(),
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
                          'isRegister': false,
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const HorizontalDivider(),
                  const SizedBox(height: 16),
                  const SocialSignIn(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: CommonBackButton(),
            ),
          ],
        ),
      ),
    );
  }
}
