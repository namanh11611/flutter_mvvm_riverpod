import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/constants.dart';
import '../../../routing/routes.dart';
import '../../authentication/repository/authentication_repository.dart';
import '../../common/ui/widgets/loading.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Loading(),
      ),
    );
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await ref.read(authenticationRepositoryProvider).isLogin();
    debugPrint('${Constants.tag} [SplashScreen._checkLoginStatus] isLoggedIn = $isLoggedIn');
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    if (isLoggedIn) {
      context.pushReplacement(Routes.main);
    } else {
      context.pushReplacement(Routes.register);
    }
  }
}
