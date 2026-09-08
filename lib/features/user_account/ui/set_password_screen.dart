import 'package:flutter_mvvm_riverpod/core/utils/password_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/routes.dart';
import '../../common/remote/supabase_client.dart';
import 'view_model/authentication_view_model.dart';

const _purple = Color(0xFF7C3AED);
const _ink = Color(0xFF281950);
const _border = Color(0xFFD5CFEF);
const _muted = Color(0xFF686082);

class SetPasswordScreen extends ConsumerStatefulWidget {
  const SetPasswordScreen({super.key, this.isRecovery = false});

  final bool isRecovery;

  @override
  ConsumerState<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends ConsumerState<SetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final viewModel = ref.read(authenticationViewModelProvider.notifier);
    final succeeded = widget.isRecovery
        ? await viewModel.updateRecoveredPassword(_passwordController.text)
        : await viewModel.setPassword(_passwordController.text);
    if (!mounted) return;
    if (succeeded) {
      if (widget.isRecovery) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully. Please sign in.'),
          ),
        );
        context.go(Routes.login);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful. Please sign in.'),
          ),
        );
        context.go(Routes.login);
      }
      return;
    }
    final result = ref.read(authenticationViewModelProvider);
    final message = switch (result) {
      AsyncError(:final error) => _readableError(error),
      _ =>
        widget.isRecovery
            ? 'Unable to reset your password. Please try again.'
            : 'Unable to save your password. Please try again.',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authenticationViewModelProvider).isLoading;
    if (widget.isRecovery && supabase.auth.currentSession == null) {
      return const _InvalidRecoveryLinkView();
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _BrandHeader(),
                const SizedBox(height: 48),
                Text(
                  widget.isRecovery ? 'Reset Password' : 'Create Password',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 32,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  widget.isRecovery
                      ? 'Enter and confirm your new password.'
                      : 'Your email is verified. Create a password to finish setup.',
                  style: const TextStyle(color: _muted, fontSize: 15),
                ),
                const SizedBox(height: 34),
                _PasswordField(
                  label: widget.isRecovery ? 'New Password' : 'Password',
                  hint: widget.isRecovery
                      ? 'Enter your new password'
                      : 'Enter your password',
                  controller: _passwordController,
                  obscure: _obscurePassword,
                  onToggle: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 20),
                _PasswordField(
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  controller: _confirmPasswordController,
                  obscure: _obscureConfirmation,
                  onToggle: () => setState(
                    () => _obscureConfirmation = !_obscureConfirmation,
                  ),
                  validator: (value) {
                    final passwordError = _validatePassword(value);
                    if (passwordError != null) return passwordError;
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _savePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _purple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.isRecovery ? 'Reset Password' : 'Continue',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InvalidRecoveryLinkView extends StatelessWidget {
  const _InvalidRecoveryLinkView();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_off_rounded, color: _muted, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Reset link unavailable',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'This password reset link is invalid or expired. Request '
                'a new link and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, height: 1.5),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () => context.go(Routes.forgotPassword),
                child: const Text('Request New Link'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      DecoratedBox(
        decoration: BoxDecoration(color: _purple, shape: BoxShape.circle),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(Icons.explore_rounded, color: Colors.white, size: 21),
        ),
      ),
      SizedBox(width: 10),
      Text(
        'GoBuddy',
        style: TextStyle(
          color: _ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    required this.validator,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: _ink,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _muted),
          suffixIcon: IconButton(
            tooltip: obscure ? 'Show password' : 'Hide password',
            onPressed: onToggle,
            icon: Icon(
              obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: _muted,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: _inputBorder,
          enabledBorder: _inputBorder,
          focusedBorder: _inputBorder.copyWith(
            borderSide: const BorderSide(color: _purple, width: 1.5),
          ),
        ),
      ),
    ],
  );
}

String? _validatePassword(String? value) => validatePassword(value);

String _readableError(Object error) {
  final message = error.toString();
  return message.startsWith('Exception: ')
      ? message.substring('Exception: '.length)
      : message;
}

final _inputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(14),
  borderSide: const BorderSide(color: _border),
);
