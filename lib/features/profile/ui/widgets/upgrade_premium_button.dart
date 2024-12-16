import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../features/common/ui/widgets/material_ink_well.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';

class UpgradePremiumButton extends StatelessWidget {
  const UpgradePremiumButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: (MediaQuery.sizeOf(context).width - 140) / 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cempedak60,
            AppColors.cempedak100,
          ],
        ),
      ),
      child: MaterialInkWell(
        onTap: () {
          // context.push(Routes.premium);
        },
        radius: 24,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedNewReleases,
                color: AppColors.mono0,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Premium',
                style:
                    AppTheme.titleExtraSmall14.copyWith(color: AppColors.mono0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
