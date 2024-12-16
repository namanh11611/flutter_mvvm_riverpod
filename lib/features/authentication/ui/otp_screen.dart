import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pinput/pinput.dart';

import '../../../constants/assets.dart';
import '../../../extensions/build_context_extension.dart';
import '../../../features/authentication/ui/view_models/authentication_view_model.dart';
import '../../../features/common/ui/widgets/common_back_button.dart';
import '../../../features/common/ui/widgets/primary_button.dart';
import '../../../theme/app_theme.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String email;
  final bool isRegister;

  const OtpScreen({
    super.key,
    required this.email,
    required this.isRegister,
  });

  @override
  ConsumerState createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  late final TextEditingController otpController;
  late Timer _timer;
  int count = 60;
  bool isEnableResendButton = false;

  @override
  void initState() {
    super.initState();
    otpController = TextEditingController();
    startTimer();
  }

  @override
  void dispose() {
    otpController.dispose();
    _timer.cancel();
    super.dispose();
  }

  void startTimer() {
    isEnableResendButton = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (count == 0) {
          count = 60;
          isEnableResendButton = true;
          timer.cancel();
        } else {
          count--;
        }
      });
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
                      Assets.otp,
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.bottomCenter,
                      semanticsLabel: 'OTP',
                    ),
                  ),
                  Text(
                    'otp_enter_title'.tr(),
                    style: AppTheme.titleLarge20,
                  ),
                  Text(
                    'otp_enter_description'.tr(),
                    style: AppTheme.bodyLarge16,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Pinput(
                      length: 6,
                      controller: otpController,
                      defaultPinTheme: PinTheme(
                        width: 48,
                        height: 48,
                        textStyle: AppTheme.bodyLarge16,
                        decoration: BoxDecoration(
                          border: Border.all(color: context.secondaryTextColor),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'did_not_receive_otp'.tr(),
                        style: AppTheme.bodyMedium14.copyWith(
                          color: context.secondaryTextColor,
                        ),
                      ),
                      TextButton(
                        onPressed: isEnableResendButton
                            ? () async {
                                otpController.clear();
                                await ref
                                    .read(authenticationViewModelProvider
                                        .notifier)
                                    .signInWithMagicLink(widget.email);
                                startTimer();
                              }
                            : null,
                        child: Text(
                          'resend_otp'.tr(),
                          style: AppTheme.titleTiny12,
                        ),
                      ),
                    ],
                  ),
                  count < 60
                      ? Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 32),
                          child: Text(
                            'try_again_after',
                            style: AppTheme.bodyMedium14.copyWith(
                              color: context.secondaryTextColor,
                            ),
                          ).tr(args: ['$count']),
                        )
                      : const SizedBox(height: 68),
                  PrimaryButton(
                    text: 'confirm'.tr(),
                    isEnable: otpController.text.length == 6,
                    onPressed: () => ref
                        .read(authenticationViewModelProvider.notifier)
                        .verifyOtp(
                          email: widget.email,
                          token: otpController.text,
                          isRegister: widget.isRegister,
                        ),
                  ),
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
