import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../extensions/build_context_extension.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../view_model/onboarding_view_model.dart';

class InviteCodeScreen extends ConsumerStatefulWidget {
  const InviteCodeScreen({super.key});

  @override
  ConsumerState<InviteCodeScreen> createState() => _InviteCodeScreenState();
}

class _InviteCodeScreenState extends ConsumerState<InviteCodeScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    super.dispose();
  }

  void _onCodeChanged() {
    ref.read(onboardingViewModelProvider.notifier)
        .updateInviteCode(_codeController.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingViewModelProvider);
    final viewModel = ref.read(onboardingViewModelProvider.notifier);

    if (state.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.showErrorSnackBar(state.error!);
        viewModel.clearError();
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // UPDATED: Header is now a centered logo, no back button
              SizedBox(
                height: 40,
                child: Align(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'authentick',
                        style: AppTheme.title18.copyWith(
                          color: AppColors.mono100,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.blueberry100,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(flex: 1),
              
              Text(
                'Enter your invite code',
                style: AppTheme.title24.copyWith(
                  color: AppColors.mono100,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              TextField(
                controller: _codeController,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mono100,
                  letterSpacing: 8.0, // Creates space between characters
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: '--------', // Dashes as hint
                  hintStyle: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mono40,
                    letterSpacing: 8.0,
                  ),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              
              const Spacer(flex: 2),
              
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: state.inviteCode.isNotEmpty ? viewModel.submitInviteCode : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6D28D9),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFEDE9FF),
                    disabledForegroundColor: const Color(0xFFC4B5FD),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                  ),
                  child: const Text('Get started', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: viewModel.skipInviteCode,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6D28D9),
                    side: const BorderSide(color: Color(0xFF6D28D9), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                  ),
                  child: const Text('I don\'t have an invite code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTheme.body12.copyWith(color: AppColors.mono60, height: 1.4),
                    children: [
                      const TextSpan(text: 'By continuing, you agree to Authentick\'s '),
                      TextSpan(text: 'EULA', style: AppTheme.body12.copyWith(color: AppColors.blueberry100)),
                      const TextSpan(text: ', '),
                      TextSpan(text: 'terms of service', style: AppTheme.body12.copyWith(color: AppColors.blueberry100)),
                      const TextSpan(text: ' and '),
                      TextSpan(text: 'privacy policy', style: AppTheme.body12.copyWith(color: AppColors.blueberry100)),
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