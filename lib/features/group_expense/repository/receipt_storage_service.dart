abstract interface class ReceiptStorageService {
  Future<String> uploadExpenseReceipt(
      {required String tripId,
      required String expenseId,
      required String sourcePath});
  Future<String> uploadSettlementReceipt(
      {required String tripId,
      required String settlementId,
      required String sourcePath});
  Future<void> deleteReceipt(String objectPath);
  Future<String> createSignedUrl(String objectPath);
}
