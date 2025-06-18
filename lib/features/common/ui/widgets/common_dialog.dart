import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/extensions/build_context_extension.dart';
import '/theme/app_colors.dart';
import '/theme/app_theme.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

class CommonDialog extends ConsumerWidget {
  final String title;
  final String content;
  final String primaryButtonLabel;
  final Function()? primaryButtonAction;
  final Color primaryButtonBackground;
  final String? secondaryButtonLabel;
  final Function()? secondaryButtonAction;

  const CommonDialog({
    super.key,
    required this.title,
    required this.content,
    required this.primaryButtonLabel,
    this.primaryButtonAction,
    this.primaryButtonBackground = AppColors.blueberry100,
    this.secondaryButtonLabel,
    this.secondaryButtonAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.primaryBackgroundColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTheme.title20),
            const SizedBox(height: 16),
            Text(content, style: AppTheme.body14),
            const SizedBox(height: 16),
            secondaryButtonLabel != null
                ? Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          text: secondaryButtonLabel ?? '',
                          onPressed: () {
                            secondaryButtonAction?.call();
                            context.pop();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: PrimaryButton(
                          text: primaryButtonLabel,
                          backgroundColor: primaryButtonBackground,
                          onPressed: () {
                            primaryButtonAction?.call();
                            context.pop();
                          },
                        ),
                      ),
                    ],
                  )
                : PrimaryButton(
                    text: primaryButtonLabel,
                    backgroundColor: primaryButtonBackground,
                    onPressed: () {
                      primaryButtonAction?.call();
                      context.pop();
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
