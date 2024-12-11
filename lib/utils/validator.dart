import 'package:easy_localization/easy_localization.dart';

String? notEmptyEmailValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'validator_required_field'.tr();
  }

  if (!isValidEmail(value.trim())) {
    return 'validator_invalid_email_format'.tr();
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
