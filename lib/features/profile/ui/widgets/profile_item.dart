import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '/extensions/build_context_extension.dart';
import '/theme/app_theme.dart';
import '../../../common/ui/widgets/material_ink_well.dart';
import 'common_rounded_item.dart';

class ProfileItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Function() onTap;
  final Color? textColor;
  final bool isShowArrow;
  final bool isFirst;
  final bool isLast;

  const ProfileItem({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
    this.textColor,
    this.isShowArrow = true,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return CommonRoundedItem(
      isFirst: isFirst,
      isLast: isLast,
      child: MaterialInkWell(
        onTap: onTap,
        child: Container(
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: isLast
                  ? BorderSide.none
                  : BorderSide(color: context.dividerColor),
            ),
          ),
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
                  style: AppTheme.body16.copyWith(color: textColor),
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
      ),
    );
  }
}
