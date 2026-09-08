class SettingsState {
  const SettingsState({
    this.tripMatchNotificationsEnabled = true,
    this.isSigningOut = false,
    this.isDeletingAccount = false,
    this.error,
  });

  final bool tripMatchNotificationsEnabled;
  final bool isSigningOut;
  final bool isDeletingAccount;
  final String? error;

  SettingsState copyWith({
    bool? tripMatchNotificationsEnabled,
    bool? isSigningOut,
    bool? isDeletingAccount,
    String? error,
    bool clearError = false,
  }) {
    return SettingsState(
      tripMatchNotificationsEnabled:
          tripMatchNotificationsEnabled ?? this.tripMatchNotificationsEnabled,
      isSigningOut: isSigningOut ?? this.isSigningOut,
      isDeletingAccount: isDeletingAccount ?? this.isDeletingAccount,
      error: clearError ? null : error ?? this.error,
    );
  }
}
