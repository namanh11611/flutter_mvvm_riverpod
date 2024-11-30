import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/routing/routes.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: const Text('Go to Welcome'),
          onPressed: () {
            context.pushReplacement(Routes.welcome);
          },
        ),
      ),
    );
  }
}
