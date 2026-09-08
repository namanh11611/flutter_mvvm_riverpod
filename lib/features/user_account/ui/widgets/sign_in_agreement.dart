import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mvvm_riverpod/core/extensions/build_context_extension.dart';
import 'package:flutter_mvvm_riverpod/core/routing/routes.dart';
import 'package:flutter_mvvm_riverpod/core/theme/app_theme.dart';
import 'package:flutter_mvvm_riverpod/generated/locale_keys.g.dart';

class SignInAgreement extends StatelessWidget {
  const SignInAgreement({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTheme.body12.copyWith(
              color: context.secondaryTextColor,
            ),
            children: [
              TextSpan(text: '${LocaleKeys.signInAgreementPrefix.tr()} '),
              TextSpan(
                text: LocaleKeys.termsOfService.tr(),
                style: AppTheme.title12,
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    context.push(Routes.termsOfService);
                  },
              ),
              TextSpan(text: ' ${LocaleKeys.signInAgreementMiddle.tr()} '),
              TextSpan(
                text: LocaleKeys.privacyPolicy.tr(),
                style: AppTheme.title12,
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    context.push(Routes.privacyPolicy);
                  },
              ),
              TextSpan(text: ' ${LocaleKeys.signInAgreementSuffix.tr()}'),
            ],
          ),
        ),
      ),
    );
  }
}
