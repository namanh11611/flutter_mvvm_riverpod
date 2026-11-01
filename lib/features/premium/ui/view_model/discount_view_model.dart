import 'package:easy_localization/easy_localization.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../constants/constants.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../profile/ui/view_model/profile_view_model.dart';
import '../../model/product.dart';
import '../state/discount_state.dart';

part 'discount_view_model.g.dart';

final Product defaultAnnualProduct = Product(
  title: LocaleKeys.annual.tr(),
  description: LocaleKeys.annualDescription.tr(),
  currentPrice: '\$19.99',
  savePercent: 50,
  identifier: Constants.premiumAnnual,
);

@riverpod
class DiscountViewModel extends _$DiscountViewModel {
  @override
  FutureOr<DiscountState> build() async {
    final defaultState = DiscountState(
      product: defaultAnnualProduct,
      originalPrice: '\$19.99',
      discountedPrice: '\$9.99',
    );
    try {
      final Offerings offerings = await Purchases.getOfferings();
      final availablePackages = offerings.current?.availablePackages;

      if (availablePackages == null) {
        return defaultState;
      }

      final annualPackage = availablePackages
          .where((p) => p.identifier == Constants.premiumAnnualDiscount50)
          .firstOrNull;

      if (annualPackage == null) {
        return defaultState;
      }

      final originalPrice = annualPackage.storeProduct.priceString;
      final discountedPrice =
          annualPackage.storeProduct.introductoryPrice?.priceString ?? "";

      return DiscountState(
        product: defaultAnnualProduct.copyWith(
          currentPrice: discountedPrice,
        ),
        originalPrice: originalPrice,
        discountedPrice: discountedPrice,
        annualPackage: annualPackage,
      );
    } catch (error) {
      return defaultState;
    }
  }

  Future<void> purchase() async {
    state = const AsyncValue.loading();
    try {
      final currentState = state.value!;
      if (currentState.annualPackage == null) {
        state =
            AsyncError(LocaleKeys.fetchOfferingsError.tr(), StackTrace.current);
        return;
      }

      final purchaseResult = await Purchases.purchase(
          PurchaseParams.package(currentState.annualPackage!));
      await ref.read(profileViewModelProvider.notifier).refreshProfile();

      state = AsyncData(currentState.copyWith(
        isPurchaseSuccessfully:
            purchaseResult.customerInfo.entitlements.active.isNotEmpty,
      ));
    } catch (error) {
      state = AsyncError(LocaleKeys.purchaseError.tr(), StackTrace.current);
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
      state =
          AsyncError(LocaleKeys.restorePurchasesError.tr(), StackTrace.current);
      rethrow;
    }
  }
}
