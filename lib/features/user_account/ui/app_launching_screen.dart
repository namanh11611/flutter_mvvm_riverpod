import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/routing/routes.dart';
import '../repository/authentication_repository.dart';

/// Fly design tokens sourced from `fly-DESIGN.md`.
const _flyBackground = Color(0xFFFFFFFF);
const _flyPrimary = Color(0xFF281950);
const _flyOnPrimary = Color(0xFFFFFFFF);
const _flySurface = Color(0xFF7C3AED);
const _flyTextMuted = Color(0xFF686082);

/// The application launch screen for the User Account module.
class AppLaunchingScreen extends StatefulWidget {
  const AppLaunchingScreen({super.key});

  @override
  State<AppLaunchingScreen> createState() => _AppLaunchingScreenState();
}

class _AppLaunchingScreenState extends State<AppLaunchingScreen>
    with SingleTickerProviderStateMixin {
  static const _displayDuration = Duration(milliseconds: 2200);
  static const _motionDuration = Duration(milliseconds: 300);

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _offset;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _motionDuration)
      ..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween<Offset>(
      begin: const Offset(0, .04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _navigationTimer = Timer(_displayDuration, _continueFromSplash);
  }

  Future<void> _continueFromSplash() async {
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      context.go(Routes.login);
      return;
    }

    final registrationPending =
        await const AuthenticationRepository().isRegistrationPending();
    if (!mounted) return;
    if (registrationPending) {
      context.go(Routes.setPassword);
      return;
    }

    final hasCompletedOnboarding = await const AuthenticationRepository()
        .hasCompletedProfileOnboarding();
    if (!mounted) return;
    context.go(
      hasCompletedOnboarding ? Routes.main : Routes.profileOnboarding,
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _flyBackground,
    body: SafeArea(
      child: Center(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _offset,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                _BrandMark(),
                SizedBox(height: 16),
                Text(
                  'GoBuddy',
                  style: TextStyle(
                    color: _flyPrimary,
                    fontFamily: 'Georgia',
                    fontSize: 48,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    letterSpacing: -1.2,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Connecting people for meaningful journeys.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _flyTextMuted,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.66,
                    letterSpacing: .3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) => Container(
    width: 64,
    height: 64,
    decoration: BoxDecoration(
      color: _flySurface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Icon(Icons.explore_rounded, color: _flyOnPrimary, size: 34),
  );
}
