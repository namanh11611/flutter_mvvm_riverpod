import 'package:flutter_mvvm_riverpod/core/routing/router.dart';
import 'package:flutter_mvvm_riverpod/core/routing/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dashboard route accepts a UUID trip ID without integer parsing', () {
    const tripId = '8d8b36d2-10e7-43b5-a6f5-5b4df0a8df31';
    final matches = router.configuration.findMatch(
      Uri.parse('${Routes.groupExpense}/$tripId'),
    );

    expect(matches.uri.path, '${Routes.groupExpense}/$tripId');
    expect(matches.error, isNull);
  });
}
