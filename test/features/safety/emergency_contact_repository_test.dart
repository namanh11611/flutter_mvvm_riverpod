import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mvvm_riverpod/features/safety/repository/emergency_contact_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferencesEmergencyContactRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = SharedPreferencesEmergencyContactRepository();
  });

  test('adds and persists a normalized emergency contact', () async {
    final added = await repository.addContact(
      userId: 'user-1',
      name: '  Jamie Lee  ',
      phoneNumber: '+60 12-345 6789',
      email: ' JAMIE@EXAMPLE.COM ',
    );

    expect(added.name, 'Jamie Lee');
    expect(added.phoneNumber, '+60123456789');
    expect(added.email, 'jamie@example.com');
    expect(await repository.getContacts('user-1'), hasLength(1));
  });

  test('keeps contacts isolated by user', () async {
    await repository.addContact(
      userId: 'user-1',
      name: 'Jamie Lee',
      phoneNumber: '+60123456789',
      email: 'jamie@example.com',
    );

    expect(await repository.getContacts('user-2'), isEmpty);
  });

  test('rejects a duplicate normalized phone number', () async {
    await repository.addContact(
      userId: 'user-1',
      name: 'Jamie Lee',
      phoneNumber: '+60 12-345 6789',
      email: 'jamie@example.com',
    );

    expect(
      () => repository.addContact(
        userId: 'user-1',
        name: 'Jamie Other',
        phoneNumber: '+60123456789',
        email: 'other@example.com',
      ),
      throwsA(isA<EmergencyContactValidationException>()),
    );
  });

  test('rejects invalid contact details', () {
    expect(
      () => repository.addContact(
        userId: 'user-1',
        name: '',
        phoneNumber: '123',
        email: 'not-an-email',
      ),
      throwsA(isA<EmergencyContactValidationException>()),
    );
  });
}
