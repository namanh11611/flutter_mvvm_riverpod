import 'package:flutter/material.dart';

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
        return const ShimmerHeroItem();
      },
    );
  }
}

class ShimmerHeroItem extends StatelessWidget {
  const ShimmerHeroItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: CommonShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Expanded(
              flex: 4,
              child: ColoredBox(
                color: Colors.white,
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
