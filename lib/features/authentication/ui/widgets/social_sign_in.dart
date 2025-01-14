import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../features/authentication/ui/widgets/sign_in_with_apple.dart';
import '../../../../features/authentication/ui/widgets/sign_in_with_google.dart';

class SocialSignIn extends StatelessWidget {
  const SocialSignIn({super.key});

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;
    return Row(
      children: [
        Expanded(
          child: SignInWithGoogle(),
        ),
        if (isIOS) const SizedBox(width: 16),
        if (isIOS)
          Expanded(
            child: SignInWithApple(),
          ),
      ],
    );
  }
}
