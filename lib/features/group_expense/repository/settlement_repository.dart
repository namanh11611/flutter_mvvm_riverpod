import '../model/settlement.dart';
import '../model/settlement_receipt.dart';

abstract interface class SettlementRepository {
  Future<List<Settlement>> getSettlementsForTrip(String tripId);
  Future<String> createSettlement(
    Settlement settlement, {
    SettlementReceipt? receipt,
  });
  Future<void> updateSettlement(
    Settlement settlement, {
    SettlementReceipt? receipt,
    bool removeReceipt = false,
  });
  Future<void> deleteSettlement(String tripId, String settlementId);
  Future<SettlementReceipt?> getReceipt(String tripId, String settlementId);
  Future<Map<String, SettlementReceipt>> getReceiptsForTrip(String tripId);
  Future<List<Settlement>> getCompletedSettlements(String tripId);
  Future<List<Settlement>> getPendingSettlements(String tripId);
}
