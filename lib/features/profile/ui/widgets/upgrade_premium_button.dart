import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../../routing/routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../../common/ui/widgets/material_ink_well.dart';

class UpgradePremiumButton extends StatelessWidget {
  final String source;
  final bool isShowText;

  const UpgradePremiumButton({
    super.key,
    this.source = "",
    this.isShowText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cempedak80,
            AppColors.cempedak60,
            AppColors.cempedak100,
          ],
        ),
      ),
      child: MaterialInkWell(
        onTap: () async {
          if (context.mounted) {
            context.push(Routes.premium);
          }
        },
        radius: 24,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: isShowText ? 8 : 12,
            horizontal: isShowText ? 32 : 12,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedCrown02,
                color: AppColors.mono0,
                size: 24,
              ),
              if (isShowText)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    context.tr(LocaleKeys.premium),
                    style: AppTheme.title16.copyWith(
                      color: AppColors.mono0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
