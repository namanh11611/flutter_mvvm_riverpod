import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../extensions/build_context_extension.dart';

class CommonRoundedItem extends ConsumerWidget {
  final Widget child;
  final bool isFirst;
  final bool isLast;

  const CommonRoundedItem({
    super.key,
    required this.child,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: context.secondaryWidgetColor,
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: context.dividerColor),
        ),
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(16) : Radius.zero,
          bottom: isLast ? const Radius.circular(16) : Radius.zero,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: child,
    );
  }
}
