import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class GroupExpenseRepositoryException implements Exception {
  const GroupExpenseRepositoryException(this.message, {this.code});
  final String message;
  final String? code;
  @override
  String toString() => message;
}

Never groupExpenseFailure(Object error) {
  if (error is GroupExpenseRepositoryException) throw error;
  if (error is AuthException) {
    throw const GroupExpenseRepositoryException(
      'Your session has expired. Please sign in again.',
      code: 'unauthenticated',
    );
  }
  if (error is PostgrestException) {
    final code = error.code;
    if (code == '42501') {
      throw const GroupExpenseRepositoryException(
        'You do not have permission to perform this action.',
        code: 'unauthorized',
      );
    }
    if (code == 'PGRST116' || code == 'P0002') {
      throw const GroupExpenseRepositoryException(
        'The requested record was not found.',
        code: 'not_found',
      );
    }
    if (code == '23505') {
      throw const GroupExpenseRepositoryException(
        'A matching record already exists.',
        code: 'conflict',
      );
    }
    throw const GroupExpenseRepositoryException(
      'Group expense data is temporarily unavailable.',
      code: 'database',
    );
  }
  if (error is StorageException) {
    throw const GroupExpenseRepositoryException(
      'The receipt could not be stored. Please try again.',
      code: 'storage',
    );
  }
  if (error is SocketException || error is TimeoutException) {
    throw const GroupExpenseRepositoryException(
      'Check your connection and try again.',
      code: 'network',
    );
  }
  throw const GroupExpenseRepositoryException(
    'Something went wrong. Please try again.',
    code: 'unknown',
  );
}
