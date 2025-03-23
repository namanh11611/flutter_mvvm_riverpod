import 'dart:io';

import 'package:easy_localization/easy_localization.dart';

class Languages {
  Languages._();

  // Common
  static String ok = 'ok'.tr();
  static String cancel = 'cancel'.tr();
  static String confirm = 'confirm'.tr();
  static String continueText = 'continue'.tr();
  static String noData = 'no_data'.tr();
  static String offline = 'offline'.tr();
  static String unexpectedErrorOccurred = 'unexpected_error_occurred'.tr();
  static String validatorRequiredField = 'validator_required_field'.tr();
  static String validatorInvalidEmailFormat = 'validator_invalid_email_format'.tr();

  // Auth
  static String welcome = 'welcome'.tr();
  static String alreadyHaveAccount = 'already_have_account'.tr();
  static String or = 'or'.tr();
  static String signIn = 'sign_in'.tr();
  static String register = 'register'.tr();
  static String google = 'google'.tr();
  static String signInWithGoogle = 'sign_in_with_google'.tr();
  static String apple = 'apple'.tr();
  static String signInWithApple = 'sign_in_with_apple'.tr();
  static String accessTokenNotFound = 'access_token_not_found'.tr();
  static String idTokenNotFound = 'id_token_not_found'.tr();
  static String signInAgreementPrefix = 'sign_in_agreement_prefix'.tr();
  static String signInAgreementMiddle = 'sign_in_agreement_middle'.tr();
  static String signInAgreementSuffix = 'sign_in_agreement_suffix'.tr();

  // Home
  static String goodMorning = 'good_morning';
  static String goodAfternoon = 'good_afternoon';
  static String goodEvening = 'good_evening';

  // Profile
  static String general = 'general'.tr();
  static String preferences = 'preferences'.tr();
  static String dangerousZone = 'dangerous_zone'.tr();
  static String accountInformation = 'account_information'.tr();
  static String selectAvatar = 'select_avatar'.tr();
  static String noPhotoPermissionError = 'no_photo_permission_error'.tr();
  static String email = 'email'.tr();
  static String name = 'name'.tr();
  static String appearances = 'appearances'.tr();
  static String auto = 'auto'.tr();
  static String lightMode = 'light_mode'.tr();
  static String darkMode = 'dark_mode'.tr();
  static String language = 'language'.tr();
  static String termOfService = 'term_of_service'.tr();
  static String privacyPolicy = 'privacy_policy'.tr();
  static String aboutUs = 'about_us'.tr();
  static String rateUs = 'rate_us'.tr();
  static String reportAProblem = 'report_a_problem'.tr();
  static String logOut = 'log_out'.tr();
  static String logOutTitle = 'log_out_title'.tr();
  static String logOutMessage = 'log_out_message'.tr();
  static String deleteAccount = 'delete_account'.tr();
  static String deleteAccountTitle = 'delete_account_title'.tr();
  static String deleteAccountMessage = 'delete_account_message'.tr();

  // Premium
  static String premium = 'premium'.tr();
  static String premiumLifetime = 'premium_lifetime'.tr();
  static String until = 'until'.tr();
  static String selectPlan = 'select_plan'.tr();
  static String premiumBenefits = 'premium_benefits'.tr();
  static String benefitTitle1 = 'benefit_title_1'.tr();
  static String benefitDescription1 = 'benefit_description_1'.tr();
  static String benefitTitle2 = 'benefit_title_2'.tr();
  static String benefitDescription2 = 'benefit_description_2'.tr();
  static String benefitTitle3 = 'benefit_title_3'.tr();
  static String benefitDescription3 = 'benefit_description_3'.tr();
  static String monthly = 'monthly'.tr();
  static String monthlyDescription = 'monthly_description'.tr();
  static String yearly = 'yearly'.tr();
  static String yearlyDescription = 'yearly_description'.tr();
  static String lifetime = 'lifetime'.tr();
  static String lifetimeDescription = 'lifetime_description'.tr();
  static String starter = 'starter'.tr();
  static String mostPopular = 'most_popular'.tr();
  static String bestPrice = 'best_price'.tr();
  static String premiumAgreementPrefix = 'premium_agreement_prefix'.tr();
  static String premiumAgreementMiddle = 'premium_agreement_middle'.tr();
  static String subscriptionInfo = Platform.isIOS
      ? 'subscription_info_ios'.tr()
      : 'subscription_info_android'.tr();
  static String restorePurchases = 'restore_purchases'.tr();
  static String fetchOfferingsError = 'fetch_offerings_error'.tr();
  static String packageNotFoundError = 'package_not_found_error'.tr();
  static String purchaseSuccess = 'purchase_success'.tr();
  static String purchaseError = 'purchase_error'.tr();
  static String restorePurchasesSuccess = 'restore_purchases_success'.tr();
  static String noActivePurchases = 'no_active_purchases'.tr();
  static String restorePurchasesError = 'restore_purchases_error'.tr();
}
