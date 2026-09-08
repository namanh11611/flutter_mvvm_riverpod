import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:flutter_mvvm_riverpod/core/extensions/build_context_extension.dart';
import 'package:flutter_mvvm_riverpod/generated/locale_keys.g.dart';
import 'package:flutter_mvvm_riverpod/core/theme/app_theme.dart';
import 'package:flutter_mvvm_riverpod/features/common/ui/widgets/material_ink_well.dart';

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
