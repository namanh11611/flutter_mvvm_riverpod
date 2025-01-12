import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../constants/assets.dart';
import '../../../../extensions/build_context_extension.dart';
import '../../../../theme/app_theme.dart';

class CommonEmptyData extends StatelessWidget {
  const CommonEmptyData({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          SizedBox(
            width: 100,
            height: 100,
            child: Image.asset(Assets.empty),
          ),
          const SizedBox(height: 16),
          Text(
            'no_data'.tr(),
            style: AppTheme.bodyMedium14.copyWith(
              color: context.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
