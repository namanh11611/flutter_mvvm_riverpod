import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/remote/supabase_client.dart';
import '../../repository/emergency_contact_repository.dart';
import '../../repository/emergency_service_repository.dart';
import '../../repository/location_service.dart';
import '../state/sos_state.dart';

final sosViewModelProvider = NotifierProvider<SosViewModel, SosState>(
  SosViewModel.new,
);

class SosViewModel extends Notifier<SosState> {
  @override
  SosState build() => const SosState();

  Future<void> triggerEmergency() async {
    if (state.isTriggering) return;
    state = state.copyWith(isTriggering: true, clearMessage: true);
    try {
      if (state.location == null || state.numbers == null) {
        await activate();
      }

      // Launch the pre-addressed location alert first, followed by the phone
      // dialler. Android and iOS require the user to confirm both actions.
      await alertContacts();
      await callPreferred();
    } finally {
      state = state.copyWith(isTriggering: false);
    }
  }

  Future<void> activate() async {
    if (state.isLocating) return;
    state = state.copyWith(
      isLocating: true,
      clearMessage: true,
      clearEmergencyData: true,
    );
    try {
      final location = await ref.read(locationServiceProvider).getCurrentLocation();
      final repository = ref.read(emergencyServiceRepositoryProvider);
      final detected = await repository.detectLocation(location);
      state = state.copyWith(
        isLocating: false,
        location: location,
        countryCode: detected.countryCode,
        locationLabel: detected.label,
      );
      final cached = await repository.getCachedEmergencyNumbers(
        detected.countryCode,
      );
      if (cached != null) {
        state = state.copyWith(numbers: cached, usingCache: true);
      }
      await refresh();
    } on LocationServiceException catch (error) {
      state = state.copyWith(isLocating: false, message: error.message);
    } on EmergencyServiceException catch (error) {
      state = state.copyWith(isLocating: false, message: error.message);
    } catch (_) {
      state = state.copyWith(
        isLocating: false,
        message: 'Could not identify your location. Please retry.',
      );
    }
  }

  Future<void> refresh() async {
    final code = state.countryCode;
    if (code == null || state.isRefreshing) return;
    state = state.copyWith(isRefreshing: true, clearMessage: true);
    try {
      final numbers = await ref
          .read(emergencyServiceRepositoryProvider)
          .getEmergencyNumbers(code);
      state = state.copyWith(
        isRefreshing: false,
        numbers: numbers,
        usingCache: false,
      );
    } on EmergencyServiceException catch (error) {
      state = state.copyWith(
        isRefreshing: false,
        message: state.numbers == null
            ? error.message
            : 'Could not refresh. Showing saved emergency numbers.',
      );
    }
  }

  Future<void> call(String number) async {
    try {
      await ref.read(emergencyServiceRepositoryProvider).openDialler(number);
    } on EmergencyServiceException catch (error) {
      state = state.copyWith(message: error.message);
    }
  }

  Future<void> callPreferred() async {
    final service = state.numbers?.preferredService;
    if (service == null || service.numbers.isEmpty) {
      state = state.copyWith(message: 'No callable emergency number is available.');
      return;
    }
    await call(service.numbers.first);
  }

  Future<void> alertContacts() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw StateError('Sign in to alert your contacts.');
      final contacts = await ref
          .read(emergencyContactRepositoryProvider)
          .getContacts(userId);
      if (contacts.isEmpty) {
        throw StateError('Add an emergency contact before sending an alert.');
      }
      final location = state.location;
      final locationText = location == null
          ? 'My current location could not be retrieved.'
          : 'My location: https://maps.google.com/?q=${location.latitude},${location.longitude}';
      await ref.read(emergencyServiceRepositoryProvider).composeAlert(
            phoneNumbers: contacts.map((contact) => contact.phoneNumber).toList(),
            message: 'GoBuddy SOS: I may need urgent help. $locationText',
          );
    } on EmergencyServiceException catch (error) {
      state = state.copyWith(message: error.message);
    } catch (error) {
      state = state.copyWith(
        message: error.toString().replaceFirst('Bad state: ', ''),
      );
    }
  }

  void clearMessage() => state = state.copyWith(clearMessage: true);
}
