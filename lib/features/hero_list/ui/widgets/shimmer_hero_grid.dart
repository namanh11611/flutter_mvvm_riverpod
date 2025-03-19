import 'package:flutter/material.dart';

import '/theme/app_colors.dart';
import '../../../common/ui/widgets/common_shimmer.dart';

class ShimmerHeroGrid extends StatelessWidget {
  const ShimmerHeroGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 0.8,
      ),
      itemCount: 6, // Show 6 shimmer items while loading
      itemBuilder: (context, index) {
        return CommonShimmer(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.mono0,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }
}
