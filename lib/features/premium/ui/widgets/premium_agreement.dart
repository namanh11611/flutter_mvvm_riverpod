import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '/constants/constants.dart';
import '/constants/languages.dart';
import '/extensions/build_context_extension.dart';
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
          TextSpan(text: Languages.premiumAgreementPrefix),
          TextSpan(
            text: Languages.termOfService,
            style: AppTheme.title14,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                context.tryLaunchUrl(Constants.termOfService);
              },
          ),
          TextSpan(text: Languages.premiumAgreementMiddle),
          TextSpan(
            text: Languages.privacyPolicy,
            style: AppTheme.title14,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                context.tryLaunchUrl(Constants.privacyPolicy);
              },
          ),
          TextSpan(text: Languages.signInAgreementSuffix),
        ],
      ),
    );
  }
}
