import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

class ShadowBox extends StatelessWidget {
  final Widget child;
  final BorderRadiusGeometry borderRadius;

  const ShadowBox({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.mono0,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.mono100.withOpacity(0.24),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
