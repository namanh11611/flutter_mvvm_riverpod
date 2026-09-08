import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/remote/supabase_client.dart';
import '../../repository/emergency_contact_repository.dart';
import '../state/emergency_contacts_state.dart';

final emergencyContactsViewModelProvider =
    NotifierProvider<EmergencyContactsViewModel, EmergencyContactsState>(
  EmergencyContactsViewModel.new,
);

class EmergencyContactsViewModel extends Notifier<EmergencyContactsState> {
  String? _userId;

  @override
  EmergencyContactsState build() {
    Future.microtask(loadContacts);
    return const EmergencyContactsState(isLoading: true);
  }

  Future<void> loadContacts() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final userId = _authenticatedUserId();
      _userId = userId;
      final contacts = await ref
          .read(emergencyContactRepositoryProvider)
          .getContacts(userId);
      state = state.copyWith(contacts: contacts, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<bool> addContact({
    required String name,
    required String phoneNumber,
    required String email,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final userId = _userId ?? _authenticatedUserId();
      _userId = userId;
      final contact =
          await ref.read(emergencyContactRepositoryProvider).addContact(
                userId: userId,
                name: name,
                phoneNumber: phoneNumber,
                email: email,
              );
      state = state.copyWith(
        contacts: [...state.contacts, contact],
        isSaving: false,
      );
      return true;
    } catch (error) {
      state = state.copyWith(isSaving: false, error: error.toString());
      return false;
    }
  }

  Future<void> deleteContact(String contactId) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await ref.read(emergencyContactRepositoryProvider).deleteContact(
            userId: userId,
            contactId: contactId,
          );
      state = state.copyWith(
        contacts: state.contacts
            .where((contact) => contact.id != contactId)
            .toList(growable: false),
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  String _authenticatedUserId() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw const EmergencyContactValidationException(
        'Sign in to manage emergency contacts.',
      );
    }
    return userId;
  }
}
