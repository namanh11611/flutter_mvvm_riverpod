import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/constants/assets.dart';
import 'package:flutter_mvvm_riverpod/extensions/build_context_extension.dart';
import 'package:flutter_mvvm_riverpod/features/common/ui/widgets/primary_button.dart';
import 'package:flutter_mvvm_riverpod/features/common/ui/widgets/secondary_button.dart';
import 'package:flutter_mvvm_riverpod/features/authentication/ui/view_models/welcome_view_model.dart';
import 'package:flutter_mvvm_riverpod/routing/routes.dart';
import 'package:flutter_mvvm_riverpod/theme/app_theme.dart';
import 'package:flutter_mvvm_riverpod/utils/global_loading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIOS = Platform.isIOS;

    ref.listen(welcomeViewModelProvider, (previous, next) {
      if (next.isLoading != previous?.isLoading) {
        if (next.isLoading == true) {
          Global.showLoading(context);
        } else {
          Global.hideLoading();
        }
      }

      if (next.value?.isLoginWithGoogleSuccessfully == true ||
          next.value?.isLoginWithAppleSuccessfully == true) {
        context.push(Routes.home);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 24,
                top: 48,
                right: 24,
              ),
              child: Text(
                'welcome'.tr(),
                style: AppTheme.headLineLarge32,
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: SvgPicture.asset(
                Assets.welcome,
                fit: BoxFit.contain,
                semanticsLabel: 'Welcome',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: 16,
              ),
              child: PrimaryButton(
                text: 'register'.tr(),
                onPressed: () {
                  // context.push(Routers.loginMagic, extra: true);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: 16,
              ),
              child: SecondaryButton(
                text: 'log_in'.tr(),
                onPressed: () {
                  // context.push(Routers.loginMagic, extra: false);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Divider(
                      thickness: 1,
                      color: context.dividerColor,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or'.tr(),
                      style: AppTheme.bodyMedium14
                          .copyWith(color: context.secondaryTextColor),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      thickness: 1,
                      color: context.dividerColor,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 24,
                top: 16,
                right: 24,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      icon: SizedBox(
                        width: 32,
                        height: 32,
                        child: SvgPicture.asset(
                          Assets.googleLogo,
                          fit: BoxFit.contain,
                        ),
                      ),
                      text: isIOS ? 'google'.tr() : 'sign_in_with_google'.tr(),
                      onPressed: () => ref
                          .read(welcomeViewModelProvider.notifier)
                          .loginWithGoogle(),
                    ),
                  ),
                  if (isIOS) const SizedBox(width: 16),
                  if (isIOS)
                    Expanded(
                      child: SecondaryButton(
                        icon: SizedBox(
                          width: 20,
                          height: 20,
                          child: SvgPicture.asset(
                            Assets.appleLogo,
                            fit: BoxFit.contain,
                            colorFilter: ColorFilter.mode(
                              context.secondaryTextColor,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        text: 'apple'.tr(),
                        onPressed: () => ref
                            .read(welcomeViewModelProvider.notifier)
                            .loginWithApple(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
