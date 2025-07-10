import 'package:flutter/material.dart';

import '/theme/app_colors.dart';

class ShadowBox extends StatelessWidget {
  final Widget child;
  final double radius;

  const ShadowBox({
    super.key,
    required this.child,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.mono0,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.mono100.withAlpha(60),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
