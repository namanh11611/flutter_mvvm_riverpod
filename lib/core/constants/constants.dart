class Constants {
  Constants._();

  static const String tag = 'FMR';

  static const String supabaseLoginCallback = 'gobuddy://auth-callback/';
  static const String supabasePasswordRecoveryCallback =
      'gobuddy://reset-password/';
  static const String identityVerificationCallback =
      'gobuddy://app/identity-verification';
  static const String supabaseProfileTable = 'profile';
  static const String googleEmailScope = 'email';
  static const String googleUserInfoScope =
      'https://www.googleapis.com/auth/userinfo.profile';
  // Google OAuth web client used to mint an ID token for Supabase. OAuth
  // client IDs identify an application and are safe to include in the app.
  static const String googleWebClientId =
      '629920550859-237nfnfq28k8ej9tnpne1mnhqhsb7m5b.apps.googleusercontent.com';
  static const String defaultName = 'Guest';
  static const String termsOfService = 'https://areser.net';
  static const String privacyPolicy = 'https://areser.net';
  static const String aboutUs = 'https://areser.net';
  static const String appStore =
      'https://apps.apple.com/developer/id1760383102';
  static const String playStore =
      'https://play.google.com/store/apps/developer?id=Areser+JSC';
  static const String reportProblem =
      'mailto:areserjsc@gmail.com?subject=Report a Problem';
  static const String premium = 'premium';
  static const String premiumMonthly = '\$rc_monthly';
  static const String premiumAnnual = '\$rc_annual';
  static const String premiumLifeTime = '\$rc_lifetime';

  // Route
  static const String isGoToMain = 'isGoToMain';

  // SharedPreferences key
  static const String themeModeKey = 'theme_mode_key';
  static const String tripMatchNotificationsKey =
      'trip_match_notifications_enabled';
  static const String profileKey = 'profile_key';
  static const String isLoginKey = 'is_login_key';
  static const String isExistAccountKey = 'is_exist_account_key';
  static const String isGuestModeKey = 'is_guest_mode_key';
  static const String registrationPendingKey = 'registration_pending_key';
  static const String registrationPendingEmailKey =
      'registration_pending_email_key';
  static const String wasShowOnboardingKey = 'was_show_onboarding_key';
  static const String isPremiumUserKey = 'is_premium_user_key';
  static const String lastDayShowPremiumKey = 'last_day_show_premium_key';
}
