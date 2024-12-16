import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../extensions/build_context_extension.dart';
import '../../../../theme/app_theme.dart';

class HorizontalDivider extends StatelessWidget {
  const HorizontalDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            thickness: 1,
            color: context.dividerColor,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or'.tr(),
            style: AppTheme.bodyMedium14
                .copyWith(color: context.secondaryTextColor),
          ),
        ),
        Expanded(
          child: Divider(
            thickness: 1,
            color: context.dividerColor,
          ),
        ),
      ],
    );
  }
}
