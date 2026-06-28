import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/assets.dart';
import '../../../extensions/build_context_extension.dart';
import '../../../generated/locale_keys.g.dart';
import '../../../routing/routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/global_loading.dart';
import '../../common/ui/widgets/common_close_button.dart';
import '../../common/ui/widgets/primary_button.dart';
import '../../profile/ui/view_model/profile_view_model.dart';
import '../model/product.dart';
import 'view_model/premium_view_model.dart';
import 'widgets/benefit_item.dart';
import 'widgets/premium_footer.dart';
import 'widgets/product_item.dart';
import 'widgets/trial_timeline.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  final bool? isGoToMain;

  const PremiumScreen({
    super.key,
    this.isGoToMain,
  });

  @override
  ConsumerState createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(profileViewModelProvider.notifier).setIsShowPremium();
  }

  @override
  Widget build(BuildContext context) {
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
          context.showSuccessSnackBar(LocaleKeys.purchaseSuccess.tr());
          context.go(Routes.splash);
        }
        if (next.value?.isRestoreSuccessfully == true) {
          context.showSuccessSnackBar(LocaleKeys.restorePurchasesSuccess.tr());
          context.go(Routes.splash);
        } else if (next.value?.isRestoreSuccessfully == false) {
          context.showWarningSnackBar(LocaleKeys.noActivePurchases.tr());
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
          Positioned.fill(
            child: Image.asset(Assets.premiumBackground, fit: BoxFit.cover),
          ),
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
                        LocaleKeys.premium.tr(),
                        style: AppTheme.title32.copyWith(
                          color: AppColors.mono0,
                        ),
                      ),
                      CommonCloseButton(
                        onClose: _mayBackOrGoHome,
                        color: AppColors.mono0,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 128),
                    children: [
                      Text(
                        LocaleKeys.start7dayFreeTrial.tr(),
                        style: AppTheme.title18.copyWith(
                          color: AppColors.mono0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const TrialTimeline(),
                      const SizedBox(height: 24),
                      Text(
                        LocaleKeys.selectPlan.tr(),
                        style: AppTheme.title24.copyWith(
                          color: AppColors.mono0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPlans(products, selectedIndex),
                      const SizedBox(height: 8),
                      Text(
                        '* ${products[selectedIndex].description}',
                        style: AppTheme.body14.copyWith(
                          color: AppColors.mono20,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        LocaleKeys.premiumBenefits.tr(),
                        style: AppTheme.title24.copyWith(
                          color: AppColors.mono0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBenefits(),
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
                MediaQuery.paddingOf(context).bottom,
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
                    text: selectedIndex == 2
                        ? context.tr(LocaleKeys.continueText)
                        : context.tr(LocaleKeys.startFreeTrial),
                    onPressed: () =>
                        ref.read(premiumViewModelProvider.notifier).purchase(),
                  ),
                  const SizedBox(height: 2),
                  PremiumFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlans(List<Product> products, int selectedIndex) {
    return Row(
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
    );
  }

  Widget _buildBenefits() {
    return Container(
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
    );
  }

  void _mayBackOrGoHome() {
    if (widget.isGoToMain == true) {
      context.pushReplacement(Routes.main);
    } else {
      context.pop();
    }
  }
}
