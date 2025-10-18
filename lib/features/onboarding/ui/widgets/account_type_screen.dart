import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../extensions/build_context_extension.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../../common/ui/widgets/primary_button.dart';
import '../../model/onboarding_state.dart';
import '../../view_model/onboarding_view_model.dart';

class AccountTypeScreen extends ConsumerWidget {
  const AccountTypeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingViewModelProvider);
    final viewModel = ref.read(onboardingViewModelProvider.notifier);

    // Show error if any
    if (state.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.showErrorSnackBar(state.error!);
        viewModel.clearError();
      });
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF8F7FF),
            Color(0xFFEDE9FF),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: viewModel.goBack,
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: AppColors.mono80,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        'authentick',
                        style: AppTheme.title18.copyWith(
                          color: AppColors.mono100,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.check,
                        color: AppColors.blueberry100,
                        size: 20,
                      ),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), 
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Title
              Text(
                'Choose an account',
                style: AppTheme.title24.copyWith(
                  color: AppColors.mono100,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // Subtitle
              Text(
                'to continue to Authentick',
                style: AppTheme.body16.copyWith(
                  color: AppColors.mono80,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Account type options
              Expanded(
                child: Column(
                  children: [
                    _AccountTypeOption(
                      type: AccountType.personal,
                      title: 'Personal Account',
                      subtitle: 'For personal use',
                      icon: Icons.person_outline,
                      isSelected: state.selectedAccountType == AccountType.personal,
                      onTap: () => viewModel.selectAccountType(AccountType.personal),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _AccountTypeOption(
                      type: AccountType.business,
                      title: 'Business Account',
                      subtitle: 'For business use',
                      icon: Icons.business_outlined,
                      isSelected: state.selectedAccountType == AccountType.business,
                      onTap: () => viewModel.selectAccountType(AccountType.business),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _AccountTypeOption(
                      type: AccountType.creator,
                      title: 'Creator Account',
                      subtitle: 'Use another account',
                      icon: Icons.star_outline,
                      isSelected: state.selectedAccountType == AccountType.creator,
                      onTap: () => viewModel.selectAccountType(AccountType.creator),
                    ),
                  ],
                ),
              ),
              
              // Continue button
              PrimaryButton(
                text: 'Continue',
                onPressed: viewModel.completeOnboarding,
                isEnable: state.selectedAccountType != null,
              ),
              
              const SizedBox(height: 32),
              
              // Terms text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTheme.body12.copyWith(
                      color: AppColors.mono60,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(text: 'By continuing, you agree to Authentick\'s '),
                      TextSpan(
                        text: 'terms of service',
                        style: AppTheme.body12.copyWith(
                          color: AppColors.blueberry100,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'privacy policy',
                        style: AppTheme.body12.copyWith(
                          color: AppColors.blueberry100,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountTypeOption extends StatelessWidget {
  final AccountType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _AccountTypeOption({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.mono0,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.blueberry100 : AppColors.mono20,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Selection indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.blueberry100 : AppColors.mono40,
                  width: 2,
                ),
                color: isSelected ? AppColors.blueberry100 : AppColors.mono0,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: AppColors.mono0,
                      size: 16,
                    )
                  : null,
            ),
            
            const SizedBox(width: 16),
            
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.blueberry10 : AppColors.mono20,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.blueberry100 : AppColors.mono60,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.title16.copyWith(
                      color: AppColors.mono100,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTheme.body14.copyWith(
                      color: AppColors.mono60,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
