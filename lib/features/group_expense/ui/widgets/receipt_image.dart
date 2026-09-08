import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repository/group_expense_providers.dart';

final receiptSignedUrlProvider =
    FutureProvider.autoDispose.family<String, String>((ref, objectPath) {
  return ref.watch(receiptStorageServiceProvider).createSignedUrl(objectPath);
});

class ReceiptImage extends ConsumerWidget {
  const ReceiptImage({super.key, required this.path, this.height = 220});
  final String path;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!path.startsWith('trips/')) {
      return Image.file(File(path),
          height: height, fit: BoxFit.cover, errorBuilder: _error);
    }
    return ref.watch(receiptSignedUrlProvider(path)).when(
          loading: () => SizedBox(
              height: height,
              child: const Center(child: CircularProgressIndicator())),
          error: (_, __) => _error(context, Object(), StackTrace.empty),
          data: (url) => Image.network(url,
              height: height, fit: BoxFit.cover, errorBuilder: _error),
        );
  }

  Widget _error(BuildContext context, Object error, StackTrace? stackTrace) =>
      SizedBox(
          height: 100,
          child: const Center(child: Text('Receipt preview unavailable')));
}
