import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '/constants/constants.dart';

import '/extensions/build_context_extension.dart';
import '/generated/locale_keys.g.dart';
import '/theme/app_theme.dart';

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
                text: LocaleKeys.termOfService.tr(),
                style: AppTheme.title12,
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    context.tryLaunchUrl(Constants.termOfService);
                  },
              ),
              TextSpan(text: ' ${LocaleKeys.signInAgreementMiddle.tr()} '),
              TextSpan(
                text: LocaleKeys.privacyPolicy.tr(),
                style: AppTheme.title12,
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    context.tryLaunchUrl(Constants.privacyPolicy);
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
