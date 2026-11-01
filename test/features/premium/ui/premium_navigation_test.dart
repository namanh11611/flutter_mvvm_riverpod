import 'dart:math';

import 'package:flutter_mvvm_riverpod/features/premium/ui/premium_navigation.dart';
import 'package:flutter_mvvm_riverpod/routing/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PremiumNavigation.routePath', () {
    test('maps premium to Routes.premium', () {
      expect(
        PremiumNavigation.routePath(PremiumScreenOption.premium),
        Routes.premium,
      );
      expect(
        PremiumNavigation.routePath(PremiumScreenOption.premium),
        '/premium',
      );
    });

    test('maps shortPeriod to Routes.shortPeriodPremium', () {
      expect(
        PremiumNavigation.routePath(PremiumScreenOption.shortPeriod),
        Routes.shortPeriodPremium,
      );
      expect(
        PremiumNavigation.routePath(PremiumScreenOption.shortPeriod),
        '/shortPeriodPremium',
      );
    });

    test('maps discount to Routes.discountPremium', () {
      expect(
        PremiumNavigation.routePath(PremiumScreenOption.discount),
        Routes.discountPremium,
      );
      expect(
        PremiumNavigation.routePath(PremiumScreenOption.discount),
        '/discountPremium',
      );
    });
  });

  group('PremiumNavigation.pickSplashOffer', () {
    test('Android / non-iOS always returns premium', () {
      // Random ignored on non-iOS; seed that would otherwise vary.
      expect(
        PremiumNavigation.pickSplashOffer(
          isIOS: false,
          random: Random(0),
        ),
        PremiumScreenOption.premium,
      );
      expect(
        PremiumNavigation.pickSplashOffer(
          isIOS: false,
          random: Random(99),
        ),
        PremiumScreenOption.premium,
      );
    });

    test('iOS returns premium, shortPeriod, discount for nextInt indices', () {
      // Random(8): nextInt(3) sequence is 0, 1, 2
      final random = Random(8);
      expect(
        PremiumNavigation.pickSplashOffer(isIOS: true, random: random),
        PremiumScreenOption.premium,
      );
      expect(
        PremiumNavigation.pickSplashOffer(isIOS: true, random: random),
        PremiumScreenOption.shortPeriod,
      );
      expect(
        PremiumNavigation.pickSplashOffer(isIOS: true, random: random),
        PremiumScreenOption.discount,
      );
    });

    test('iOS uniform distribution over large N', () {
      final random = Random(42);
      const n = 3000;
      final counts = <PremiumScreenOption, int>{
        PremiumScreenOption.premium: 0,
        PremiumScreenOption.shortPeriod: 0,
        PremiumScreenOption.discount: 0,
      };
      for (var i = 0; i < n; i++) {
        final pick =
            PremiumNavigation.pickSplashOffer(isIOS: true, random: random);
        counts[pick] = counts[pick]! + 1;
      }
      expect(counts.values.every((c) => c > 0), isTrue);
      for (final count in counts.values) {
        final ratio = count / n;
        expect(ratio, greaterThanOrEqualTo(0.20));
        expect(ratio, lessThanOrEqualTo(0.45));
      }
    });
  });

  group('PremiumNavigation.pickAfterPremiumClose', () {
    test('iOS returns null (no follow-up)', () {
      expect(
        PremiumNavigation.pickAfterPremiumClose(
          isIOS: true,
          random: Random(0),
        ),
        isNull,
      );
      expect(
        PremiumNavigation.pickAfterPremiumClose(
          isIOS: true,
          random: Random(1),
        ),
        isNull,
      );
    });

    test('Android returns shortPeriod when nextBool is true', () {
      // Random(1): first nextBool() == true
      expect(
        PremiumNavigation.pickAfterPremiumClose(
          isIOS: false,
          random: Random(1),
        ),
        PremiumScreenOption.shortPeriod,
      );
    });

    test('Android returns discount when nextBool is false', () {
      // Random(0): first nextBool() == false
      expect(
        PremiumNavigation.pickAfterPremiumClose(
          isIOS: false,
          random: Random(0),
        ),
        PremiumScreenOption.discount,
      );
    });

    test('Android 50/50 over large N', () {
      final random = Random(42);
      const n = 2000;
      var shortPeriod = 0;
      var discount = 0;
      for (var i = 0; i < n; i++) {
        final pick = PremiumNavigation.pickAfterPremiumClose(
          isIOS: false,
          random: random,
        );
        expect(pick, isNotNull);
        expect(pick, isNot(PremiumScreenOption.premium));
        if (pick == PremiumScreenOption.shortPeriod) {
          shortPeriod++;
        } else if (pick == PremiumScreenOption.discount) {
          discount++;
        }
      }
      expect(shortPeriod + discount, n);
      final shortRatio = shortPeriod / n;
      final discountRatio = discount / n;
      expect(shortRatio, greaterThanOrEqualTo(0.35));
      expect(shortRatio, lessThanOrEqualTo(0.65));
      expect(discountRatio, greaterThanOrEqualTo(0.35));
      expect(discountRatio, lessThanOrEqualTo(0.65));
    });
  });
}
