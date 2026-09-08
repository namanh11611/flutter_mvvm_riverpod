import '../../model/emergency_contact.dart';

class EmergencyContactsState {
  final List<EmergencyContact> contacts;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const EmergencyContactsState({
    this.contacts = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  EmergencyContactsState copyWith({
    List<EmergencyContact>? contacts,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return EmergencyContactsState(
      contacts: contacts ?? this.contacts,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : error ?? this.error,
    );
  }
}
