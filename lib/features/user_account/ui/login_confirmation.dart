import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_mvvm_riverpod/core/constants/assets.dart';
import 'package:flutter_mvvm_riverpod/core/routing/routes.dart';
import 'package:flutter_mvvm_riverpod/core/theme/app_theme.dart';
import 'package:flutter_mvvm_riverpod/features/common/remote/supabase_client.dart';
import 'package:flutter_mvvm_riverpod/features/common/ui/widgets/primary_button.dart';

/// The existing verification route, presented as an email-confirmation screen.
class OtpScreen extends StatefulWidget {
  final String email;

  const OtpScreen({
    super.key,
    required this.email,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = supabase.auth.onAuthStateChange.listen((state) {
      if (state.session != null) _continueToPassword();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (supabase.auth.currentSession != null) _continueToPassword();
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  void _checkSession() {
    if (supabase.auth.currentSession != null) {
      _continueToPassword();
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Verification is not complete yet. Open the link in your email.',
          ),
        ),
      );
  }

  void _continueToPassword() {
    if (mounted) context.go(Routes.setPassword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SvgPicture.asset(
                  Assets.otp,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.bottomCenter,
                  semanticsLabel: 'Email confirmation',
                ),
              ),
              Text('Check Your Email', style: AppTheme.title20),
              const SizedBox(height: 8),
              Text(
                'We sent a confirmation link to:',
                style: AppTheme.body16,
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  widget.email,
                  textAlign: TextAlign.center,
                  style: AppTheme.body16.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Please open your email and click the confirmation link to '
                'verify your account. Then return here and log in.',
                style: AppTheme.body16,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: "I've Verified My Email",
                isEnable: true,
                onPressed: _checkSession,
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => context.go(Routes.login),
                  child: const Text('Back to Login'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
