import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mvvm_riverpod/core/routing/routes.dart';
import 'view_model/authentication_view_model.dart';

const _purple = Color(0xFF7C3AED);
const _ink = Color(0xFF281950);
const _lightPurple = Color(0xFFD5CFEF);
const _muted = Color(0xFF686082);

/// Email registration screen owned by the User Account module.
class RegisterAccountScreen extends ConsumerStatefulWidget {
  const RegisterAccountScreen({super.key});

  @override
  ConsumerState<RegisterAccountScreen> createState() =>
      _RegisterAccountScreenState();
}

class _RegisterAccountScreenState extends ConsumerState<RegisterAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _hasAcceptedLegalTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_hasAcceptedLegalTerms) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _emailController.text.trim();
    final succeeded = await ref
        .read(authenticationViewModelProvider.notifier)
        .sendRegistrationLink(email);
    if (!mounted) return;
    if (!succeeded) {
      final result = ref.read(authenticationViewModelProvider);
      final message = switch (result) {
        AsyncError(:final error) => _readableError(error),
        _ => 'Unable to create account. Please try again.',
      };
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    context.push(Routes.otp, extra: {'email': email, 'isRegister': true});
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authenticationViewModelProvider).isLoading;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height - 140,
            ),
            child: IntrinsicHeight(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _BrandHeader(),
                    const SizedBox(height: 40),
                    const Text('Create your account',
                        style: TextStyle(
                            color: _ink,
                            fontSize: 32,
                            height: 1.1,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 9),
                    const Text('Start planning meaningful journeys.',
                        style: TextStyle(color: _muted, fontSize: 15)),
                    const SizedBox(height: 34),
                    const Text('Email Address',
                        style: TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      decoration: InputDecoration(
                        hintText: 'example@email.com',
                        hintStyle: const TextStyle(color: _muted),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        enabledBorder: _inputBorder,
                        focusedBorder: _inputBorder.copyWith(
                          borderSide:
                              const BorderSide(color: _purple, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _LegalAgreement(
                      value: _hasAcceptedLegalTerms,
                      onChanged: (value) {
                        setState(() => _hasAcceptedLegalTerms = value);
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _hasAcceptedLegalTerms && !isLoading
                            ? _register
                            : null,
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
                            : const Text('Continue',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const Spacer(),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Already have an account? ',
                              style: TextStyle(color: _muted)),
                          TextButton(
                            onPressed: () => context.go(Routes.login),
                            style: TextButton.styleFrom(
                              foregroundColor: _purple,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Sign in',
                                style: TextStyle(fontWeight: FontWeight.w800)),
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
}

String? _validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
    return 'Enter a valid email address';
  }
  return null;
}

String _readableError(Object error) {
  final message = error.toString();
  return message.startsWith('Exception: ')
      ? message.substring('Exception: '.length)
      : message;
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) => const Row(children: [
        DecoratedBox(
          decoration: BoxDecoration(color: _purple, shape: BoxShape.circle),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(Icons.explore_rounded, color: Colors.white, size: 21),
          ),
        ),
        SizedBox(width: 10),
        Text('GoBuddy',
            style: TextStyle(
                color: _ink, fontSize: 20, fontWeight: FontWeight.w800)),
      ]);
}

final _inputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(14),
  borderSide: const BorderSide(color: _lightPurple),
);

class _LegalAgreement extends StatelessWidget {
  const _LegalAgreement({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: value,
          activeColor: _purple,
          onChanged: (checked) => onChanged(checked ?? false),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 11),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'I agree to the ',
                  style: TextStyle(color: _muted, height: 1.4),
                ),
                _LegalLink(
                  label: 'Terms of Service',
                  onTap: () => context.push(Routes.termsOfService),
                ),
                const Text(
                  ' and ',
                  style: TextStyle(color: _muted, height: 1.4),
                ),
                _LegalLink(
                  label: 'Privacy Policy',
                  onTap: () => context.push(Routes.privacyPolicy),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          color: _purple,
          height: 1.4,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
          decorationColor: _purple,
        ),
      ),
    );
  }
}
