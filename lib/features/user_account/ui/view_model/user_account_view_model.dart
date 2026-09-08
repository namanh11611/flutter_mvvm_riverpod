import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/permissions/app_permission_service.dart';
import '../../model/user_account_model.dart';
import '../../repository/user_account_repository.dart';
import '../state/user_account_state.dart';

// 1. Modern NotifierProvider definition matching your team template
final userAccountViewModelProvider =
    NotifierProvider<UserAccountViewModel, UserAccountState>(
      UserAccountViewModel.new,
    );

// 2. The modern Notifier class managing your module state lifecycle
class UserAccountViewModel extends Notifier<UserAccountState> {
  @override
  UserAccountState build() {
    // Fire off async data initialization so it doesn't block layout threads
    _initLoad();

    // Return standard initial loading state immediately
    return const UserAccountState(isLoading: true);
  }

  /// Private initialization method to load profile data seamlessly
  Future<void> _initLoad() async {
    // Let Riverpod finish initializing the notifier before mutating state.
    await Future<void>.delayed(Duration.zero);
    await _loadProfile();
  }

  Future<void> refresh() async {
    if (state.isLoading) return;
    await _loadProfile();
  }

  Future<void> _loadProfile() async {
    final repository = ref.read(userAccountRepositoryProvider);
    state = state.copyWith(isLoading: true, clearError: true, clearUser: true);
    try {
      // A missing row is represented by an authenticated empty draft so the
      // first profile save can create it with an upsert.
      final initialUser = await repository.fetchCurrentAccount();
      state = state.copyWith(user: initialUser, isLoading: false);
    } catch (error) {
      state = state.copyWith(error: error.toString(), isLoading: false);
    }
  }

  /// Change the currently active sub-page within the user account module
  void goTo(UserAccountPage page) => state = state.copyWith(page: page);

  Future<bool> updateProfile(UserAccountProfileUpdate update) async {
    if (state.user == null || update.username.trim().isEmpty) return false;

    state = state.copyWith(isLoading: true, clearError: true);
    final repository = ref.read(userAccountRepositoryProvider);

    try {
      final updatedUser = await repository.updateProfile(
        state.user!.uid,
        update,
      );
      state = state.copyWith(
        user: updatedUser,
        page: UserAccountPage.profile,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<String?> selectProfileImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    if (state.user == null || state.isLoading) return null;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (source == ImageSource.camera) {
        await const AppPermissionService().requireCameraPermission();
      }
      final image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
      );
      if (image == null) {
        state = state.copyWith(isLoading: false);
        return null;
      }

      final repository = ref.read(userAccountRepositoryProvider);
      final updatedUser = await repository.updateProfilePhoto(image.path);
      state = state.copyWith(user: updatedUser, isLoading: false);
      return updatedUser.profilePhoto;
    } catch (error) {
      state = state.copyWith(
        error: switch (error) {
          ProfilePhotoUpdateException(:final message) => message,
          AppPermissionException(:final message) => message,
          _ => 'Unable to update profile photo. Please try again.',
        },
        isLoading: false,
      );
      return null;
    }
  }

  Future<bool> deleteProfileImage() async {
    if (state.user == null ||
        state.isLoading ||
        state.user!.profilePhoto == null) {
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updatedUser = await ref
          .read(userAccountRepositoryProvider)
          .deleteProfilePhoto();
      state = state.copyWith(user: updatedUser, isLoading: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        error: error is ProfilePhotoUpdateException
            ? error.message
            : 'Unable to delete profile photo. Please try again.',
        isLoading: false,
      );
      return false;
    }
  }

  Future<String?> addGalleryImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    if (state.user == null || state.isLoading) return null;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (source == ImageSource.camera) {
        await const AppPermissionService().requireCameraPermission();
      }
      final image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
      );
      if (image == null) {
        state = state.copyWith(isLoading: false);
        return null;
      }

      final updatedUser = await ref
          .read(userAccountRepositoryProvider)
          .addGalleryPhoto(image.path);
      state = state.copyWith(user: updatedUser, isLoading: false);
      return updatedUser.galleryPhotos.isEmpty
          ? null
          : updatedUser.galleryPhotos.first;
    } catch (error) {
      state = state.copyWith(
        error: switch (error) {
          ProfilePhotoUpdateException(:final message) => message,
          AppPermissionException(:final message) => message,
          _ => 'Unable to add this gallery photo. Please try again.',
        },
        isLoading: false,
      );
      return null;
    }
  }

  Future<String?> selectBackgroundImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    if (state.user == null || state.isLoading) return null;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (source == ImageSource.camera) {
        await const AppPermissionService().requireCameraPermission();
      }
      final image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
      );
      if (image == null) {
        state = state.copyWith(isLoading: false);
        return null;
      }
      final croppedImage = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        maxWidth: 1600,
        maxHeight: 1600,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop background photo',
            toolbarColor: const Color(0xFF281950),
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFF7C3AED),
            dimmedLayerColor: Colors.black87,
            cropFrameColor: Colors.white,
            cropGridColor: Colors.white70,
            lockAspectRatio: true,
            hideBottomControls: true,
            initAspectRatio: CropAspectRatioPreset.square,
            aspectRatioPresets: const [CropAspectRatioPreset.square],
          ),
          IOSUiSettings(
            title: 'Crop background photo',
            doneButtonTitle: 'Save',
            cancelButtonTitle: 'Cancel',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
            aspectRatioPresets: const [CropAspectRatioPreset.square],
          ),
        ],
      );
      if (croppedImage == null) {
        state = state.copyWith(isLoading: false);
        return null;
      }
      final updatedUser = await ref
          .read(userAccountRepositoryProvider)
          .updateBackgroundPhoto(croppedImage.path);
      state = state.copyWith(user: updatedUser, isLoading: false);
      return updatedUser.backgroundPhoto;
    } catch (error) {
      state = state.copyWith(
        error: switch (error) {
          ProfilePhotoUpdateException(:final message) => message,
          AppPermissionException(:final message) => message,
          _ => 'Unable to update background photo. Please try again.',
        },
        isLoading: false,
      );
      return null;
    }
  }

  Future<bool> deleteBackgroundImage() async {
    if (state.user == null || state.isLoading) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updatedUser = await ref
          .read(userAccountRepositoryProvider)
          .deleteBackgroundPhoto();
      state = state.copyWith(user: updatedUser, isLoading: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        error: error is ProfilePhotoUpdateException
            ? error.message
            : 'Unable to delete background photo. Please try again.',
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> deleteGalleryImages(List<String> photoUrls) async {
    if (state.user == null || state.isLoading || photoUrls.isEmpty) {
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updatedUser = await ref
          .read(userAccountRepositoryProvider)
          .deleteGalleryPhotos(photoUrls);
      state = state.copyWith(user: updatedUser, isLoading: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        error: switch (error) {
          ProfilePhotoUpdateException(:final message) => message,
          _ => 'Unable to delete the selected photos. Please try again.',
        },
        isLoading: false,
      );
      return false;
    }
  }

  bool _refreshingVerification = false;
  int _verificationRevision = 0;

  Future<void> refreshVerificationStatus({bool showError = false}) async {
    final user = state.user;
    if (user == null || state.isLoading || _refreshingVerification) return;
    _refreshingVerification = true;
    final revision = _verificationRevision;
    try {
      final repository = ref.read(userAccountRepositoryProvider);
      final status = await repository.fetchVerificationStatus();
      if (state.user?.uid == user.uid && revision == _verificationRevision) {
        // Approval can also replace date_of_birth with the value extracted
        // from the verified identity document, so refresh the whole account.
        final refreshedUser = status == IdentityVerificationStatus.verified
            ? await repository.fetchCurrentAccount()
            : state.user!.copyWith(verificationStatus: status);
        if (state.user?.uid != user.uid ||
            revision != _verificationRevision) {
          return;
        }
        state = state.copyWith(
          user: refreshedUser,
          clearError: true,
        );
      }
    } catch (_) {
      if (showError) {
        state = state.copyWith(
          error: 'Unable to refresh verification status. Please try again.',
        );
      }
    } finally {
      _refreshingVerification = false;
    }
  }

  Future<String?> startIdentityVerification() async {
    final user = state.user;
    if (user == null || state.isLoading) return null;
    if (user.isVerified) {
      state = state.copyWith(error: 'Your identity is already verified.');
      return null;
    }
    _verificationRevision++;

    state = state.copyWith(isLoading: true, clearError: true);
    final repository = ref.read(userAccountRepositoryProvider);

    try {
      final verificationUrl = await repository.createDiditSession();
      state = state.copyWith(
        isLoading: false,
        user: state.user?.copyWith(
          verificationStatus: IdentityVerificationStatus.pending,
        ),
      );
      return verificationUrl;
    } catch (error) {
      state = state.copyWith(error: error.toString(), isLoading: false);
      return null;
    }
  }
}
