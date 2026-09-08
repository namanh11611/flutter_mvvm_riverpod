import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../common/remote/supabase_client.dart';
import '../model/emergency_contact.dart';

final emergencyContactRepositoryProvider = Provider<EmergencyContactRepository>(
  (ref) => SupabaseEmergencyContactRepository(supabase),
);

abstract interface class EmergencyContactRepository {
  Future<List<EmergencyContact>> getContacts(String userId);

  Future<EmergencyContact> addContact({
    required String userId,
    required String name,
    required String phoneNumber,
    required String email,
  });

  Future<void> deleteContact(
      {required String userId, required String contactId});
}

class EmergencyContactValidationException implements Exception {
  final String message;
  const EmergencyContactValidationException(this.message);

  @override
  String toString() => message;
}

class SupabaseEmergencyContactRepository implements EmergencyContactRepository {
  const SupabaseEmergencyContactRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<EmergencyContact>> getContacts(String userId) async {
    _validateAuthenticatedUser(userId);
    final rows = await _client
        .from('emergency_contacts')
        .select()
        .eq('user_id', userId)
        .order('created_at');
    return rows
        .map((row) => _fromRow(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  @override
  Future<EmergencyContact> addContact({
    required String userId,
    required String name,
    required String phoneNumber,
    required String email,
  }) async {
    _validateAuthenticatedUser(userId);
    final values = EmergencyContactInput.validate(
      name: name,
      phoneNumber: phoneNumber,
      email: email,
    );
    try {
      final row = await _client
          .from('emergency_contacts')
          .insert({
            'user_id': userId,
            'name': values.name,
            'phone_number': values.phoneNumber,
            'email': values.email,
          })
          .select()
          .single();
      return _fromRow(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw const EmergencyContactValidationException(
          'A contact with this phone number or email already exists.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteContact({
    required String userId,
    required String contactId,
  }) async {
    _validateAuthenticatedUser(userId);
    await _client
        .from('emergency_contacts')
        .delete()
        .eq('id', contactId)
        .eq('user_id', userId);
  }

  void _validateAuthenticatedUser(String userId) {
    final authenticatedUserId = _client.auth.currentUser?.id;
    if (authenticatedUserId == null || authenticatedUserId != userId) {
      throw const EmergencyContactValidationException(
        'A signed-in user is required.',
      );
    }
  }

  EmergencyContact _fromRow(Map<String, dynamic> row) => EmergencyContact(
        id: row['id'] as String,
        userId: row['user_id'] as String,
        name: row['name'] as String,
        phoneNumber: row['phone_number'] as String,
        email: row['email'] as String,
        createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
      );
}

class EmergencyContactInput {
  const EmergencyContactInput({
    required this.name,
    required this.phoneNumber,
    required this.email,
  });

  final String name;
  final String phoneNumber;
  final String email;

  static final _emailPattern = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(\.[a-zA-Z]+)+$",
  );
  static final _phonePattern = RegExp(r'^\+?[0-9]{7,15}$');

  static EmergencyContactInput validate({
    required String name,
    required String phoneNumber,
    required String email,
  }) {
    final cleanName = name.trim();
    final cleanPhone = normalisePhone(phoneNumber);
    final cleanEmail = email.trim().toLowerCase();
    if (cleanName.isEmpty) {
      throw const EmergencyContactValidationException('Name is required.');
    }
    if (!_phonePattern.hasMatch(cleanPhone)) {
      throw const EmergencyContactValidationException(
        'Enter a valid phone number with 7 to 15 digits.',
      );
    }
    if (!_emailPattern.hasMatch(cleanEmail)) {
      throw const EmergencyContactValidationException(
        'Enter a valid email address.',
      );
    }
    return EmergencyContactInput(
      name: cleanName,
      phoneNumber: cleanPhone,
      email: cleanEmail,
    );
  }

  static String normalisePhone(String value) {
    final trimmed = value.trim();
    final prefix = trimmed.startsWith('+') ? '+' : '';
    return '$prefix${trimmed.replaceAll(RegExp(r'[^0-9]'), '')}';
  }
}

class SharedPreferencesEmergencyContactRepository
    implements EmergencyContactRepository {
  static const _keyPrefix = 'safety_emergency_contacts_';

  @override
  Future<List<EmergencyContact>> getContacts(String userId) async {
    if (userId.trim().isEmpty) {
      throw const EmergencyContactValidationException(
          'A signed-in user is required.');
    }
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_key(userId));
    if (encoded == null) return const [];

    final values = jsonDecode(encoded) as List<dynamic>;
    return values
        .map(
            (value) => EmergencyContact.fromJson(value as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<EmergencyContact> addContact({
    required String userId,
    required String name,
    required String phoneNumber,
    required String email,
  }) async {
    final cleanUserId = userId.trim();
    if (cleanUserId.isEmpty) {
      throw const EmergencyContactValidationException(
        'A signed-in user is required.',
      );
    }
    final values = EmergencyContactInput.validate(
      name: name,
      phoneNumber: phoneNumber,
      email: email,
    );

    final contacts = await getContacts(cleanUserId);
    final duplicate = contacts.any(
      (contact) =>
          EmergencyContactInput.normalisePhone(contact.phoneNumber) ==
              values.phoneNumber ||
          contact.email.toLowerCase() == values.email,
    );
    if (duplicate) {
      throw const EmergencyContactValidationException(
        'A contact with this phone number or email already exists.',
      );
    }

    final contact = EmergencyContact(
      id: const Uuid().v4(),
      userId: cleanUserId,
      name: values.name,
      phoneNumber: values.phoneNumber,
      email: values.email,
      createdAt: DateTime.now().toUtc(),
    );
    await _save(cleanUserId, [...contacts, contact]);
    return contact;
  }

  @override
  Future<void> deleteContact({
    required String userId,
    required String contactId,
  }) async {
    final contacts = await getContacts(userId);
    await _save(
      userId,
      contacts.where((contact) => contact.id != contactId).toList(),
    );
  }

  static String _key(String userId) => '$_keyPrefix$userId';

  Future<void> _save(String userId, List<EmergencyContact> contacts) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key(userId),
      jsonEncode(contacts.map((contact) => contact.toJson()).toList()),
    );
  }
}
