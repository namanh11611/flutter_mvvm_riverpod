import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '/extensions/build_context_extension.dart';
import 'circle_outline_button.dart';

class CommonCloseButton extends StatelessWidget {
  final Function()? onClose;
  final Color? color;

  const CommonCloseButton({super.key, this.onClose, this.color});

  @override
  Widget build(BuildContext context) {
    return CircleOutlineButton(
      icon: HugeIcon(
        icon: HugeIcons.strokeRoundedCancel01,
        color: color ?? context.primaryTextColor,
        size: 24,
      ),
      color: color,
      onPressed:
          onClose ??
          () {
            context.pop();
          },
    );
  }
}
