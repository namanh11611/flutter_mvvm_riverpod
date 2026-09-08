abstract interface class ReceiptFileService {
  Future<String> persistReceipt(String sourcePath);
  Future<void> deleteReceipt(String path);
}
