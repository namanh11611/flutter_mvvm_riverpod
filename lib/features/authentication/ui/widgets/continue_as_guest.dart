import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../extensions/build_context_extension.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../../theme/app_theme.dart';
import '../../../common/ui/widgets/material_ink_well.dart';

class ContinueAsGuest extends StatelessWidget {
  final VoidCallback onClick;

  const ContinueAsGuest({
    super.key,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialInkWell(
      radius: 24,
      onTap: onClick,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 16,
        ),
        child: Text(
          LocaleKeys.continueAsGuest.tr(),
          style: AppTheme.title14.copyWith(
            color: context.secondaryTextColor,
          ),
        ),
      ),
    );
  }
}
