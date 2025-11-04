import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '/constants/constants.dart';
import '/extensions/build_context_extension.dart';
import '/generated/locale_keys.g.dart';
import '/theme/app_colors.dart';
import '/theme/app_theme.dart';

class PremiumAgreement extends StatelessWidget {
  const PremiumAgreement({super.key});

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.justify,
      text: TextSpan(
        style: AppTheme.body14.copyWith(color: AppColors.mono0),
        children: [
          TextSpan(text: LocaleKeys.premiumAgreementPrefix.tr()),
          TextSpan(
            text: LocaleKeys.termOfService.tr(),
            style: AppTheme.title14,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                context.tryLaunchUrl(Constants.termOfService);
              },
          ),
          TextSpan(text: LocaleKeys.premiumAgreementMiddle.tr()),
          TextSpan(
            text: LocaleKeys.privacyPolicy.tr(),
            style: AppTheme.title14,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                context.tryLaunchUrl(Constants.privacyPolicy);
              },
          ),
          TextSpan(text: LocaleKeys.signInAgreementSuffix.tr()),
        ],
      ),
    );
  }
}
