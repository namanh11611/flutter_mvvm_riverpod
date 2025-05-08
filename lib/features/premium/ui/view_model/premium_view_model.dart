import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '/constants/constants.dart';
import '/constants/languages.dart';
import '/theme/app_colors.dart';
import '../../../profile/ui/view_model/profile_view_model.dart';
import '../../model/benefit.dart';
import '../../model/product.dart';
import '../state/premium_state.dart';

part 'premium_view_model.g.dart';

final List<Benefit> benefits = [
  Benefit(
    icon: Icon(HugeIcons.strokeRoundedAlert01, color: AppColors.mono0),
    title: Languages.benefitTitle1,
    description: Languages.benefitDescription1,
  ),
  Benefit(
    icon: Icon(HugeIcons.strokeRoundedInfinity01, color: AppColors.mono0),
    title: Languages.benefitTitle2,
    description: Languages.benefitDescription2,
  ),
  Benefit(
    icon: Icon(HugeIcons.strokeRoundedChartHistogram, color: AppColors.mono0),
    title: Languages.benefitTitle3,
    description: Languages.benefitDescription3,
  ),
];

final List<Product> defaultProducts = [
  Product(
    title: Languages.monthly,
    description: Languages.monthlyDescription,
    currentPrice: '\$0.99',
    savePercent: 34,
    identifier: Constants.premiumMonthly,
  ),
  Product(
    title: Languages.yearly,
    description: Languages.yearlyDescription,
    currentPrice: '\$9.99',
    savePercent: 38,
    label: Languages.mostPopular,
    identifier: Constants.premiumYearly,
  ),
  Product(
    title: Languages.lifetime,
    description: Languages.lifetimeDescription,
    currentPrice: '\$14.99',
    savePercent: 42,
    label: Languages.bestPrice,
    identifier: Constants.premiumLifeTime,
  ),
];

@riverpod
class PremiumViewModel extends _$PremiumViewModel {
  @override
  FutureOr<PremiumState> build() async {
    final defaultState = PremiumState(
      products: defaultProducts,
      selectedIndex: 1,
    );
    try {
      final Offerings offerings = await Purchases.getOfferings();
      final availablePackages = offerings.current?.availablePackages;

      if (availablePackages == null) {
        return defaultState;
      }

      final products = defaultProducts;
      for (var p in availablePackages) {
        switch (p.identifier) {
          case Constants.premiumMonthly:
            products[0] = products[0].copyWith(
              currentPrice: p.storeProduct.priceString,
            );
            break;
          case Constants.premiumYearly:
            products[1] = products[1].copyWith(
              currentPrice: p.storeProduct.priceString,
            );
            break;
          case Constants.premiumLifeTime:
            products[2] = products[2].copyWith(
              currentPrice: p.storeProduct.priceString,
            );
            break;
          default:
        }
      }

      return PremiumState(
        products: products,
        availablePackages: availablePackages,
        selectedIndex: 1,
      );
    } catch (error) {
      return defaultState;
    }
  }

  Future<void> purchase() async {
    state = const AsyncValue.loading();
    try {
      final currentState = state.value!;
      if (currentState.availablePackages == null) {
        state = AsyncError(Languages.fetchOfferingsError, StackTrace.current);
        return;
      }

      final product = currentState.products[currentState.selectedIndex];
      final revenueCatPackage =
          currentState.availablePackages?.firstWhereOrNull(
        (p) => p.identifier == product.identifier,
      );

      if (revenueCatPackage == null) {
        state = AsyncError(Languages.packageNotFoundError, StackTrace.current);
        return;
      }

      final customerInfo = await Purchases.purchasePackage(revenueCatPackage);
      await ref.read(profileViewModelProvider.notifier).refreshProfile();

      state = AsyncData(currentState.copyWith(
        isPurchaseSuccessfully: customerInfo.entitlements.active.isNotEmpty,
      ));
    } catch (error) {
      state = AsyncError(Languages.purchaseError, StackTrace.current);
      rethrow;
    }
  }

  Future<void> restorePurchases() async {
    state = const AsyncValue.loading();
    try {
      final customerInfo = await Purchases.restorePurchases();
      await ref.read(profileViewModelProvider.notifier).refreshProfile();

      state = AsyncData(state.value!.copyWith(
        isRestoreSuccessfully: customerInfo.entitlements.active.isNotEmpty,
      ));
    } catch (error) {
      state = AsyncError(Languages.restorePurchasesError, StackTrace.current);
      rethrow;
    }
  }

  void selectProduct(int index) {
    if (!state.isLoading) {
      state = AsyncData(state.value!.copyWith(selectedIndex: index));
    }
  }
}
