import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../model/product.dart';

part 'short_period_state.freezed.dart';

@freezed
abstract class ShortPeriodState with _$ShortPeriodState {
  const factory ShortPeriodState({
    required Product product,
    Package? weeklyPackage,
    bool? isPurchaseSuccessfully,
    bool? isRestoreSuccessfully,
  }) = _ShortPeriodState;
}
