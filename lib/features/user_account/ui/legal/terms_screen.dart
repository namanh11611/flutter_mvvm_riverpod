import 'package:flutter/material.dart';

import 'legal_document_screen.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      title: 'Terms of Service',
      assetPath: 'assets/legal/terms_of_service.md',
    );
  }
}
