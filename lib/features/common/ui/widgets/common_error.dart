import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../extensions/build_context_extension.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';

class CommonError extends StatelessWidget {
  const CommonError({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          const Icon(
            Icons.error,
            size: 60,
            color: AppColors.rambutan100,
          ),
          const SizedBox(height: 16),
          Text(
            'oops_something_unexpected_happened'.tr(),
            style: AppTheme.bodyMedium14.copyWith(
              color: context.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
