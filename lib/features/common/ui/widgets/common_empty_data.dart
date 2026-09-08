import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:flutter_mvvm_riverpod/core/constants/assets.dart';
import 'package:flutter_mvvm_riverpod/core/extensions/build_context_extension.dart';
import 'package:flutter_mvvm_riverpod/generated/locale_keys.g.dart';
import 'package:flutter_mvvm_riverpod/core/theme/app_theme.dart';

class CommonEmptyData extends StatelessWidget {
  const CommonEmptyData({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: SvgPicture.asset(
              Assets.empty,
              fit: BoxFit.contain,
              semanticsLabel: 'Empty',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            LocaleKeys.noData.tr(),
            style: AppTheme.body14.copyWith(
              color: context.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
