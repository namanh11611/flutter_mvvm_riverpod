import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../extensions/build_context_extension.dart';
import '../../../../features/common/ui/widgets/material_ink_well.dart';
import '../../../../theme/app_theme.dart';

class ProfileItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Function() onTap;
  final Color? textColor;
  final bool isShowArrow;

  const ProfileItem({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
    this.textColor,
    this.isShowArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialInkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            HugeIcon(
              icon: icon,
              color: textColor ?? context.primaryTextColor,
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: AppTheme.bodyLarge16.copyWith(color: textColor),
              ),
            ),
            if (isShowArrow)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  color: textColor ?? context.primaryTextColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
