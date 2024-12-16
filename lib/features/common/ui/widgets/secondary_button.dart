import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../extensions/build_context_extension.dart';
import '../../../../features/common/ui/widgets/material_ink_well.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';

class SecondaryButton extends ConsumerWidget {
  final String text;
  final Function() onPressed;
  final Widget? icon;
  final Color? textColor;
  final Color? backgroundColor;
  final double verticalPadding;
  final bool isEnable;

  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.textColor,
    this.backgroundColor,
    this.verticalPadding = 12,
    this.isEnable = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txtColor = textColor ?? context.primaryTextColor;
    final bgColor = backgroundColor ?? Colors.transparent;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isEnable ? bgColor : AppColors.mono20,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isEnable ? txtColor : AppColors.mono20,
          width: 2,
        ),
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
                      style: AppTheme.titleExtraSmall14.copyWith(
                        color: isEnable ? txtColor : AppColors.mono40,
                      ),
                    ),
                  ],
                )
              : Text(
                  text,
                  style: AppTheme.titleExtraSmall14.copyWith(
                    color: isEnable ? txtColor : AppColors.mono40,
                  ),
                ),
        ),
      ),
    );
  }
}
