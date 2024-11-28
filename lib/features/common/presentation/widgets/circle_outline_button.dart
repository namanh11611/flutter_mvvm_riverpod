import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_mvvm_riverpod/features/common/presentation/widgets/material_ink_well.dart';
import 'package:flutter_mvvm_riverpod/extensions/build_context_extension.dart';

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
        child: Icon(
          icon,
          size: 24,
          color: iconColor,
        ),
      ),
    );
  }
}
