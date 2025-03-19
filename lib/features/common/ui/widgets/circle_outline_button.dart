import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '/extensions/build_context_extension.dart';
import 'material_ink_well.dart';

class CircleOutlineButton extends ConsumerWidget {
  final IconData icon;
  final Function()? onPressed;
  final Color? color;

  const CircleOutlineButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconColor = color ?? context.primaryTextColor;
    return MaterialInkWell(
      onTap: onPressed,
      radius: 18,
      child: SizedBox(
        width: 36,
        height: 36,
        child: HugeIcon(
          icon: icon,
          color: iconColor,
          size: 24,
        ),
      ),
    );
  }
}
