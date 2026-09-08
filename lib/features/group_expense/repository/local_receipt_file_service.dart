import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'receipt_file_service.dart';

class LocalReceiptFileService implements ReceiptFileService {
  @override
  Future<String> persistReceipt(String sourcePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final receiptDirectory = Directory(path.join(directory.path, 'receipts'));
    await receiptDirectory.create(recursive: true);
    final extension = path.extension(sourcePath);
    final destination = path.join(
      receiptDirectory.path,
      'receipt_${DateTime.now().microsecondsSinceEpoch}$extension',
    );
    return (await File(sourcePath).copy(destination)).path;
  }

  @override
  Future<void> deleteReceipt(String pathValue) async {
    final file = File(pathValue);
    if (await file.exists()) await file.delete();
  }
}
