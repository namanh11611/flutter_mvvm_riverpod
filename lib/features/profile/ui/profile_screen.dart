import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/constants/constants.dart';
import '/constants/languages.dart';
import '/extensions/build_context_extension.dart';
import '/extensions/profile_extension.dart';
import '/routing/routes.dart';
import '/theme/app_colors.dart';
import '/theme/app_theme.dart';
import '/utils/global_loading.dart';
import '../../../../features/common/ui/widgets/common_dialog.dart';
import '../model/profile.dart';
import 'view_model/profile_view_model.dart';
import 'widgets/avatar.dart';
import 'widgets/premium_info.dart';
import 'widgets/profile_item.dart';
import 'widgets/upgrade_premium_button.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  var _version = '';

  @override
  void initState() {
    super.initState();
    _getPackageInfo();
  }

  @override
  Widget build(BuildContext context) {
    final profile =
        ref.watch(profileViewModelProvider.select((it) => it.value?.profile));
    final dangerousColor =
        context.isDarkMode ? AppColors.rambutan80 : AppColors.rambutan100;
    return Scaffold(
      backgroundColor: context.secondaryBackgroundColor,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.paddingOf(context).top + 48,
          16,
          48,
        ),
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: context.secondaryWidgetColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Transform.translate(
                  offset: Offset(0, -48),
                  child: Column(
                    children: [
                      Avatar(url: profile?.avatar),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          profile?.name ?? Constants.defaultName,
                          style: AppTheme.title24,
                        ),
                      ),
                      Center(
                        child: Text(
                          profile?.email ?? '',
                          style: AppTheme.body14.copyWith(
                            color: context.secondaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, -32),
                  child: profile.isPremium
                      ? PremiumInfo(expiryDate: profile?.expiryDatePremium)
                      : UpgradePremiumButton(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              Languages.general,
              style: AppTheme.title20,
            ),
          ),
          const SizedBox(height: 8),
          ProfileItem(
            icon: HugeIcons.strokeRoundedUser,
            text: Languages.accountInformation,
            isFirst: true,
            onTap: () {
              context.push(
                Routes.accountInformation,
                extra: profile ?? Profile(),
              );
            },
          ),
          ProfileItem(
            icon: HugeIcons.strokeRoundedIdea,
            text: Languages.appearances,
            onTap: () {
              context.push(Routes.appearances);
            },
          ),
          ProfileItem(
            icon: HugeIcons.strokeRoundedCoinsSwap,
            text: Languages.language,
            isLast: true,
            onTap: () {
              context.push(Routes.languages);
            },
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              Languages.preferences,
              style: AppTheme.title20,
            ),
          ),
          const SizedBox(height: 8),
          ProfileItem(
            icon: HugeIcons.strokeRoundedNews,
            text: Languages.termOfService,
            isFirst: true,
            onTap: () => context.tryLaunchUrl(Constants.termOfService),
          ),
          ProfileItem(
            icon: HugeIcons.strokeRoundedShield01,
            text: Languages.privacyPolicy,
            onTap: () => context.tryLaunchUrl(Constants.privacyPolicy),
          ),
          ProfileItem(
            icon: HugeIcons.strokeRoundedUserMultiple,
            text: Languages.aboutUs,
            onTap: () => context.tryLaunchUrl(Constants.aboutUs),
          ),
          ProfileItem(
            icon: HugeIcons.strokeRoundedStar,
            text: Languages.rateUs,
            onTap: () => context.tryLaunchUrl(
                Platform.isIOS ? Constants.appStore : Constants.playStore),
          ),
          ProfileItem(
            icon: HugeIcons.strokeRoundedSettingError04,
            text: Languages.reportAProblem,
            isLast: true,
            onTap: () => context.tryLaunchUrl(Constants.facebookPage),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              Languages.dangerousZone,
              style: AppTheme.title20,
            ),
          ),
          const SizedBox(height: 8),
          ProfileItem(
            icon: HugeIcons.strokeRoundedLogout01,
            text: Languages.logOut,
            textColor: dangerousColor,
            isFirst: true,
            onTap: () => _signOut(context),
          ),
          ProfileItem(
            icon: HugeIcons.strokeRoundedDelete01,
            text: Languages.deleteAccount,
            textColor: dangerousColor,
            isLast: true,
            onTap: () => _deleteAccount(context),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Version $_version',
              style: AppTheme.body12,
            ),
          ),
        ],
      ),
    );
  }

  void _getPackageInfo() {
    PackageInfo.fromPlatform().then((info) {
      setState(() {
        _version = info.version;
      });
    }).catchError((error) {
      debugPrint(
          '${Constants.tag} [_ProfileScreenState._getPackageInfo] Error: $error');
    });
  }

  void _signOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => CommonDialog(
        title: Languages.logOutTitle,
        content: Languages.logOutMessage,
        primaryButtonLabel: Languages.logOut,
        primaryButtonBackground: AppColors.rambutan100,
        secondaryButtonLabel: Languages.cancel,
        primaryButtonAction: () async {
          try {
            Global.showLoading(context);
            await ref.read(profileViewModelProvider.notifier).signOut();
          } on AuthException catch (error) {
            if (context.mounted) {
              context.showErrorSnackBar(error.message);
            }
          } catch (error) {
            if (context.mounted) {
              context.showErrorSnackBar(Languages.unexpectedErrorOccurred);
            }
          } finally {
            if (context.mounted) {
              Global.hideLoading();
              context.pushReplacement(Routes.welcome);
            }
          }
        },
      ),
    );
  }

  void _deleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => CommonDialog(
        title: Languages.deleteAccountTitle,
        content: Languages.deleteAccountMessage,
        primaryButtonLabel: Languages.deleteAccount,
        primaryButtonBackground: AppColors.rambutan100,
        secondaryButtonLabel: Languages.cancel,
        primaryButtonAction: () async {
          try {
            Global.showLoading(context);
            await ref.read(profileViewModelProvider.notifier).signOut();
          } on AuthException catch (error) {
            if (context.mounted) {
              context.showErrorSnackBar(error.message);
            }
          } catch (error) {
            if (context.mounted) {
              context.showErrorSnackBar(Languages.unexpectedErrorOccurred);
            }
          } finally {
            if (context.mounted) {
              Global.hideLoading();
              context.pushReplacement(Routes.welcome);
            }
          }
        },
      ),
    );
  }
}
