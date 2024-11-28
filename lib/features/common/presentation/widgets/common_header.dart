import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/features/common/presentation/widgets/common_back_button.dart';
import 'package:flutter_mvvm_riverpod/theme/app_colors.dart';
import 'package:flutter_mvvm_riverpod/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommonHeader extends ConsumerWidget {
  final String header;
  final bool isShowBack;

  const CommonHeader({
    super.key,
    required this.header,
    this.isShowBack = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 16,
        left: 6,
        right: 6,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.blueberry100,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (isShowBack) const CommonBackButton(color: AppColors.mono0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              header,
              style: AppTheme.titleExtraLarge24.copyWith(
                color: AppColors.mono0,
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}
