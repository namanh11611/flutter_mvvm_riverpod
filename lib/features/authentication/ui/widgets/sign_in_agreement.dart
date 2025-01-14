import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../constants/languages.dart';
import '../../../../extensions/build_context_extension.dart';
import '../../../../theme/app_theme.dart';

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
            style: AppTheme.bodySmall12.copyWith(
              color: context.secondaryTextColor,
            ),
            children: [
              TextSpan(text: '${Languages.signInAgreementPrefix} '),
              TextSpan(
                text: Languages.termOfService,
                style: AppTheme.titleTiny12,
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    context.tryLaunchUrl('https://github.com/namanh11611/flutter_mvvm_riverpod');
                  },
              ),
              TextSpan(text: ' ${Languages.signInAgreementMiddle} '),
              TextSpan(
                text: Languages.privacyPolicy,
                style: AppTheme.titleTiny12,
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    context.tryLaunchUrl('https://github.com/namanh11611/flutter_mvvm_riverpod');
                  },
              ),
              TextSpan(text: ' ${Languages.signInAgreementSuffix}'),
            ],
          ),
        ),
      ),
    );
  }
}
