import 'package:flutter/material.dart';

import 'sign_in_with_google.dart';

class SocialSignIn extends StatelessWidget {
  const SocialSignIn({super.key});

  @override
  Widget build(BuildContext context) => const Row(
    children: [Expanded(child: SignInWithGoogle())],
  );
}
