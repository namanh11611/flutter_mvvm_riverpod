import '../../model/user_account_model.dart';

class UserAccountState {
  final UserAccountPage page;
  final UserAccount? user; // Using your exact class name 'UserAccount'
  final bool isLoading;
  final String? error;

  const UserAccountState({
    this.page = UserAccountPage.profile,
    this.user,
    this.isLoading = false,
    this.error,
  });

  UserAccountState copyWith({
    UserAccountPage? page,
    UserAccount? user,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return UserAccountState(
      page: page ?? this.page,
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAccountState &&
          runtimeType == other.runtimeType &&
          page == other.page &&
          user == other.user &&
          isLoading == other.isLoading &&
          error == other.error;

  @override
  int get hashCode =>
      page.hashCode ^ user.hashCode ^ isLoading.hashCode ^ error.hashCode;
}
