import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../constants/assets.dart';
import '../../../../extensions/build_context_extension.dart';
import '../../../../features/authentication/ui/view_models/authentication_view_model.dart';
import '../../../../features/common/ui/widgets/secondary_button.dart';

class SignInWithApple extends ConsumerWidget {
  const SignInWithApple({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SecondaryButton(
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
      onPressed: () =>
          ref.read(authenticationViewModelProvider.notifier).signInWithApple(),
    );
  }
}
