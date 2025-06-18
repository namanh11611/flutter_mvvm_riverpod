import 'package:flutter/material.dart';

import '/theme/app_colors.dart';
import '/theme/app_theme.dart';
import '../../../common/ui/widgets/material_ink_well.dart';
import '../../model/product.dart';

class ProductItem extends StatelessWidget {
  final Product product;
  final bool isSelected;
  final VoidCallback onTap;

  const ProductItem({
    super.key,
    required this.product,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MaterialInkWell(
        radius: 16,
        onTap: onTap,
        child: AnimatedContainer(
          padding: EdgeInsets.only(bottom: 24),
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.blueberry100.withAlpha(220)
                : AppColors.mono100.withAlpha(220),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                alignment: Alignment.topRight,
                margin: EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 8,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.rambutan80,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    '- ${product.savePercent}%',
                    style: AppTheme.body12.copyWith(
                      color: AppColors.mono0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                product.title,
                style: AppTheme.title16.copyWith(
                  color: AppColors.mono0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product.currentPrice,
                style: AppTheme.title20.copyWith(
                  color: AppColors.mono0,
                ),
              ),
              const SizedBox(height: 16),
              product.label != null
                  ? Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mono0.withAlpha(50),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        product.label!,
                        style: AppTheme.title10.copyWith(
                          color: AppColors.mono0,
                        ),
                      ),
                    )
                  : const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
