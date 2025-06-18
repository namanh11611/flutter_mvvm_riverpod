import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../constants/languages.dart';
import '../../../../features/common/ui/widgets/material_ink_well.dart';
import '../../../../routing/routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';

class UpgradePremiumButton extends StatelessWidget {
  const UpgradePremiumButton({super.key});

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
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedNewReleases,
                color: AppColors.mono0,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                Languages.premium,
                style:
                    AppTheme.title14.copyWith(color: AppColors.mono0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
