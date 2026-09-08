import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_mvvm_riverpod/core/extensions/build_context_extension.dart';
import 'package:flutter_mvvm_riverpod/core/theme/app_colors.dart';
import 'package:flutter_mvvm_riverpod/core/theme/app_theme.dart';

class LegalDocumentScreen extends StatefulWidget {
  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.assetPath,
  });

  final String title;
  final String assetPath;

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  late final Future<String> _document;

  @override
  void initState() {
    super.initState();
    _document = rootBundle.loadString(widget.assetPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.secondaryBackgroundColor,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(widget.title, style: AppTheme.title20),
        backgroundColor: context.secondaryBackgroundColor,
        foregroundColor: context.primaryTextColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: FutureBuilder<String>(
        future: _document,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load ${widget.title}.',
                  style: AppTheme.body16,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Markdown(
            data: data,
            selectable: true,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            styleSheet:
                MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              h1: AppTheme.title24.copyWith(color: context.primaryTextColor),
              h2: AppTheme.title20.copyWith(color: context.primaryTextColor),
              p: AppTheme.body16.copyWith(color: context.primaryTextColor),
              listBullet:
                  AppTheme.body16.copyWith(color: context.primaryTextColor),
              a: AppTheme.body16.copyWith(
                color: AppColors.blueberry100,
                decoration: TextDecoration.underline,
              ),
            ),
            onTapLink: (linkText, href, title) async {
              if (href == null) return;
              final uri = Uri.tryParse(href);
              if (uri == null || !await launchUrl(uri)) {
                if (context.mounted) {
                  context.showErrorSnackBar('Unable to open this link.');
                }
              }
            },
          );
        },
      ),
    );
  }
}
