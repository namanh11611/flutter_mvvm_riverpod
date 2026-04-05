import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../model/trial.dart';

final List<Trial> _trials = [
  Trial(
    icon: HugeIcons.strokeRoundedLock,
    title: LocaleKeys.trialToday,
    description: LocaleKeys.trialTodayDescription,
  ),
  Trial(
    icon: HugeIcons.strokeRoundedNotification01,
    title: LocaleKeys.trialDay5,
    description: LocaleKeys.trialDay5Description,
  ),
  Trial(
    icon: HugeIcons.strokeRoundedStar,
    title: LocaleKeys.trialDay7,
    description: LocaleKeys.trialDay7Description,
  ),
];

class TrialTimeline extends StatelessWidget {
  const TrialTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _trials
          .mapIndexed((index, trial) => TrialItem(
        trial: trial,
        isLast: index == _trials.length - 1,
      ))
          .toList(),
    );
  }
}

class TrialItem extends StatelessWidget {
  final Trial trial;
  final bool isLast;

  const TrialItem({
    super.key,
    required this.trial,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.mono100.withAlpha(220),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                trial.icon,
                color: AppColors.mono0,
                size: 24,
              ),
            ),
            if (!isLast)
              Container(
                width: 16,
                height: 56,
                padding: EdgeInsets.all(12),
                color: AppColors.mono100.withAlpha(220),
              ),
          ],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.mono100.withAlpha(220),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(trial.title),
                  style: AppTheme.title16.copyWith(color: AppColors.mono0),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr(trial.description),
                  style: AppTheme.body14.copyWith(color: AppColors.mono0),
                  softWrap: true,
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
