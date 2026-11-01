import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/assets.dart';
import '../../../constants/constants.dart';
import '../../../extensions/build_context_extension.dart';
import '../../../generated/locale_keys.g.dart';
import '../../../routing/routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/global_loading.dart';
import '../../../utils/utils.dart';
import '../../common/ui/widgets/common_close_button.dart';
import '../../common/ui/widgets/primary_button.dart';
import '../../profile/ui/view_model/profile_view_model.dart';
import 'view_model/short_period_view_model.dart';
import 'widgets/premium_footer.dart';

class ShortPeriodScreen extends ConsumerStatefulWidget {
  final bool? isGoToMain;

  const ShortPeriodScreen({
    super.key,
    this.isGoToMain,
  });

  @override
  ConsumerState createState() => _ShortPeriodScreenState();
}

class _ShortPeriodScreenState extends ConsumerState<ShortPeriodScreen> {
  late Timer _countdownTimer;
  int _remainingSeconds = Constants.countdownDefaultSecond;

  @override
  void initState() {
    super.initState();
    ref.read(profileViewModelProvider.notifier).setShouldShowPremium();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _countdownTimer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(shortPeriodViewModelProvider, (previous, next) {
      if (previous != next) {
        if (next.isLoading) {
          Global.showLoading(context);
        } else {
          Global.hideLoading();
        }
      }

      if (next is AsyncError) {
        context.showErrorSnackBar(next.error.toString());
      }

      if (next is AsyncData) {
        if (next.value?.isPurchaseSuccessfully == true) {
          context.showSuccessSnackBar(LocaleKeys.purchaseSuccess.tr());
          context.go(Routes.splash);
        }
        if (next.value?.isRestoreSuccessfully == true) {
          context.showSuccessSnackBar(LocaleKeys.restorePurchasesSuccess.tr());
          context.go(Routes.splash);
        } else if (next.value?.isRestoreSuccessfully == false) {
          context.showWarningSnackBar(LocaleKeys.noActivePurchases.tr());
        }
      }
    });

    final shortPeriodState = ref.watch(shortPeriodViewModelProvider);
    final product = shortPeriodState.value?.product;

    return Scaffold(
      backgroundColor: AppColors.premiumBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(Assets.premiumBackground, fit: BoxFit.cover),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.gradient40,
                  AppColors.gradient60,
                  AppColors.gradient100,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(width: 36),
                      Text(
                        LocaleKeys.offerTitle.tr(),
                        style: AppTheme.title32.copyWith(
                          color: AppColors.mono0,
                        ),
                      ),
                      CommonCloseButton(
                        onClose: _dismiss,
                        color: AppColors.mono0,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 128),
                    children: [
                      Text(
                        LocaleKeys.shortPeriodSubtitle.tr(),
                        style: AppTheme.title18.copyWith(
                          color: AppColors.mono0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Image.asset(Assets.specialOffer, width: 666, height: 200),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                MediaQuery.paddingOf(context).bottom,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.gradient0,
                    AppColors.gradient100,
                    AppColors.gradient100,
                    AppColors.gradient100,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (product != null) _buildWeeklyCard(product.currentPrice),
                  const SizedBox(height: 64),
                  Text(
                    LocaleKeys.hurryUp.tr(args: [Utils.formatTime(_remainingSeconds)]),
                    style: AppTheme.title18.copyWith(color: AppColors.mono0),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: context.tr(LocaleKeys.getOfferNow),
                    onPressed: () => ref
                        .read(shortPeriodViewModelProvider.notifier)
                        .purchase(),
                  ),
                  const SizedBox(height: 2),
                  PremiumFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCard(String price) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.blueberry100.withAlpha(180),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blueberry100, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.weekly.tr(),
                  style: AppTheme.title20.copyWith(
                    color: AppColors.mono0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  LocaleKeys.weeklyDescription.tr(),
                  style: AppTheme.body12.copyWith(
                    color: AppColors.mono20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              Text(
                price,
                style: AppTheme.title24.copyWith(
                  color: AppColors.mono0,
                ),
              ),
              Text(
                LocaleKeys.perWeek.tr(),
                style: AppTheme.body14.copyWith(
                  color: AppColors.mono20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _dismiss() {
    if (widget.isGoToMain == true) {
      context.pushReplacement(Routes.main);
    } else {
      context.pop();
    }
  }
}
