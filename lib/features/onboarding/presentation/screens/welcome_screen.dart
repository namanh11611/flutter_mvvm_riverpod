import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/routing/routes.dart';
import 'package:flutter_mvvm_riverpod/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'welcome'.tr(),
              style: AppTheme.headLineLarge32,
              textAlign: TextAlign.center,
            ),
            ElevatedButton(
              child: const Text('Go to Home'),
              onPressed: () {
                context.pushReplacement(Routes.home);
              },
            ),
          ],
        ),
      ),
    );
  }
}
