import 'package:flutter/material.dart';

import '/theme/app_colors.dart';
import '/theme/app_theme.dart';
import 'material_ink_well.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final Function() onPressed;
  final Widget? icon;
  final Color? textColor;
  final Color? backgroundColor;
  final double verticalPadding;
  final bool isEnable;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.textColor,
    this.backgroundColor,
    this.verticalPadding = 14,
    this.isEnable = true,
  });

  @override
  Widget build(BuildContext context) {
    final txtColor = textColor ?? AppColors.mono0;
    final bgColor = backgroundColor ?? AppColors.blueberry100;
    return Container(
      height: 48,
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
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          child: icon != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    icon!,
                    const SizedBox(width: 8),
                    Text(
                      text,
                      style: AppTheme.title14.copyWith(
                        color: isEnable ? txtColor : AppColors.mono60,
                      ),
                    ),
                  ],
                )
              : Text(
                  text,
                  style: AppTheme.title14.copyWith(
                    color: isEnable ? txtColor : AppColors.mono60,
                  ),
                ),
        ),
      ),
    );
  }
}
