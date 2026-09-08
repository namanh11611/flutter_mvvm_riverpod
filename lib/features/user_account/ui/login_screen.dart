import 'package:flutter_mvvm_riverpod/core/utils/password_policy.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/assets.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../common/remote/supabase_client.dart';
import '../repository/authentication_repository.dart';
import 'view_model/authentication_view_model.dart';

const _purple = AppColors.brandSurface;
const _ink = AppColors.brandPrimary;
const _lightPurple = AppColors.brandBorder;
const _muted = AppColors.brandTextMuted;

/// A self-contained sign-in interface for the User Account module.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    super.key,
    this.onContinue,
    this.onForgotPassword,
    this.onGoogleSignIn,
    this.onSignUp,
  });

  final ValueChanged<String>? onContinue;
  final VoidCallback? onForgotPassword;
  final VoidCallback? onGoogleSignIn;
  final VoidCallback? onSignUp;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSigningIn = false;
  bool _isRoutingAfterGoogleSignIn = false;
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = supabase.auth.onAuthStateChange.listen((state) {
      if (state.session != null) {
        _handleAuthenticatedSession(
          allowOAuthRouting: state.event != AuthChangeEvent.initialSession,
        );
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (supabase.auth.currentSession != null) {
        // A verified registration link may restore its temporary session
        // before this widget subscribes. Only resume Set Password here; a
        // normal persisted session must not bypass the requested Login page.
        _handleAuthenticatedSession(allowOAuthRouting: false);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuthenticatedSession({
    required bool allowOAuthRouting,
  }) async {
    if (_isRoutingAfterGoogleSignIn) return;

    final repository = ref.read(authenticationRepositoryProvider);
    final pending = await repository.isRegistrationPending();
    if (!mounted) return;
    if (pending) {
      context.go(Routes.setPassword);
      return;
    }
    if (!allowOAuthRouting) return;

    final user = supabase.auth.currentUser;
    final provider = user?.appMetadata['provider'];
    final providers = user?.appMetadata['providers'];
    final hasGoogleIdentity =
        provider == 'google' ||
        (providers is List && providers.contains('google')) ||
        (user?.identities?.any((identity) => identity.provider == 'google') ??
            false);
    if (!hasGoogleIdentity) return;

    _isRoutingAfterGoogleSignIn = true;
    try {
      final hasCompletedOnboarding = await ref
          .read(authenticationViewModelProvider.notifier)
          .hasCompletedProfileOnboarding();
      if (mounted) {
        context.go(
          hasCompletedOnboarding ? Routes.main : Routes.profileOnboarding,
        );
      }
    } catch (_) {
      _isRoutingAfterGoogleSignIn = false;
      if (mounted) {
        _showMessage(
          'Google sign-in succeeded, but your profile could not be loaded. '
          'Please try again.',
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (widget.onGoogleSignIn != null) {
      widget.onGoogleSignIn!();
      return;
    }

    final started = await ref
        .read(authenticationViewModelProvider.notifier)
        .signInWithGoogle();
    if (started || !mounted) return;
    final result = ref.read(authenticationViewModelProvider);
    final message = switch (result) {
      AsyncError(:final error) => _readableError(error),
      _ => 'Unable to start Google sign-in. Please try again.',
    };
    _showMessage(message);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSigningIn = true);

    try {
      final email = _emailController.text.trim();
      await supabase.auth.signInWithPassword(
        email: email,
        password: _passwordController.text,
      );
      widget.onContinue?.call(email);
      final repository = const AuthenticationRepository();
      final pending = await repository.isRegistrationPending();
      final hasCompletedOnboarding = pending
          ? false
          : await repository.hasCompletedProfileOnboarding();
      if (mounted) {
        context.go(
          pending
              ? Routes.setPassword
              : hasCompletedOnboarding
              ? Routes.main
              : Routes.profileOnboarding,
        );
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_friendlyLoginError(error))));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to sign in. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGoogleSigningIn = ref
        .watch(authenticationViewModelProvider)
        .isLoading;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height - 104,
            ),
            child: IntrinsicHeight(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _BrandHeader(),
                    const SizedBox(height: 38),
                    const Text(
                      'Welcome back!',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 32,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 9),
                    const Text(
                      'Sign in to continue your adventure',
                      style: TextStyle(color: _muted, fontSize: 15),
                    ),
                    const SizedBox(height: 34),
                    _LoginField(
                      label: 'Email Address',
                      controller: _emailController,
                      hint: 'example@email.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 20),
                    _LoginField(
                      label: 'Password',
                      controller: _passwordController,
                      hint: 'Enter your password',
                      obscureText: _obscurePassword,
                      validator: _validatePassword,
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: _muted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSigningIn ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _purple,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSigningIn
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Continue',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed:
                            widget.onForgotPassword ??
                            () => context.push(Routes.forgotPassword),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _purple,
                          side: const BorderSide(color: _lightPurple),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const _SocialDivider(),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: isGoogleSigningIn || _isSigningIn
                            ? null
                            : _signInWithGoogle,
                        icon: SizedBox(
                          width: 22,
                          height: 22,
                          child: SvgPicture.asset(Assets.googleLogo),
                        ),
                        label: isGoogleSigningIn
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _purple,
                                ),
                              )
                            : const Text(
                                'Continue with Google',
                                style: TextStyle(
                                  color: _ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _lightPurple),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(color: _muted),
                          ),
                          TextButton(
                            onPressed:
                                widget.onSignUp ??
                                () => context.push(Routes.register),
                            style: TextButton.styleFrom(
                              foregroundColor: _purple,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Sign up now',
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
}

String? _validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
    return 'Enter a valid email address';
  }
  return null;
}

String? _validatePassword(String? value) => validatePassword(value);

String _friendlyLoginError(AuthException error) {
  final message = error.message.toLowerCase();
  if (message.contains('banned') || error.code == 'user_banned') {
    return 'Your account has been banned.';
  }
  if (message.contains('email not confirmed') ||
      message.contains('email_not_confirmed')) {
    return 'Please confirm your email before signing in.';
  }
  if (message.contains('invalid login credentials') ||
      message.contains('invalid credentials')) {
    return 'The email or password is incorrect.';
  }
  if (message.contains('network') ||
      message.contains('socket') ||
      message.contains('connection')) {
    return 'Unable to connect. Check your internet connection and try again.';
  }
  return 'Unable to sign in. Please try again.';
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

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.label,
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

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
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _muted),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          enabledBorder: _inputBorder,
          focusedBorder: _inputBorder.copyWith(
            borderSide: const BorderSide(color: _purple, width: 1.5),
          ),
          errorBorder: _inputBorder.copyWith(
            borderSide: const BorderSide(color: _purple),
          ),
          focusedErrorBorder: _inputBorder.copyWith(
            borderSide: const BorderSide(color: _purple, width: 1.5),
          ),
        ),
      ),
    ],
  );
}

final _inputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(14),
  borderSide: const BorderSide(color: _lightPurple),
);

class _SocialDivider extends StatelessWidget {
  const _SocialDivider();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(child: Divider(color: _lightPurple)),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          'or continue with',
          style: TextStyle(color: _muted, fontSize: 12),
        ),
      ),
      Expanded(child: Divider(color: _lightPurple)),
    ],
  );
}
