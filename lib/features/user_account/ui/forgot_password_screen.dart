import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mvvm_riverpod/core/extensions/build_context_extension.dart';
import 'package:flutter_mvvm_riverpod/core/routing/routes.dart';
import 'package:flutter_mvvm_riverpod/core/theme/app_colors.dart';
import 'package:flutter_mvvm_riverpod/core/theme/app_theme.dart';
import 'package:flutter_mvvm_riverpod/core/utils/validator.dart';
import 'view_model/authentication_view_model.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String? _resetEmail;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final sent = await ref
        .read(authenticationViewModelProvider.notifier)
        .sendPasswordResetEmail(_emailController.text.trim());

    if (!mounted) return;
    if (!sent) {
      final result = ref.read(authenticationViewModelProvider);
      final message = switch (result) {
        AsyncError(:final error) => _readableError(error),
        _ => 'Unable to send the reset link. Please try again.',
      };
      context.showErrorSnackBar(message);
      return;
    }
    setState(() => _resetEmail = _emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authenticationViewModelProvider).isLoading;
    if (_resetEmail case final email?) {
      return _CheckResetEmailView(email: email, onBackToLogin: _goToLogin);
    }

    return Scaffold(
      backgroundColor: AppColors.brandBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).vertical -
                  44,
            ),
            child: IntrinsicHeight(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: isLoading ? null : _goToLogin,
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      label: const Text('Back to Login'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.brandPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(44, 44),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: AppColors.brandBorder,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mail_outline_rounded,
                          color: AppColors.brandSurface,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Text(
                        'Forgot Password?',
                        textAlign: TextAlign.center,
                        style: AppTheme.title32.copyWith(
                          color: AppColors.brandPrimary,
                          fontFamily: 'Georgia',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        "No worries! Enter your email address and we'll send "
                        'you a link to reset your password.',
                        textAlign: TextAlign.center,
                        style: AppTheme.body16.copyWith(
                          color: AppColors.brandTextMuted,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Email Address',
                      style: AppTheme.title14.copyWith(
                        color: AppColors.brandPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      validator: notEmptyEmailValidator,
                      onFieldSubmitted:
                          isLoading ? null : (_) => _sendResetLink(),
                      decoration: InputDecoration(
                        hintText: 'example@email.com',
                        hintStyle: AppTheme.body16.copyWith(
                          color: AppColors.brandTextMuted,
                        ),
                        prefixIcon: const Icon(
                          Icons.mail_outline_rounded,
                          color: AppColors.brandTextMuted,
                        ),
                        filled: true,
                        fillColor: AppColors.brandBackground,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: _inputBorder,
                        enabledBorder: _inputBorder,
                        focusedBorder: _inputBorder.copyWith(
                          borderSide: const BorderSide(
                            color: AppColors.brandSurface,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _sendResetLink,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandSurface,
                          foregroundColor: AppColors.brandBackground,
                          disabledBackgroundColor: AppColors.brandBorder,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.brandBackground,
                                ),
                              )
                            : const Text(
                                'Send Reset Link',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 32),
                    Center(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment: WrapAlignment.center,
                        children: [
                          Text(
                            'Remember your password? ',
                            style: AppTheme.body14.copyWith(
                              color: AppColors.brandTextMuted,
                            ),
                          ),
                          TextButton(
                            onPressed: isLoading ? null : _goToLogin,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.brandSurface,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(44, 44),
                            ),
                            child: const Text(
                              'Log in',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _goToLogin() => context.go(Routes.login);
}

class _CheckResetEmailView extends StatelessWidget {
  const _CheckResetEmailView({
    required this.email,
    required this.onBackToLogin,
  });

  final String email;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.brandBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.brandBorder,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    color: AppColors.brandSurface,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Check Your Email',
                  textAlign: TextAlign.center,
                  style: AppTheme.title32.copyWith(
                    color: AppColors.brandPrimary,
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'If an account exists for this email, a password reset link '
                  'has been sent to:',
                  textAlign: TextAlign.center,
                  style: AppTheme.body16.copyWith(
                    color: AppColors.brandTextMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: AppTheme.title14.copyWith(
                    color: AppColors.brandPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Open the email and tap the reset link to create a new '
                  'password.',
                  textAlign: TextAlign.center,
                  style: AppTheme.body14.copyWith(
                    color: AppColors.brandTextMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: onBackToLogin,
                    child: const Text('Back to Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

final _inputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(16),
  borderSide: const BorderSide(color: AppColors.brandBorder),
);

String _readableError(Object error) {
  final message = error.toString();
  return message.startsWith('Exception: ')
      ? message.substring('Exception: '.length)
      : message;
}
