import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../../user_account/ui/view_model/user_account_view_model.dart';

/// Prevents unverified accounts from opening member-only modules, including
/// when the screen is reached from a notification or deep link.
class VerifiedAccessGate extends ConsumerWidget {
  const VerifiedAccessGate({
    super.key,
    required this.featureName,
    required this.child,
  });

  final String featureName;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(userAccountViewModelProvider);
    if (account.user?.isVerified == true) return child;
    if (account.isLoading && account.user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(featureName)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 64,
                  color: Color(0xFF7C3AED),
                ),
                const SizedBox(height: 20),
                Text(
                  'Verify your identity to unlock $featureName',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Only verified users can use this feature. Complete identity verification to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF686082), height: 1.45),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.push(Routes.identityVerification),
                    icon: const Icon(Icons.verified_user_outlined),
                    label: const Text('Verify my account now'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go(Routes.main),
                  child: const Text('Back to matchmaking'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
