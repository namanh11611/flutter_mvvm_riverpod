import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/constants.dart';
import '../../../features/authentication/repository/authentication_repository.dart';
import '../../../features/common/ui/widgets/loading.dart';
import '../../../routing/routes.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _checkLoginStatus(ref, context);
    return Scaffold(
      body: Center(
        child: Loading(),
      ),
    );
  }

  Future<void> _checkLoginStatus(WidgetRef ref, BuildContext context) async {
    final isLoggedIn = await ref.read(authenticationRepositoryProvider).isLogin();
    debugPrint('${Constants.tag} [SplashScreen._checkLoginStatus] isLoggedIn = $isLoggedIn');
    await Future.delayed(const Duration(seconds: 1));
    if (!context.mounted) return;
    if (isLoggedIn) {
      context.pushReplacement(Routes.main);
    } else {
      context.pushReplacement(Routes.welcome);
    }
  }
}
