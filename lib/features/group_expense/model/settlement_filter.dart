import 'settlement.dart';

enum SettlementFilter { all, pending, completed, rejected }

class SettlementFilterHelper {
  SettlementFilterHelper._();

  static List<Settlement> apply({
    required List<Settlement> settlements,
    required SettlementFilter filter,
    required String query,
    required String Function(String userId) travellerName,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    return settlements.where((settlement) {
      final matchesFilter = filter == SettlementFilter.all ||
          settlement.status.name == filter.name;
      if (!matchesFilter) return false;
      if (normalizedQuery.isEmpty) return true;
      final payer = travellerName(settlement.payerId).toLowerCase();
      final payee = travellerName(settlement.payeeId).toLowerCase();
      return payer.contains(normalizedQuery) || payee.contains(normalizedQuery);
    }).toList(growable: false);
  }
}
