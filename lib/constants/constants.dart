class Constants {
  Constants._();

  static const String tag = 'FMR';

  static const String supabaseLoginCallback = 'com.areser.flutter_mvvm_riverpod://login-callback/';
  static const String supabaseProfileTable = 'profile';
  static const String googleEmailScope = 'email';
  static const String googleUserInfoScope = 'https://www.googleapis.com/auth/userinfo.profile';
  static const String defaultName = 'Guest';
  static const String termOfService = 'https://areser.net';
  static const String privacyPolicy = 'https://areser.net';
  static const String aboutUs = 'https://areser.net';
  static const String appStore = 'https://apps.apple.com/developer/id1760383102';
  static const String playStore = 'https://play.google.com/store/apps/developer?id=Areser+JSC';
  static const String reportProblem = 'mailto:areserjsc@gmail.com?subject=Report a Problem';
  static const String premium = 'premium';
  static const String premiumMonthly = '\$rc_monthly';
  static const String premiumYearly = '\$rc_annual';
  static const String premiumLifeTime = '\$rc_lifetime';

  // Route
  static const String isGoToMain = 'isGoToMain';

  // SharedPreferences key
  static const String themeModeKey = 'theme_mode_key';
  static const String profileKey = 'profile_key';
  static const String isLoginKey = 'is_login_key';
  static const String isExistAccountKey = 'is_exist_account_key';
  static const String isGuestModeKey = 'is_guest_mode_key';
  static const String wasShowOnboardingKey = 'was_show_onboarding_key';
  static const String isPremiumUserKey = 'is_premium_user_key';
  static const String lastDayShowPremiumKey = 'last_day_show_premium_key';
}
