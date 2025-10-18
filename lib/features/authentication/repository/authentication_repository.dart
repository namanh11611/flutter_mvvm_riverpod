import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '/constants/constants.dart';
import '/constants/languages.dart';
import '/environment/env.dart';

part 'authentication_repository.g.dart';

@riverpod
AuthenticationRepository authenticationRepository(Ref ref) {
  return AuthenticationRepository();
}

class AuthenticationRepository {
  const AuthenticationRepository();

  Future<void> signInWithMagicLink(String email) async {
    // TODO: Implement with your own backend
    throw Exception('Magic link authentication not implemented yet');
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String token,
    required bool isRegister,
  }) async {
    // TODO: Implement with your own backend
    // Return a mock user object for now
    return {
      'user': {
        'id': 'mock_user_id',
        'email': email,
        'created_at': DateTime.now().toIso8601String(),
      },
    };
  }

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;

      // Initialize with server client ID (required for Android)
      await googleSignIn.initialize(serverClientId: Env.googleServerClientId);

      // Authenticate the user
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('id_token_not_found'.tr());
      }

      // TODO: Send the ID token to your own backend for verification
      // For now, return a mock response
      return {
        'user': {
          'id': googleUser.id,
          'email': googleUser.email,
          'name': googleUser.displayName,
          'avatar_url': googleUser.photoUrl,
          'created_at': DateTime.now().toIso8601String(),
        },
      };
    } catch (error, stackTrace) {
      debugPrint(
        '${Constants.tag} [AuthenticationRepository.signInWithGoogle] Error: $error',
      );
      debugPrint(
        '${Constants.tag} [AuthenticationRepository.signInWithGoogle] StackTrace: $stackTrace',
      );
      throw Exception('$error');
    }
  }

  Future<Map<String, dynamic>> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw Exception('id_token_not_found'.tr());
      }

      // TODO: Send the ID token to your own backend for verification
      // For now, return a mock response
      return {
        'user': {
          'id': credential.userIdentifier ?? 'apple_user_id',
          'email': credential.email ?? 'user@apple.com',
          'name': '${credential.givenName ?? ''} ${credential.familyName ?? ''}'
              .trim(),
          'created_at': DateTime.now().toIso8601String(),
        },
      };
    } catch (error) {
      throw Exception(Languages.unexpectedErrorOccurred);
    }
  }

  Future<void> signOut() async {
    try {
      // TODO: Implement with your own backend
      setIsLogin(false);
      Purchases.logOut();
    } catch (error) {
      throw Exception(Languages.unexpectedErrorOccurred);
    }
  }

  Future<bool> isLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(Constants.isLoginKey) ?? false;
  }

  Future<void> setIsLogin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Constants.isLoginKey, value);
  }

  Future<bool> isExistAccount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(Constants.isExistAccountKey) ?? false;
  }

  Future<void> setIsExistAccount(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Constants.isExistAccountKey, value);
  }

  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(Constants.hasCompletedOnboardingKey) ?? false;
  }

  Future<void> setHasCompletedOnboarding(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Constants.hasCompletedOnboardingKey, value);
  }
}
