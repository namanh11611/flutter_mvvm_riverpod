import 'package:easy_localization/easy_localization.dart';

import '../generated/locale_keys.g.dart';

String? notEmptyNameValidator(String? value) {
  return value == null || value.trim().isEmpty
      ? LocaleKeys.validatorRequiredField.tr()
      : null;
}

String? notEmptyEmailOrPhoneValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return LocaleKeys.validatorRequiredField.tr();
  }

  if (!isValidEmailOrPhone(value.trim())) {
    return LocaleKeys.validatorInvalidEmailOrPhoneFormat.tr();
  }

  // Return null if the value is valid
  return null;
}

bool isValidEmailOrPhone(String value) {
  return isValidEmail(value) || isValidPhone(value);
}

String? notEmptyEmailValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return LocaleKeys.validatorRequiredField.tr();
  }

  if (!isValidEmail(value.trim())) {
    return LocaleKeys.validatorInvalidEmailFormat.tr();
  }

  // Return null if the value is valid
  return null;
}

bool isValidEmail(String email) {
  // Define a regex pattern to match email format
  final regExp =
      RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(\.[a-zA-Z]+)+$");
  return regExp.hasMatch(email);
}

String? notEmptyPhoneValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return LocaleKeys.validatorRequiredField.tr();
  }

  if (!isValidPhone(value.trim())) {
    return LocaleKeys.validatorInvalidPhoneFormat.tr();
  }

  // Return null if the value is valid
  return null;
}

bool isValidPhone(String phone) {
  final regExp = RegExp(r"^0[0-9]{9}$");
  return regExp.hasMatch(phone);
}

String? confirmPasswordValidator(String? password, String? confirmPassword) {
  if (password == null ||
      password.isEmpty ||
      confirmPassword == null ||
      confirmPassword.isEmpty) {
    return LocaleKeys.validatorRequiredField.tr();
  }

  if (password != confirmPassword) {
    return LocaleKeys.validatorPasswordNotMatch.tr();
  }

  return null;
}
