import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_mvvm_riverpod/features/common/presentation/widgets/material_ink_well.dart';
import 'package:flutter_mvvm_riverpod/extensions/build_context_extension.dart';
import 'package:flutter_mvvm_riverpod/theme/app_colors.dart';
import 'package:flutter_mvvm_riverpod/theme/app_theme.dart';

class SecondaryButton extends ConsumerWidget {
  final String text;
  final Function() onPressed;
  final Color? textColor;
  final Color? backgroundColor;
  final bool isEnable;

  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.textColor,
    this.backgroundColor,
    this.isEnable = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txtColor = textColor ?? context.primaryTextColor;
    final bgColor = backgroundColor ?? Colors.transparent;
    return Container(
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
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
