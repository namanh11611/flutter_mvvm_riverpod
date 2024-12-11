import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/constants/assets.dart';
import 'package:flutter_mvvm_riverpod/features/authentication/ui/view_models/authentication_view_model.dart';
import 'package:flutter_mvvm_riverpod/features/common/ui/widgets/secondary_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SignInWithGoogle extends ConsumerWidget {
  const SignInWithGoogle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SecondaryButton(
      icon: SizedBox(
        width: 32,
        height: 32,
        child: SvgPicture.asset(
          Assets.googleLogo,
          fit: BoxFit.contain,
        ),
      ),
      text: Platform.isIOS ? 'google'.tr() : 'sign_in_with_google'.tr(),
      onPressed: () =>
          ref.read(authenticationViewModelProvider.notifier).signInWithGoogle(),
    );
  }
}
