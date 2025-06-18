import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../extensions/build_context_extension.dart';
import '../../../../features/common/ui/widgets/material_ink_well.dart';
import '../../../../features/profile/model/language.dart';
import '../../../../features/profile/ui/widgets/common_rounded_item.dart';
import '../../../../theme/app_theme.dart';

class LanguageItem extends ConsumerWidget {
  final Language language;
  final bool isFirst;
  final bool isLast;

  const LanguageItem({
    super.key,
    required this.language,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CommonRoundedItem(
      isFirst: isFirst,
      isLast: isLast,
      child: MaterialInkWell(
        onTap: () {
          context.setLocale(Locale(language.code));
        },
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
              Expanded(
                child: Container(
                  height: 60,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    language.name,
                    style: AppTheme.body16,
                  ),
                ),
              ),
              if (language.code == context.locale.languageCode)
                Icon(HugeIcons.strokeRoundedTick01),
            ],
          ),
        ),
      ),
    );
  }
}
