import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/routing/routes.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: const Text('Go to Splash'),
          onPressed: () {
            context.pushReplacement(Routes.splash);
          },
        ),
      ),
    );
  }
}
