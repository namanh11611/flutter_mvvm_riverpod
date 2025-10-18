import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/constants.dart';
import '../../../features/profile/model/profile.dart';
import '../../../utils/utils.dart';

part 'profile_repository.g.dart';

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) {
  return ProfileRepository();
}

class ProfileRepository {
  const ProfileRepository();

  Future<Profile?> get() async {
    // TODO: temporary get profile from local
    final prefs = await SharedPreferences.getInstance();
    final profileStr = prefs.getString(Constants.profileKey);
    if (profileStr == null) return null;

    final profile = Profile.fromJson(jsonDecode(profileStr));
    return profile;
  }

  Future<void> update(Profile profile) async {
    // TODO: temporary save profile to local
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(Constants.profileKey, jsonEncode(profile.toJson()));
    // TODO: Implement with your own backend
  }

  Future<bool> isShowPremium() async {
    final prefs = await SharedPreferences.getInstance();
    final day = prefs.getString(Constants.lastDayShowPremiumKey);
    if (day == null) return true;
    return Utils.today().difference(DateTime.parse(day)).inDays >= 3;
  }

  Future<void> setIsShowPremium() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      Constants.lastDayShowPremiumKey,
      Utils.today().toIso8601String(),
    );
  }
}
