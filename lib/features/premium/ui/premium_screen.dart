import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/assets.dart';
import '../../../constants/languages.dart';
import '../../../extensions/build_context_extension.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/global_loading.dart';
import '../../common/ui/widgets/common_close_button.dart';
import '../../common/ui/widgets/primary_button.dart';
import 'view_model/premium_view_model.dart';
import 'widgets/benefit_item.dart';
import 'widgets/premium_agreement.dart';
import 'widgets/product_item.dart';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(premiumViewModelProvider, (previous, next) {
      if (previous != next) {
        if (next.isLoading) {
          Global.showLoading(context);
        } else {
          Global.hideLoading();
        }
      }

      if (next is AsyncError) {
        context.showErrorSnackBar(next.error.toString());
      }

      if (next is AsyncData) {
        if (next.value?.isPurchaseSuccessfully == true) {
          context.showSuccessSnackBar(Languages.purchaseSuccess);
          context.pop();
        }
        if (next.value?.isRestoreSuccessfully == true) {
          context.showSuccessSnackBar(Languages.restorePurchasesSuccess);
          context.pop();
        } else if (next.value?.isRestoreSuccessfully == false) {
          context.showWarningSnackBar(Languages.noActivePurchases);
        }
      }
    });

    final premiumState = ref.watch(premiumViewModelProvider);
    final products = premiumState.value?.products ?? defaultProducts;
    final selectedIndex = premiumState.value?.selectedIndex ?? 1;

    return Scaffold(
      backgroundColor: AppColors.premiumBackground,
      body: Stack(
        children: [
          Image(image: AssetImage(Assets.premiumBackground)),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.gradient20,
                  AppColors.gradient40,
                  AppColors.gradient100,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(width: 36),
                      Text(
                        Languages.premium,
                        style: AppTheme.title32.copyWith(
                          color: AppColors.mono0,
                        ),
                      ),
                      CommonCloseButton(color: AppColors.mono0),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 256),
                    children: [
                      Text(
                        Languages.premiumBenefits,
                        style: AppTheme.title24.copyWith(
                          color: AppColors.mono0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.mono100.withAlpha(220),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          spacing: 16,
                          children: benefits
                              .map((benefit) => BenefitItem(
                                    icon: benefit.icon,
                                    title: benefit.title,
                                    description: benefit.description,
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        Languages.selectPlan,
                        style: AppTheme.title24.copyWith(
                          color: AppColors.mono0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        spacing: 16,
                        children: products
                            .mapIndexed(
                              (index, product) => ProductItem(
                                product: product,
                                isSelected: selectedIndex == index,
                                onTap: () => ref
                                    .read(premiumViewModelProvider.notifier)
                                    .selectProduct(index),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '* ${products[selectedIndex].description}',
                        style: AppTheme.body14.copyWith(
                          color: AppColors.mono20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Languages.subscriptionInfo,
                        style: AppTheme.body14.copyWith(
                          color: AppColors.mono0,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                      const SizedBox(height: 8),
                      PremiumAgreement(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                MediaQuery.paddingOf(context).bottom + 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.gradient0,
                    AppColors.gradient100,
                    AppColors.gradient100,
                    AppColors.gradient100,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(
                    text: Languages.continueText,
                    onPressed: () =>
                        ref.read(premiumViewModelProvider.notifier).purchase(),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => ref
                        .read(premiumViewModelProvider.notifier)
                        .restorePurchases(),
                    child: Text(
                      Languages.restorePurchases,
                      style: AppTheme.title14.copyWith(
                        color: AppColors.mono0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
