import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../common/remote/supabase_client.dart';
import '../model/user_account_model.dart';

class UserAccountRepository {
  const UserAccountRepository();

  Future<void> completeProfileOnboarding({
    required String displayName,
    DateTime? dateOfBirth,
    String? nationality,
    String? gender,
    String? bio,
  }) async {
    final authUser = supabase.auth.currentUser;
    if (authUser == null) {
      throw const UserAccountLoadException(
        'Your session has expired. Please sign in again.',
      );
    }
    final name = displayName.trim();
    if (name.isEmpty) {
      throw const UserAccountLoadException('Your display name is required.');
    }

    try {
      await supabase
          .from('user_accounts')
          .update(<String, Object?>{
            'display_name': name,
            'date_of_birth': dateOfBirth == null
                ? null
                : '${dateOfBirth.year.toString().padLeft(4, '0')}-'
                      '${dateOfBirth.month.toString().padLeft(2, '0')}-'
                      '${dateOfBirth.day.toString().padLeft(2, '0')}',
            'nationality': _nullableText(nationality),
            'gender': _nullableText(gender),
            'bio': _nullableText(bio),
            'onboarding_completed': true,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', authUser.id);
    } on PostgrestException catch (error) {
      throw UserAccountLoadException(error.message);
    } catch (_) {
      throw const UserAccountLoadException(
        'Unable to save your profile. Check your connection and try again.',
      );
    }
  }

  Future<UserAccount> fetchCurrentAccount() async {
    final authUser = supabase.auth.currentUser;
    if (authUser == null) {
      throw const UserAccountLoadException(
        'Your session has expired. Please sign in again.',
      );
    }

    try {
      final row = await supabase
          .from('user_accounts')
          .select(
            'id, display_name, date_of_birth, gender, bio, '
            'profile_photo_path, background_photo_path, verification_status, '
            'nationality, created_at',
          )
          .eq('id', authUser.id)
          .maybeSingle();
      if (row == null) {
        return UserAccount(
          uid: authUser.id,
          email: authUser.email ?? '',
          phoneNumber: authUser.phone ?? '',
          username: '',
        );
      }

      final galleryPhotos = await _fetchGalleryPhotos(authUser.id);

      return UserAccount(
        uid: row['id'] as String,
        email: authUser.email ?? '',
        phoneNumber: authUser.phone ?? '',
        username: (row['display_name'] as String?)?.trim() ?? '',
        profilePhoto: _publicStorageUrl(
          'profile-images',
          row['profile_photo_path'] as String?,
          cacheBust: true,
        ),
        backgroundPhoto: _publicStorageUrl(
          'background-images',
          row['background_photo_path'] as String?,
          cacheBust: true,
        ),
        gender: row['gender'] as String?,
        nationality: (row['nationality'] as String?)?.trim(),
        dateOfBirth: _parseDate(row['date_of_birth']),
        joinedAt: _parseDate(row['created_at']),
        bio: (row['bio'] as String?)?.trim() ?? '',
        verificationStatus: IdentityVerificationStatus.fromValue(
          row['verification_status'],
        ),
        galleryPhotos: galleryPhotos,
      );
    } on UserAccountLoadException {
      rethrow;
    } on PostgrestException {
      throw const UserAccountLoadException(
        'Unable to load your profile. Check your connection and try again.',
      );
    } catch (_) {
      throw const UserAccountLoadException(
        'Unable to load your profile. Please try again.',
      );
    }
  }

  Future<UserAccount> updateProfile(
    String uid,
    UserAccountProfileUpdate update,
  ) async {
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null || authUser.id != uid) {
      throw const UserAccountLoadException(
        'Your session has expired. Please sign in again.',
      );
    }

    try {
      final userId = authUser.id;
      final profilePhotoPath = await _storagePathForUpdate(
        uid: userId,
        value: update.profilePhoto,
        bucket: 'profile-images',
        fileName: 'profile',
      );
      final backgroundPhotoPath = await _storagePathForUpdate(
        uid: userId,
        value: update.backgroundPhoto,
        bucket: 'background-images',
        fileName: 'background',
      );

      final values = <String, Object?>{
        'id': userId,
        'display_name': update.username.trim(),
        'bio': _nullableText(update.bio),
        'gender': _nullableText(update.gender),
        'nationality': _nullableText(update.nationality),
        'profile_photo_path': _nullableText(profilePhotoPath),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (update.dateOfBirth != null) {
        values['date_of_birth'] = _dateOnly(update.dateOfBirth!);
      }
      // The current compact editor does not expose background-photo editing.
      // Preserve the stored path unless a caller explicitly supplies a value.
      if (update.backgroundPhoto != null) {
        values['background_photo_path'] = _nullableText(backgroundPhotoPath);
      }
      await supabase.from('user_accounts').upsert(values, onConflict: 'id');

      return await fetchCurrentAccount();
    } on UserAccountLoadException {
      rethrow;
    } on ProfilePhotoUpdateException catch (error) {
      throw UserAccountLoadException(error.message);
    } on StorageException catch (error) {
      throw UserAccountLoadException(error.message);
    } on PostgrestException catch (error) {
      throw UserAccountLoadException(error.message);
    } catch (_) {
      throw const UserAccountLoadException(
        'Unable to save your profile. Check your connection and try again.',
      );
    }
  }

  Future<UserAccount> updateProfilePhoto(String localPath) async {
    final authUser = supabase.auth.currentUser;
    if (authUser == null) {
      throw const ProfilePhotoUpdateException(
        'Your session has expired. Please sign in again.',
      );
    }

    try {
      final file = File(localPath);
      final fileSize = await file.length();
      if (fileSize <= 0 || fileSize > 5 * 1024 * 1024) {
        throw const ProfilePhotoUpdateException(
          'Select a JPEG, PNG, or WebP image smaller than 5 MB.',
        );
      }

      final extension = _validatedImageExtension(localPath);
      final objectPath = '${authUser.id}/profile.$extension';
      await supabase.storage
          .from('profile-images')
          .uploadBinary(
            objectPath,
            await file.readAsBytes(),
            fileOptions: FileOptions(contentType: _imageContentType(extension)),
          );

      await supabase
          .from('user_accounts')
          .update(<String, Object?>{
            'profile_photo_path': objectPath,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', authUser.id);

      return await fetchCurrentAccount();
    } on ProfilePhotoUpdateException {
      rethrow;
    } on StorageException {
      throw const ProfilePhotoUpdateException(
        'Unable to update profile photo. Please try again.',
      );
    } on PostgrestException {
      throw const ProfilePhotoUpdateException(
        'Unable to update profile photo. Please try again.',
      );
    } on FileSystemException {
      throw const ProfilePhotoUpdateException(
        'Unable to read the selected image. Please choose another image.',
      );
    } catch (_) {
      throw const ProfilePhotoUpdateException(
        'Unable to update profile photo. Please try again.',
      );
    }
  }

  Future<UserAccount> deleteProfilePhoto() async {
    final authUser = supabase.auth.currentUser;
    if (authUser == null) {
      throw const ProfilePhotoUpdateException(
        'Your session has expired. Please sign in again.',
      );
    }

    try {
      final row = await supabase
          .from('user_accounts')
          .select('profile_photo_path')
          .eq('id', authUser.id)
          .maybeSingle();
      final oldPath = row?['profile_photo_path'] as String?;

      await supabase
          .from('user_accounts')
          .update(<String, Object?>{
            'profile_photo_path': null,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', authUser.id);

      if (oldPath != null && oldPath.startsWith('${authUser.id}/')) {
        try {
          await supabase.storage.from('profile-images').remove([oldPath]);
        } catch (_) {
          // The database is the source of truth. A leftover storage object can
          // be cleaned up independently without restoring the profile photo.
        }
      }

      return fetchCurrentAccount();
    } on PostgrestException catch (error) {
      throw ProfilePhotoUpdateException(error.message);
    } catch (_) {
      throw const ProfilePhotoUpdateException(
        'Unable to delete profile photo. Please try again.',
      );
    }
  }

  Future<UserAccount> fetchPublicAccount(String userId) async {
    final id = userId.trim();
    if (id.isEmpty) {
      throw const UserAccountLoadException('This profile is not available.');
    }
    try {
      final row = await supabase
          .from('user_accounts')
          .select(
            'id, display_name, date_of_birth, gender, bio, '
            'profile_photo_path, background_photo_path, verification_status, '
            'nationality, created_at',
          )
          .eq('id', id)
          .maybeSingle();
      if (row == null) {
        throw const UserAccountLoadException('This profile is not available.');
      }
      return UserAccount(
        uid: row['id'] as String,
        email: '',
        phoneNumber: '',
        username: (row['display_name'] as String?)?.trim() ?? '',
        profilePhoto: _publicStorageUrl(
          'profile-images',
          row['profile_photo_path'] as String?,
        ),
        backgroundPhoto: _publicStorageUrl(
          'background-images',
          row['background_photo_path'] as String?,
        ),
        gender: row['gender'] as String?,
        nationality: (row['nationality'] as String?)?.trim(),
        dateOfBirth: _parseDate(row['date_of_birth']),
        joinedAt: _parseDate(row['created_at']),
        bio: (row['bio'] as String?)?.trim() ?? '',
        verificationStatus: IdentityVerificationStatus.fromValue(
          row['verification_status'],
        ),
        galleryPhotos: await _fetchGalleryPhotos(id),
      );
    } on UserAccountLoadException {
      rethrow;
    } on PostgrestException {
      throw const UserAccountLoadException(
        'Unable to load this profile. Check your connection and try again.',
      );
    } catch (_) {
      throw const UserAccountLoadException(
        'Unable to load this profile. Please try again.',
      );
    }
  }

  Future<UserAccount> updateBackgroundPhoto(String localPath) async {
    final authUser = supabase.auth.currentUser;
    if (authUser == null) {
      throw const ProfilePhotoUpdateException(
        'Your session has expired. Please sign in again.',
      );
    }
    try {
      final file = File(localPath);
      final fileSize = await file.length();
      if (fileSize <= 0 || fileSize > 10 * 1024 * 1024) {
        throw const ProfilePhotoUpdateException(
          'Select a JPEG, PNG, or WebP image smaller than 10 MB.',
        );
      }
      final extension = _validatedImageExtension(localPath);
      final objectPath =
          '${authUser.id}/background_${DateTime.now().microsecondsSinceEpoch}.$extension';
      final bytes = await file.readAsBytes();
      await supabase.storage
          .from('background-images')
          .uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(contentType: _imageContentType(extension)),
          );
      final oldValue = await supabase
          .from('user_accounts')
          .select('background_photo_path')
          .eq('id', authUser.id)
          .maybeSingle();
      final oldPath = oldValue?['background_photo_path'] as String?;
      await supabase
          .from('user_accounts')
          .update(<String, Object?>{
            'background_photo_path': objectPath,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', authUser.id);
      if (oldPath != null && oldPath.startsWith('${authUser.id}/')) {
        try {
          await supabase.storage.from('background-images').remove([oldPath]);
        } catch (_) {}
      }
      return fetchCurrentAccount();
    } on ProfilePhotoUpdateException {
      rethrow;
    } on FileSystemException {
      throw const ProfilePhotoUpdateException(
        'Unable to read the selected image. Please choose another image.',
      );
    } on StorageException catch (error) {
      final message = error.message.toLowerCase();
      if (message.contains('mime type') && message.contains('not supported')) {
        throw const ProfilePhotoUpdateException(
          'Background photo storage is not configured for JPEG images. '
          'Apply the latest Supabase migrations and try again.',
        );
      }
      throw ProfilePhotoUpdateException(
        'Unable to upload background photo: ${error.message}',
      );
    } on PostgrestException catch (error) {
      throw ProfilePhotoUpdateException(
        'Unable to save background photo: ${error.message}',
      );
    } catch (_) {
      throw const ProfilePhotoUpdateException(
        'Unable to update background photo. Please try again.',
      );
    }
  }

  Future<UserAccount> deleteBackgroundPhoto() async {
    final authUser = supabase.auth.currentUser;
    if (authUser == null) {
      throw const ProfilePhotoUpdateException(
        'Your session has expired. Please sign in again.',
      );
    }
    try {
      final row = await supabase
          .from('user_accounts')
          .select('background_photo_path')
          .eq('id', authUser.id)
          .maybeSingle();
      final oldPath = row?['background_photo_path'] as String?;
      await supabase
          .from('user_accounts')
          .update(<String, Object?>{
            'background_photo_path': null,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', authUser.id);
      if (oldPath != null && oldPath.startsWith('${authUser.id}/')) {
        try {
          await supabase.storage.from('background-images').remove([oldPath]);
        } catch (_) {}
      }
      return fetchCurrentAccount();
    } catch (_) {
      throw const ProfilePhotoUpdateException(
        'Unable to delete background photo. Please try again.',
      );
    }
  }

  Future<List<String>> _fetchGalleryPhotos(String userId) async {
    try {
      final rows = await supabase
          .from('user_gallery')
          .select('image_path')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return rows
          .map(
            (row) => _publicStorageUrl(
              'user-gallery',
              row['image_path'] as String?,
              cacheBust: true,
            ),
          )
          .whereType<String>()
          .toList(growable: false);
    } on PostgrestException {
      // Gallery photos are optional. A gallery-specific permission or network
      // failure must not prevent the rest of the Account page from loading.
      return const [];
    }
  }

  Future<UserAccount> addGalleryPhoto(String localPath) async {
    final authUser = supabase.auth.currentUser;
    if (authUser == null) {
      throw const ProfilePhotoUpdateException(
        'Your session has expired. Please sign in again.',
      );
    }

    try {
      final file = File(localPath);
      final fileSize = await file.length();
      if (fileSize <= 0 || fileSize > 10 * 1024 * 1024) {
        throw const ProfilePhotoUpdateException(
          'Select a JPEG, PNG, or WebP image smaller than 10 MB.',
        );
      }

      final extension = _validatedImageExtension(localPath);
      final objectPath =
          '${authUser.id}/${DateTime.now().microsecondsSinceEpoch}.$extension';
      await supabase.storage
          .from('user-gallery')
          .uploadBinary(
            objectPath,
            await file.readAsBytes(),
            fileOptions: FileOptions(contentType: _imageContentType(extension)),
          );
      await supabase.from('user_gallery').insert({
        'user_id': authUser.id,
        'image_path': objectPath,
      });
      return fetchCurrentAccount();
    } on ProfilePhotoUpdateException {
      rethrow;
    } on StorageException catch (error) {
      throw ProfilePhotoUpdateException(error.message);
    } on PostgrestException catch (error) {
      throw ProfilePhotoUpdateException(error.message);
    } on FileSystemException {
      throw const ProfilePhotoUpdateException(
        'Unable to read the selected photo. Please choose another image.',
      );
    } catch (_) {
      throw const ProfilePhotoUpdateException(
        'Unable to add this gallery photo. Please try again.',
      );
    }
  }

  Future<UserAccount> deleteGalleryPhotos(List<String> photoUrls) async {
    final authUser = supabase.auth.currentUser;
    if (authUser == null) {
      throw const ProfilePhotoUpdateException(
        'Your session has expired. Please sign in again.',
      );
    }

    final objectPaths = photoUrls
        .map((url) => _extractStoragePath(url, 'user-gallery'))
        .where((path) => path.startsWith('${authUser.id}/'))
        .toSet()
        .toList(growable: false);
    if (objectPaths.isEmpty) {
      throw const ProfilePhotoUpdateException(
        'No valid gallery photos were selected.',
      );
    }

    try {
      await supabase
          .from('user_gallery')
          .delete()
          .eq('user_id', authUser.id)
          .inFilter('image_path', objectPaths);

      // The database is the source of truth for the gallery. If storage
      // cleanup fails, keep the photos deleted from the account rather than
      // restoring rows that now point at partially removed files.
      try {
        await supabase.storage.from('user-gallery').remove(objectPaths);
      } catch (_) {
        // Orphaned objects can be cleaned up independently.
      }

      return fetchCurrentAccount();
    } on ProfilePhotoUpdateException {
      rethrow;
    } on PostgrestException catch (error) {
      throw ProfilePhotoUpdateException(error.message);
    } catch (_) {
      throw const ProfilePhotoUpdateException(
        'Unable to delete the selected photos. Please try again.',
      );
    }
  }

  Future<String?> _storagePathForUpdate({
    required String uid,
    required String? value,
    required String bucket,
    required String fileName,
  }) async {
    if (value == null || value.trim().isEmpty) return null;
    if (!_isLocalPath(value)) return _extractStoragePath(value, bucket);

    final file = File(value);
    final fileSize = await file.length();
    if (fileSize <= 0 || fileSize > 5 * 1024 * 1024) {
      throw const ProfilePhotoUpdateException(
        'Select a JPEG, PNG, or WebP image smaller than 5 MB.',
      );
    }
    final extension = _validatedImageExtension(value);
    final objectPath = '$uid/$fileName.$extension';
    await supabase.storage
        .from(bucket)
        .uploadBinary(
          objectPath,
          await file.readAsBytes(),
          fileOptions: FileOptions(
            upsert: true,
            contentType: _imageContentType(extension),
          ),
        );
    return objectPath;
  }

  Future<IdentityVerificationStatus> fetchVerificationStatus() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw const IdentityVerificationException('Please sign in again.');
    }
    final row = await supabase
        .from('user_accounts')
        .select('verification_status')
        .eq('id', user.id)
        .single();
    return IdentityVerificationStatus.fromValue(row['verification_status']);
  }

  Future<String> createDiditSession() async {
    if (supabase.auth.currentSession == null) {
      throw const IdentityVerificationException(
        'Your session has expired. Please sign in again.',
      );
    }

    try {
      final response = await supabase.functions.invoke(
        'create-didit-session',
        body: const <String, Object?>{},
      );
      final data = response.data;
      if (data is! Map) {
        throw const IdentityVerificationException(
          'The verification service returned an invalid response.',
        );
      }

      final value = data['verification_url'];
      if (value is! String || value.trim().isEmpty) {
        throw const IdentityVerificationException(
          'The verification link was not returned. Please try again.',
        );
      }

      final uri = Uri.tryParse(value.trim());
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.userInfo.isNotEmpty ||
          !(uri.host == 'didit.me' || uri.host.endsWith('.didit.me'))) {
        throw const IdentityVerificationException(
          'The verification service returned an invalid link.',
        );
      }
      return uri.toString();
    } on IdentityVerificationException {
      rethrow;
    } on FunctionException catch (error) {
      if (error.status == 409) {
        throw const IdentityVerificationException(
          'Verification is already active or complete. Refresh your status and try again if needed.',
        );
      }
      throw IdentityVerificationException(
        error.status == 401
            ? 'Your session has expired. Please sign in again.'
            : 'Unable to start identity verification. Please try again.',
      );
    } catch (_) {
      throw const IdentityVerificationException(
        'Unable to start identity verification. Please try again.',
      );
    }
  }
}

String? _publicStorageUrl(
  String bucket,
  String? path, {
  bool cacheBust = false,
}) {
  final value = path?.trim();
  if (value == null || value.isEmpty) return null;
  if (!_isLocalPath(value)) return value;
  final url = supabase.storage.from(bucket).getPublicUrl(value);
  return cacheBust ? '$url?v=${DateTime.now().millisecondsSinceEpoch}' : url;
}

String _extractStoragePath(String value, String bucket) {
  final uri = Uri.tryParse(value);
  if (uri == null) return value;
  final bucketIndex = uri.pathSegments.indexOf(bucket);
  if (bucketIndex < 0 || bucketIndex == uri.pathSegments.length - 1) {
    return value;
  }
  return uri.pathSegments.sublist(bucketIndex + 1).join('/');
}

bool _isLocalPath(String? value) {
  if (value == null || value.trim().isEmpty) return false;
  final uri = Uri.tryParse(value);
  return uri == null || !(uri.scheme == 'http' || uri.scheme == 'https');
}

String? _nullableText(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

String _validatedImageExtension(String path) {
  final cleanPath = path.split('?').first.toLowerCase();
  if (cleanPath.endsWith('.jpg') || cleanPath.endsWith('.jpeg')) return 'jpg';
  if (cleanPath.endsWith('.png')) return 'png';
  if (cleanPath.endsWith('.webp')) return 'webp';
  throw const ProfilePhotoUpdateException('Select a JPEG, PNG, or WebP image.');
}

String _imageContentType(String extension) => switch (extension) {
  'png' => 'image/png',
  'webp' => 'image/webp',
  _ => 'image/jpeg',
};

DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

String _dateOnly(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

class UserAccountLoadException implements Exception {
  const UserAccountLoadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class IdentityVerificationException implements Exception {
  const IdentityVerificationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProfilePhotoUpdateException implements Exception {
  const ProfilePhotoUpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}

final userAccountRepositoryProvider = Provider<UserAccountRepository>((ref) {
  return const UserAccountRepository();
});
