import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../../../constants/assets.dart';
import '../../../authentication/ui/view_model/authentication_view_model.dart';
import '../../view_model/onboarding_view_model.dart';

class GoogleConnectScreen extends ConsumerWidget {
  const GoogleConnectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authenticationViewModelProvider);

    // Show error if authentication fails
    ref.listen(authenticationViewModelProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: ${next.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    final isLoading = authState.isLoading;

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
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Continue with',
                style: AppTheme.title24.copyWith(color: AppColors.mono100),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 260,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mono0,
                    foregroundColor: AppColors.mono100,
                    elevation: 0,
                    side: const BorderSide(color: AppColors.mono20),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isLoading
                      ? null
                      : () {
                          ref.read(authenticationViewModelProvider.notifier).signInWithGoogle();
                        },
                  icon: SizedBox(
                    width: 24,
                    height: 24,
                    child: SvgPicture.asset(Assets.googleLogo, fit: BoxFit.contain),
                  ),
                  label: Text(
                    'Sign up with Google',
                    style: AppTheme.title16.copyWith(color: AppColors.mono100),
                  ),
                ),
              ),
              if (isLoading) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
