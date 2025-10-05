enum OnboardingStep {
  intro,
  inviteCode,
  username,
  accountType,
  completed,
}

enum AccountType {
  personal,
  business,
  creator,
}

class OnboardingState {
  final OnboardingStep currentStep;
  final int introPageIndex;
  final String inviteCode;
  final String username;
  final AccountType? selectedAccountType;
  final bool isLoading;
  final String? error;

  const OnboardingState({
    this.currentStep = OnboardingStep.intro,
    this.introPageIndex = 0,
    this.inviteCode = '',
    this.username = '',
    this.selectedAccountType,
    this.isLoading = false,
    this.error,
  });

  OnboardingState copyWith({
    OnboardingStep? currentStep,
    int? introPageIndex,
    String? inviteCode,
    String? username,
    AccountType? selectedAccountType,
    bool? isLoading,
    String? error,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      introPageIndex: introPageIndex ?? this.introPageIndex,
      inviteCode: inviteCode ?? this.inviteCode,
      username: username ?? this.username,
      selectedAccountType: selectedAccountType ?? this.selectedAccountType,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
