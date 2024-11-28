import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/features/common/presentation/widgets/material_ink_well.dart';
import 'package:flutter_mvvm_riverpod/theme/app_colors.dart';
import 'package:flutter_mvvm_riverpod/theme/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final Function() onPressed;
  final Color? textColor;
  final Color? backgroundColor;
  final bool isEnable;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.textColor,
    this.backgroundColor,
    this.isEnable = true,
  });

  @override
  Widget build(BuildContext context) {
    final txtColor = textColor ?? AppColors.mono0;
    final bgColor = backgroundColor ?? AppColors.blueberry100;
    return Container(
      decoration: BoxDecoration(
        color: isEnable ? bgColor : AppColors.mono40,
        borderRadius: BorderRadius.circular(24),
      ),
      child: MaterialInkWell(
        onTap: isEnable ? onPressed : null,
        radius: 24,
        child: Container(
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            text,
            style: AppTheme.titleExtraSmall14.copyWith(
              color: isEnable ? txtColor : AppColors.mono60,
            ),
          ),
        ),
      ),
    );
  }
}
