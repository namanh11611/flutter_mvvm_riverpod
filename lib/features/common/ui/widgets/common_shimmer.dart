import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '/extensions/build_context_extension.dart';
import '/theme/app_colors.dart';

class CommonShimmer extends StatelessWidget {
  final Widget child;

  const CommonShimmer({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor:
          context.isDarkMode ? AppColors.gradient40 : AppColors.gradient10,
      highlightColor:
          context.isDarkMode ? AppColors.gradient20 : AppColors.gradient0,
      child: child,
    );
  }
}
