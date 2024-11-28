String? notEmptyEmailValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Required field, please enter a valid value';
  }

  if (!isValidEmail(value.trim())) {
    return 'Invalid email format, please try again';
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
