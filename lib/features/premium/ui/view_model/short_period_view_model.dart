import 'package:easy_localization/easy_localization.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../constants/constants.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../profile/ui/view_model/profile_view_model.dart';
import '../../model/product.dart';
import '../state/short_period_state.dart';

part 'short_period_view_model.g.dart';

final Product defaultWeeklyProduct = Product(
  title: LocaleKeys.weekly.tr(),
  description: LocaleKeys.weeklyDescription.tr(),
  currentPrice: '\$0.99',
  savePercent: 0,
  identifier: Constants.premiumWeekly,
);

@riverpod
class ShortPeriodViewModel extends _$ShortPeriodViewModel {
  @override
  FutureOr<ShortPeriodState> build() async {
    final defaultState = ShortPeriodState(
      product: defaultWeeklyProduct,
    );
    try {
      final Offerings offerings = await Purchases.getOfferings();
      final availablePackages = offerings.current?.availablePackages;

      if (availablePackages == null) {
        return defaultState;
      }

      final weeklyPackage = availablePackages
          .where((p) => p.identifier == Constants.premiumWeekly)
          .firstOrNull;

      if (weeklyPackage == null) {
        return defaultState;
      }

      return ShortPeriodState(
        product: defaultWeeklyProduct.copyWith(
          currentPrice: weeklyPackage.storeProduct.priceString,
        ),
        weeklyPackage: weeklyPackage,
      );
    } catch (error) {
      return defaultState;
    }
  }

  Future<void> purchase() async {
    state = const AsyncValue.loading();
    try {
      final currentState = state.value!;
      if (currentState.weeklyPackage == null) {
        state = AsyncError(
            LocaleKeys.fetchOfferingsError.tr(), StackTrace.current);
        return;
      }

      final purchaseResult = await Purchases.purchase(
          PurchaseParams.package(currentState.weeklyPackage!));
      await ref.read(profileViewModelProvider.notifier).refreshProfile();

      state = AsyncData(currentState.copyWith(
        isPurchaseSuccessfully:
            purchaseResult.customerInfo.entitlements.active.isNotEmpty,
      ));
    } catch (error) {
      state =
          AsyncError(LocaleKeys.purchaseError.tr(), StackTrace.current);
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
      state = AsyncError(
          LocaleKeys.restorePurchasesError.tr(), StackTrace.current);
      rethrow;
    }
  }
}
