import 'package:flutter/material.dart';

import '/theme/app_colors.dart';
import '/theme/app_theme.dart';

class CustomSnackBar extends SnackBar {
  CustomSnackBar.success({
    super.key,
    required String text,
    super.action,
  }) : super(
          content: Row(
            children: [
              const Icon(
                Icons.check,
                size: 24,
                color: AppColors.mono0,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: AppTheme.body14.copyWith(color: AppColors.mono0),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.watermelon100,
          margin: const EdgeInsets.only(left: 20, right: 20, bottom: 32),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          behavior: SnackBarBehavior.floating,
        );

  CustomSnackBar.info({
    super.key,
    required String text,
    super.action,
  }) : super(
          content: Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 24,
                color: AppColors.mono0,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: AppTheme.body14.copyWith(color: AppColors.mono0),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.blueberry100,
          margin: const EdgeInsets.only(left: 20, right: 20, bottom: 32),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          behavior: SnackBarBehavior.floating,
        );

  CustomSnackBar.warning({
    super.key,
    required String text,
    super.action,
  }) : super(
          content: Row(
            children: [
              const Icon(
                Icons.warning_amber,
                size: 24,
                color: AppColors.mono100,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: AppTheme.body14.copyWith(color: AppColors.mono100),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.cempedak100,
          margin: const EdgeInsets.only(left: 20, right: 20, bottom: 32),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          behavior: SnackBarBehavior.floating,
        );

  CustomSnackBar.error({
    super.key,
    required String text,
    super.action,
  }) : super(
          content: Row(
            children: [
              const Icon(
                Icons.close,
                size: 24,
                color: AppColors.mono0,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: AppTheme.body14.copyWith(color: AppColors.mono0),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.rambutan100,
          margin: const EdgeInsets.only(left: 20, right: 20, bottom: 32),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          behavior: SnackBarBehavior.floating,
        );
}
