import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/common/ui/widgets/common_back_button.dart';
import '../../../../theme/app_theme.dart';

class CommonHeader extends ConsumerWidget {
  final String header;
  final bool isShowBack;
  final Widget? action;

  const CommonHeader({
    super.key,
    required this.header,
    this.isShowBack = true,
    this.action,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.paddingOf(context).top + 16,
        8,
        16,
      ),
      child: Row(
        children: [
          if (isShowBack) const CommonBackButton(),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              header,
              style: AppTheme.title32,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          if (action != null) action!,
        ],
      ),
    );
  }
}
