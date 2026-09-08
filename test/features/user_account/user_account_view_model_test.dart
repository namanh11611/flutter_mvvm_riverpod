import 'package:flutter_mvvm_riverpod/features/user_account/model/user_account_model.dart';
import 'package:flutter_mvvm_riverpod/features/user_account/repository/user_account_repository.dart';
import 'package:flutter_mvvm_riverpod/features/user_account/ui/view_model/user_account_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'starts hosted verification without marking the user verified',
    () async {
      final repository = _FakeUserAccountRepository();
      final container = ProviderContainer(
        overrides: [
          userAccountRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      container.read(userAccountViewModelProvider);
      await Future<void>.delayed(Duration.zero);

      final notifier = container.read(userAccountViewModelProvider.notifier);
      expect(
        await notifier.startIdentityVerification(),
        'https://verify.didit.me/session/test',
      );

      final pending = container.read(userAccountViewModelProvider).user!;
      expect(pending.isVerified, isFalse);
      expect(pending.verificationStatus, IdentityVerificationStatus.pending);

      await notifier.updateProfile(
        const UserAccountProfileUpdate(
          username: 'new.username',
          gender: 'Non-binary',
          nationality: 'Malaysia',
          bio: 'Updated bio',
        ),
      );

      final updated = container.read(userAccountViewModelProvider).user!;
      expect(updated.username, 'new.username');
      expect(updated.nationality, 'Malaysia');
      expect(updated.bio, 'Updated bio');
    },
  );

  test(
    'refresh applies approval and rejection without clearing profile',
    () async {
      final repository = _FakeUserAccountRepository();
      final container = ProviderContainer(
        overrides: [
          userAccountRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      container.read(userAccountViewModelProvider);
      await Future<void>.delayed(Duration.zero);
      final notifier = container.read(userAccountViewModelProvider.notifier);
      repository.verificationStatus = IdentityVerificationStatus.verified;
      await notifier.refreshVerificationStatus();
      expect(
        container.read(userAccountViewModelProvider).user!.isVerified,
        isTrue,
      );
      expect(await notifier.startIdentityVerification(), isNull);
      expect(repository.sessionRequests, 0);

      repository.verificationStatus = IdentityVerificationStatus.unverified;
      await notifier.refreshVerificationStatus();
      final rejected = container.read(userAccountViewModelProvider).user!;
      expect(rejected.isVerified, isFalse);
      expect(rejected.username, 'test.user');
      expect(await notifier.startIdentityVerification(), isNotNull);
      expect(repository.sessionRequests, 1);
    },
  );

  test(
    'session failure preserves unverified status and allows retry',
    () async {
      final repository = _FakeUserAccountRepository()..failSession = true;
      final container = ProviderContainer(
        overrides: [
          userAccountRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      container.read(userAccountViewModelProvider);
      await Future<void>.delayed(Duration.zero);
      final notifier = container.read(userAccountViewModelProvider.notifier);
      expect(await notifier.startIdentityVerification(), isNull);
      final failed = container.read(userAccountViewModelProvider);
      expect(failed.isLoading, isFalse);
      expect(failed.error, contains('Try again'));
      expect(
        failed.user!.verificationStatus,
        IdentityVerificationStatus.unverified,
      );
      repository.failSession = false;
      expect(await notifier.startIdentityVerification(), isNotNull);
      expect(container.read(userAccountViewModelProvider).error, isNull);
    },
  );

  test('deletes selected gallery photos and refreshes account state', () async {
    final repository = _FakeUserAccountRepository(
      galleryPhotos: const ['newest.jpg', 'middle.jpg', 'oldest.jpg'],
    );
    final container = ProviderContainer(
      overrides: [userAccountRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    container.read(userAccountViewModelProvider);
    await Future<void>.delayed(Duration.zero);

    final deleted = await container
        .read(userAccountViewModelProvider.notifier)
        .deleteGalleryImages(const ['middle.jpg', 'oldest.jpg']);

    expect(deleted, isTrue);
    expect(repository.deletedPhotos, ['middle.jpg', 'oldest.jpg']);
    expect(container.read(userAccountViewModelProvider).user!.galleryPhotos, [
      'newest.jpg',
    ]);
  });
}

class _FakeUserAccountRepository extends UserAccountRepository {
  _FakeUserAccountRepository({List<String> galleryPhotos = const []})
    : _galleryPhotos = [...galleryPhotos];

  List<String> _galleryPhotos;
  List<String> deletedPhotos = const [];
  IdentityVerificationStatus verificationStatus =
      IdentityVerificationStatus.unverified;
  int sessionRequests = 0;
  bool failSession = false;

  @override
  Future<UserAccount> fetchCurrentAccount() async {
    return UserAccount(
      uid: 'test-user',
      email: 'test@example.com',
      phoneNumber: '',
      username: 'test.user',
      galleryPhotos: _galleryPhotos,
    );
  }

  @override
  Future<UserAccount> deleteGalleryPhotos(List<String> photoUrls) async {
    deletedPhotos = [...photoUrls];
    _galleryPhotos = _galleryPhotos
        .where((photo) => !photoUrls.contains(photo))
        .toList(growable: false);
    return fetchCurrentAccount();
  }

  @override
  Future<UserAccount> updateProfile(
    String uid,
    UserAccountProfileUpdate update,
  ) async {
    return UserAccount(
      uid: uid,
      email: 'test@example.com',
      phoneNumber: '',
      username: update.username,
      profilePhoto: update.profilePhoto,
      gender: update.gender,
      nationality: update.nationality,
      bio: update.bio,
    );
  }

  @override
  Future<IdentityVerificationStatus> fetchVerificationStatus() async =>
      verificationStatus;

  @override
  Future<String> createDiditSession() async {
    sessionRequests++;
    if (failSession) throw const IdentityVerificationException('Try again');
    return 'https://verify.didit.me/session/test';
  }
}
