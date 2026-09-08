import 'password_error.dart';
import '../../../core/utils/password_policy.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_mvvm_riverpod/core/constants/constants.dart';
import 'package:flutter_mvvm_riverpod/features/common/remote/supabase_client.dart';

part 'authentication_repository.g.dart';

@riverpod
AuthenticationRepository authenticationRepository(Ref ref) {
  return AuthenticationRepository();
}

class AuthenticationRepository {
  const AuthenticationRepository();

  static Future<void>? _googleSignInInitialization;

  Future<void> sendRegistrationLink(String email) async {
    try {
      if (supabase.auth.currentSession != null) {
        await supabase.auth.signOut(scope: SignOutScope.local);
      }
      await supabase.auth.signInWithOtp(
        email: email.trim(),
        emailRedirectTo: Constants.supabaseLoginCallback,
        shouldCreateUser: true,
        data: const {'registration_pending': true},
      );
      await setRegistrationPending(true, email: email.trim());
    } on AuthException catch (error) {
      throw Exception(friendlyRegistrationError(error));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Unable to create account. Please try again.');
    }
  }

  Future<void> setPassword(String password) async {
    if (supabase.auth.currentSession == null) {
      throw Exception(
        'Your verification session is missing or expired. Request a new link.',
      );
    }
    try {
      await supabase.auth.updateUser(UserAttributes(password: password));
      await setRegistrationPending(false);
      // Email-link verification creates a session. End it so registration
      // always finishes at the normal login screen.
      // Email verification creates an authenticated session. End that
      // temporary session so registration finishes at the login screen and
      // the user explicitly signs in with the credentials they just created.
      await supabase.auth.signOut(scope: SignOutScope.local);
    } on AuthException catch (error) {
      throw Exception(
        passwordErrorMessage(
          error,
          fallback: 'Unable to save your password. Please try again.',
        ),
      );
    } catch (_) {
      throw Exception('Unable to save your password. Please try again.');
    }
  }

  Future<bool> isRegistrationPending() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getBool(Constants.registrationPendingKey) ?? false;
    final pendingEmail = prefs
        .getString(Constants.registrationPendingEmailKey)
        ?.toLowerCase();
    final currentEmail = supabase.auth.currentUser?.email?.toLowerCase();
    return pending && pendingEmail != null && pendingEmail == currentEmail;
  }

  Future<void> setRegistrationPending(bool value, {String? email}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Constants.registrationPendingKey, value);
    if (value && email != null) {
      await prefs.setString(Constants.registrationPendingEmailKey, email);
    } else if (!value) {
      await prefs.remove(Constants.registrationPendingEmailKey);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: Constants.supabasePasswordRecoveryCallback,
      );
    } on AuthException catch (error) {
      throw Exception(_friendlyPasswordRecoveryError(error));
    } catch (_) {
      throw Exception(
        'Unable to send the reset link. Check your connection and try again.',
      );
    }
  }

  Future<void> updateRecoveredPassword(String password) async {
    if (supabase.auth.currentSession == null) {
      throw Exception(
        'This password reset link is invalid or expired. Request a new link.',
      );
    }

    try {
      await supabase.auth.updateUser(UserAttributes(password: password));
      try {
        await supabase.auth.signOut(scope: SignOutScope.local);
      } catch (_) {
        // The password is already updated. Login navigation still prevents
        // continuing into the authenticated app from the recovery flow.
      }
    } on AuthException catch (error) {
      throw Exception(
        passwordErrorMessage(
          error,
          fallback: 'Unable to reset your password. Please try again.',
        ),
      );
    } catch (_) {
      throw Exception('Unable to reset your password. Please try again.');
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final email = supabase.auth.currentUser?.email;
    if (email == null || supabase.auth.currentSession == null) {
      throw Exception('Your session has expired. Please sign in again.');
    }
    if (oldPassword == newPassword) {
      throw Exception(
        'Your new password must be different from your old password.',
      );
    }

    try {
      // Supabase requires a fresh password sign-in to prove the current
      // password is valid before this sensitive account change.
      await supabase.auth.signInWithPassword(
        email: email,
        password: oldPassword,
      );
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (error) {
      final message = error.message.toLowerCase();
      if (error.code == 'invalid_credentials' ||
          message.contains('invalid login') ||
          message.contains('invalid credentials') ||
          message.contains('email or password')) {
        throw Exception('Your old password is incorrect.');
      }
      throw Exception(
        passwordErrorMessage(
          error,
          fallback: 'Unable to change your password. Please try again.',
        ),
      );
    } catch (error) {
      if (error is Exception) rethrow;
      throw Exception('Unable to change your password. Please try again.');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      // A pending email-link registration must never send a Google user to
      // the email-only Set Password flow.
      await setRegistrationPending(false);

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        // The browser OAuth flow can leave a blank Samsung Internet tab when
        // the custom-scheme redirect is handed back to Android. Use Google's
        // native account picker on Android and give its ID token to Supabase.
        await (_googleSignInInitialization ??= GoogleSignIn.instance.initialize(
          serverClientId: Constants.googleWebClientId,
        ));
        final googleUser = await GoogleSignIn.instance.authenticate();
        final idToken = googleUser.authentication.idToken;
        if (idToken == null || idToken.isEmpty) {
          throw Exception(
            'Google did not return a sign-in token. Please try again.',
          );
        }
        await supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
        );
        return;
      }

      final launched = await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        // On Flutter web, return to the port used by `flutter run` instead
        // of Supabase's project-wide Site URL (often localhost:3000).
        redirectTo: kIsWeb ? Uri.base.origin : Constants.supabaseLoginCallback,
      );
      if (!launched) {
        throw Exception('Unable to open Google sign-in. Please try again.');
      }
    } on GoogleSignInException catch (error) {
      switch (error.code) {
        case GoogleSignInExceptionCode.canceled:
          // Credential Manager also reports configuration failures as canceled.
          throw Exception(
            'Google sign-in did not complete. Please try again. '
            'If this keeps happening after selecting your account, contact support.',
          );
        case GoogleSignInExceptionCode.clientConfigurationError:
        case GoogleSignInExceptionCode.providerConfigurationError:
          throw Exception(
            'Google sign-in is not configured for this Android app. '
            'Add its package name and signing SHA fingerprints in Google Cloud.',
          );
        case GoogleSignInExceptionCode.interrupted:
        case GoogleSignInExceptionCode.uiUnavailable:
          throw Exception(
            'Google sign-in is unavailable on this device. Please try again.',
          );
        default:
          throw Exception('Unable to sign in with Google. Please try again.');
      }
    } on AuthException catch (error) {
      throw Exception(_friendlyGoogleSignInError(error));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Unable to start Google sign-in. Please try again.');
    }
  }

  Future<bool> hasCurrentUserProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Your sign-in session is missing. Please try again.');
    }

    try {
      final profile = await supabase
          .from('user_accounts')
          .select('display_name, date_of_birth')
          .eq('id', userId)
          .maybeSingle();
      if (profile == null) return false;
      final displayName = (profile['display_name'] as String?)?.trim() ?? '';
      final dateOfBirth = profile['date_of_birth'];
      return displayName.isNotEmpty &&
          dateOfBirth is String &&
          dateOfBirth.trim().isNotEmpty;
    } on PostgrestException {
      throw Exception(
        'Unable to load your profile. Check your connection and try again.',
      );
    }
  }

  Future<bool> hasCompletedProfileOnboarding() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Your sign-in session is missing. Please try again.');
    }

    try {
      // Admins do not need a traveller profile. Route guards enforce access.
      final access = await supabase.rpc<String>('get_account_access');
      if (access == 'admin' || access == 'banned' || access == 'suspended') {
        return true;
      }
      final profile = await supabase
          .from('user_accounts')
          .select('onboarding_completed')
          .eq('id', userId)
          .maybeSingle();
      return profile?['onboarding_completed'] == true;
    } on PostgrestException {
      throw Exception(
        'Unable to load your profile. Check your connection and try again.',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
      if (supabase.auth.currentSession != null ||
          supabase.auth.currentUser != null) {
        throw const AuthException('The Supabase session could not be cleared.');
      }

      try {
        await Purchases.logOut();
      } catch (_) {
        // Supabase is the authentication source of truth. A RevenueCat cleanup
        // failure must not restore or misreport an already-ended auth session.
      }
    } on AuthException {
      throw Exception('Unable to sign out. Please try again.');
    } catch (_) {
      throw Exception('Unable to sign out. Please try again.');
    }
  }

  Future<void> deleteAccount() async {
    if (supabase.auth.currentSession == null) {
      throw Exception('Your session has expired. Please sign in again.');
    }

    try {
      final response = await supabase.functions.invoke('delete-account');
      final data = response.data;
      if (data is! Map || data['deleted'] != true) {
        throw Exception('Unable to delete your account. Please try again.');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(Constants.isLoginKey);
      await prefs.remove(Constants.isExistAccountKey);
      await prefs.remove(Constants.isGuestModeKey);
      await prefs.remove(Constants.registrationPendingKey);
      await prefs.remove(Constants.registrationPendingEmailKey);
      try {
        await Purchases.logOut();
      } catch (_) {
        // Database deletion has already completed. Local third-party cleanup
        // must not report the account as still active.
      }
      try {
        await supabase.auth.signOut(scope: SignOutScope.local);
      } catch (_) {
        // Deleting auth.users invalidates the session on the server.
      }
    } on FunctionException catch (error) {
      final data = error.details;
      final message = data is Map ? data['error']?.toString() : null;
      throw Exception(
        message ?? 'Unable to delete your account. Please try again.',
      );
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Unable to delete your account. Please try again.');
    }
  }

  Future<bool> isLogin() async {
    return supabase.auth.currentUser != null;
  }

  // TODO: remove this when integrating real auth
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
  // END TODO

  Future<bool> isGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(Constants.isGuestModeKey) ?? false;
  }

  Future<void> setIsGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Constants.isGuestModeKey, true);
  }
}

@visibleForTesting
String friendlyRegistrationError(AuthException error) {
  final message = error.message.toLowerCase();
  switch (error.code) {
    case 'over_email_send_rate_limit':
    case 'over_request_rate_limit':
      return 'Too many verification requests. Please wait before trying again.';
    case 'email_address_not_authorized':
      return 'We cannot send verification emails to this address right now. Please contact support.';
    case 'email_address_invalid':
      return 'Please enter a valid email address.';
    case 'email_exists':
    case 'user_already_exists':
      return 'An account with this email already exists. Please log in instead.';
    case 'signup_disabled':
    case 'otp_disabled':
    case 'email_provider_disabled':
      return 'Email registration is currently unavailable. Please try again later.';
  }
  if (error.statusCode == '429' ||
      message.contains('rate limit') ||
      message.contains('too many requests') ||
      message.contains('after') && message.contains('seconds')) {
    return 'Too many verification requests. Please wait before trying again.';
  }
  if (message.contains('email') && message.contains('not authorized')) {
    return 'We cannot send verification emails to this address right now. Please contact support.';
  }
  if (message.contains('already registered') ||
      message.contains('already exists') ||
      message.contains('user already')) {
    return 'An account with this email already exists. Please log in instead.';
  }
  if (error.code == 'weak_password') {
    return passwordRequirementsMessage;
  }
  if (message.contains('invalid email') ||
      message.contains('email address') && message.contains('invalid')) {
    return 'Please enter a valid email address.';
  }
  if (message.contains('network') ||
      message.contains('socket') ||
      message.contains('connection')) {
    return 'Unable to connect. Check your internet connection and try again.';
  }
  return 'Unable to send the verification link. Please try again.';
}

String _friendlyGoogleSignInError(AuthException error) {
  final message = error.message.toLowerCase();
  if (message.contains('cancel')) {
    return 'Google sign-in was cancelled.';
  }
  if (message.contains('denied')) {
    return 'Google sign-in access was denied. Please try again or use another account.';
  }
  if (message.contains('network') ||
      message.contains('socket') ||
      message.contains('connection')) {
    return 'Unable to connect. Check your internet connection and try again.';
  }
  return 'Google sign-in failed. Please try again.';
}

String _friendlyPasswordRecoveryError(AuthException error) {
  final message = error.message.toLowerCase();
  if (message.contains('network') ||
      message.contains('socket') ||
      message.contains('connection')) {
    return 'Unable to connect. Check your internet connection and try again.';
  }
  return 'Unable to send the reset link. Please try again later.';
}
