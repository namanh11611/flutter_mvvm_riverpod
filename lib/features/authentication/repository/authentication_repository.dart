import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_mvvm_riverpod/constants/constants.dart';
import 'package:flutter_mvvm_riverpod/environment/env.dart';
import 'package:flutter_mvvm_riverpod/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'authentication_repository.g.dart';

@riverpod
AuthenticationRepository authenticationRepository(Ref ref) {
  return AuthenticationRepository();
}

class AuthenticationRepository {
  const AuthenticationRepository();

  Future<AsyncValue?> loginWithGoogle() async {
    // TODO: fake data
    return AsyncData(AuthResponse(
      user: User(
        id: '',
        appMetadata: {},
        userMetadata: {},
        aud: '',
        createdAt: '',
        email: 'henry@google.com',
      ),
    ));

    try {
      const List<String> scopes = <String>[
        Constants.googleEmailScope,
        Constants.googleUserInfoScope,
      ];

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: Env.googleClientId,
        serverClientId: Env.googleServerClientId,
        scopes: scopes,
      );
      final googleUser = await googleSignIn.signIn();
      final googleAuth = await googleUser!.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        return AsyncError('access_token_not_found'.tr(), StackTrace.current);
      }

      if (idToken == null) {
        return AsyncError('id_token_not_found'.tr(), StackTrace.current);
      }

      final result = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      return AsyncData(result);
    } on AuthException catch (error) {
      return AsyncError(error.message, StackTrace.current);
    } catch (error) {
      return AsyncError('unexpected_error_occurred'.tr(), StackTrace.current);
    }
  }

  Future<AsyncValue?> loginWithApple() async {
    // TODO: fake data
    return AsyncData(AuthResponse(
      user: User(
        id: '',
        appMetadata: {},
        userMetadata: {},
        aud: '',
        createdAt: '',
        email: 'henry@apple.com',
      ),
    ));

    try {
      final rawNonce = supabase.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        return AsyncError('id_token_not_found'.tr(), StackTrace.current);
      }

      final result = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
      return AsyncData(result);
    } on AuthException catch (error) {
      return AsyncError(error.message, StackTrace.current);
    } catch (error) {
      return AsyncError('unexpected_error_occurred'.tr(), StackTrace.current);
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
}
