import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../extensions/build_context_extension.dart';
import '../../../../features/common/ui/widgets/common_back_button.dart';
import '../../../../theme/app_theme.dart';

class CommonHeader extends ConsumerWidget {
  final String header;
  final bool isShowBack;

  const CommonHeader({
    super.key,
    required this.header,
    this.isShowBack = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 16,
        left: 6,
        right: 6,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: context.secondaryWidgetColor,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (isShowBack) const CommonBackButton(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              header,
              style: AppTheme.titleExtraLarge24,
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}
