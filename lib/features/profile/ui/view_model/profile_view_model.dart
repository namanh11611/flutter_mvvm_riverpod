import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../constants/constants.dart';
import '../../../../extensions/build_context_extension.dart';
import '../../../../extensions/profile_extension.dart';
import '../../../../extensions/string_extension.dart';
import '../../../authentication/ui/view_model/authentication_view_model.dart';
import '../../model/profile.dart';
import '../../repository/profile_repository.dart';
import '../../ui/state/profile_state.dart';

part 'profile_view_model.g.dart';

@Riverpod(keepAlive: true)
class ProfileViewModel extends _$ProfileViewModel {
  late ProfileRepository _repository;

  @override
  FutureOr<ProfileState> build() async {
    _repository = ref.read(profileRepositoryProvider);
    final profile = await _repository.get();
    return ProfileState(profile: profile);
  }

  Future<void> updateProfile({
    String? email,
    String? name,
    String? avatar,
  }) async {
    state = const AsyncValue.loading();
    try {
      final newAvatarPath = await saveImage(avatar);
      final currentProfile = state.value?.profile;

      final updatedProfile = currentProfile?.copyWith(
            email: email ?? currentProfile.email,
            name: name ?? currentProfile.name,
            avatar: newAvatarPath ?? currentProfile.avatar,
          ) ??
          Profile(
            email: email,
            name: name,
            avatar: newAvatarPath,
          );
      debugPrint(
          '${Constants.tag} [ProfileViewModel.updateProfile] $updatedProfile');

      await _repository.update(updatedProfile);
      state = AsyncData(ProfileState(profile: updatedProfile));
    } catch (error) {
      state = AsyncError(error, StackTrace.current);
    }
  }

  Future<void> refreshProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repository.get();
      state = AsyncData(ProfileState(profile: profile));
    } catch (error) {
      state = AsyncError(error, StackTrace.current);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authenticationViewModelProvider.notifier).signOut();
      state = AsyncData(ProfileState(profile: null));
    } catch (error) {
      state = AsyncError(error, StackTrace.current);
    }
  }

  Future<bool> isShowPremium() async {
    if (state.value?.profile?.isPremium == true) return false;
    return _repository.isShowPremium();
  }

  Future<void> setIsShowPremium() async {
    await _repository.setIsShowPremium();
  }

  Future<String?> selectImage(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      return image?.path;
    } catch (error) {
      if (context.mounted) {
        context.showErrorSnackBar(error.toString());
      }
      return null;
    }
  }

  Future<String?> saveImage(String? image) async {
    if (image == null || image.isUrl) return image;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final extension = path.extension(image);
      final File newFile = File('${directory.path}/$fileName$extension');

      final File originalFile = File(image);
      await originalFile.copy(newFile.path);

      return newFile.path;
    } catch (error) {
      return null;
    }
  }
}
