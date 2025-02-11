import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../model/product.dart';

part 'premium_state.freezed.dart';

@freezed
class PremiumState with _$PremiumState {
  const factory PremiumState({
    required List<Product> products,
    required int selectedIndex,
    List<Package>? availablePackages,
    bool? isPurchaseSuccessfully,
    bool? isRestoreSuccessfully,
  }) = _PremiumState;
}
