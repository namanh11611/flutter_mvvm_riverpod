import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/constants.dart';
import '../../../routing/routes.dart';

enum PremiumScreenOption { premium, shortPeriod, discount }

/// Platform + random offer routing.
class PremiumNavigation {
  PremiumNavigation._();

  /// iOS: uniform among Premium / ShortPeriod / Discount.
  /// Android: always Premium.
  ///
  /// [random] and [isIOS] are injectable for deterministic unit tests.
  static PremiumScreenOption pickSplashOffer({
    Random? random,
    bool? isIOS,
  }) {
    if (isIOS ?? Platform.isIOS) {
      return PremiumScreenOption.values[(random ?? Random()).nextInt(3)];
    }
    return PremiumScreenOption.premium;
  }

  /// iOS: null (no follow-up after Premium).
  /// Android: 50/50 ShortPeriod | Discount.
  ///
  /// [random] and [isIOS] are injectable for deterministic unit tests.
  static PremiumScreenOption? pickAfterPremiumClose({
    Random? random,
    bool? isIOS,
  }) {
    if (isIOS ?? Platform.isIOS) return null;
    return (random ?? Random()).nextBool()
        ? PremiumScreenOption.shortPeriod
        : PremiumScreenOption.discount;
  }

  static String routePath(PremiumScreenOption screen) {
    switch (screen) {
      case PremiumScreenOption.premium:
        return Routes.premium;
      case PremiumScreenOption.shortPeriod:
        return Routes.shortPeriodPremium;
      case PremiumScreenOption.discount:
        return Routes.discountPremium;
    }
  }

  static Future<void> open(
    BuildContext context, {
    required PremiumScreenOption screen,
    bool isGoToMain = false,
    bool replace = false,
  }) async {
    final path = routePath(screen);
    final extra = isGoToMain ? {Constants.isGoToMain: true} : null;
    if (replace) {
      context.pushReplacement(path, extra: extra);
    } else {
      await context.push(path, extra: extra);
    }
  }
}
