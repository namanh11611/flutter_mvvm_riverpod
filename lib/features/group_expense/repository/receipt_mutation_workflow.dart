typedef UploadReceipt = Future<String> Function();
typedef UpdateReceiptMetadata = Future<void> Function(String objectPath);
typedef DeleteReceiptOperation = Future<void> Function(String objectPath);
typedef DeleteReceiptMetadata = Future<void> Function();

/// Coordinates Storage and metadata writes without depending on Supabase.
///
/// The deployed path-based DELETE policy keeps old-object authorization valid
/// after replacement metadata starts pointing at the new object.
class ReceiptMutationWorkflow {
  const ReceiptMutationWorkflow._();

  static Future<void> remove({
    required String objectPath,
    required DeleteReceiptOperation deleteObject,
    required DeleteReceiptMetadata deleteMetadata,
  }) async {
    await deleteObject(objectPath);
    await deleteMetadata();
  }

  static Future<String> replace({
    required String? oldObjectPath,
    required UploadReceipt upload,
    required UpdateReceiptMetadata updateMetadata,
    required DeleteReceiptOperation deleteObject,
  }) async {
    final newObjectPath = await upload();
    try {
      await updateMetadata(newObjectPath);
    } catch (_) {
      await deleteObject(newObjectPath);
      rethrow;
    }

    if (oldObjectPath != null && oldObjectPath != newObjectPath) {
      await deleteObject(oldObjectPath);
    }
    return newObjectPath;
  }
}
