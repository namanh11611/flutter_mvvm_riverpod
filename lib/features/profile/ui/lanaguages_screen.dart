import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../extensions/build_context_extension.dart';
import '../../../../features/common/ui/widgets/common_header.dart';
import '../../../../features/profile/model/language.dart';
import '../../../../features/profile/ui/widgets/language_item.dart';

final languages = [
  const Language(id: '0', name: 'English', code: 'en', flag: ''),
  const Language(id: '1', name: 'Tiếng Việt', code: 'vi', flag: ''),
];

class LanguagesScreen extends ConsumerWidget {
  const LanguagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.secondaryBackgroundColor,
      body: Column(
        children: [
          CommonHeader(header: 'language'.tr()),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) => LanguageItem(
                language: languages[index],
                isFirst: index == 0,
                isLast: index == languages.length - 1,
              ),
              itemCount: languages.length,
            ),
          ),
        ],
      ),
    );
  }
}
