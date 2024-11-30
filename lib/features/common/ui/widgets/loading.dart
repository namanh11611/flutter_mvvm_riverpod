import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/constants/assets.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_mvvm_riverpod/theme/app_colors.dart';

class Loading extends StatelessWidget {
  const Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints.expand(),
      color: AppColors.mono100.withAlpha(175),
      child: Center(
        child: Lottie.asset(
          Assets.loading,
          width: 120,
          height: 120,
        ),
      ),
    );
  }
}
