const passwordRequirementsMessage =
    'Use at least 8 characters, including one uppercase letter, one lowercase letter, one number, and one special character.';

String? validatePassword(String? value) {
  final password = value ?? '';
  if (password.length < 8) return 'Password must be at least 8 characters';
  if (!RegExp(r'[A-Z]').hasMatch(password)) {
    return 'Password must contain an uppercase letter';
  }
  if (!RegExp(r'[a-z]').hasMatch(password)) {
    return 'Password must contain a lowercase letter';
  }
  if (!RegExp(r'[0-9]').hasMatch(password)) {
    return 'Password must contain a number';
  }
  if (!RegExp(r'[^A-Za-z0-9\s]').hasMatch(password)) {
    return 'Password must contain a special character';
  }
  return null;
}
