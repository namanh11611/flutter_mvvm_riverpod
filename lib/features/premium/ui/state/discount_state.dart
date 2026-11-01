import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../model/product.dart';

part 'discount_state.freezed.dart';

@freezed
abstract class DiscountState with _$DiscountState {
  const factory DiscountState({
    required Product product,
    required String originalPrice,
    required String discountedPrice,
    Package? annualPackage,
    bool? isPurchaseSuccessfully,
    bool? isRestoreSuccessfully,
  }) = _DiscountState;
}
