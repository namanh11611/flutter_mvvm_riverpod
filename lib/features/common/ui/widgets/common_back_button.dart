import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'circle_outline_button.dart';

class CommonBackButton extends StatelessWidget {
  final Function()? onBack;
  final Color? color;

  const CommonBackButton({
    super.key,
    this.onBack,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CircleOutlineButton(
      icon: HugeIcons.strokeRoundedArrowLeft01,
      color: color,
      onPressed: onBack ??
          () {
            context.pop();
          },
    );
  }
}
