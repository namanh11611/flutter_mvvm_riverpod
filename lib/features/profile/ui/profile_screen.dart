import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../constants/assets.dart';
import '../../../../extensions/build_context_extension.dart';
import '../../../../features/common/ui/widgets/common_dialog.dart';
import '../../../../features/profile/ui/view_models/profile_view_model.dart';
import '../../../../features/profile/ui/widgets/profile_item.dart';
import '../../../../features/profile/ui/widgets/upgrade_premium_button.dart';
import '../../../../routing/routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/global_loading.dart';

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
    final profile = ref.watch(profileViewModelProvider).value?.profile;
    final dangerousColor =
        context.isDarkMode ? AppColors.rambutan80 : AppColors.rambutan100;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 32),
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.blueberry80,
                  backgroundImage: AssetImage(Assets.avatar),
                  foregroundImage: profile?.avatar != null
                      ? NetworkImage(profile?.avatar ?? '')
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                profile?.name ?? 'Henry Nguyen',
                style: AppTheme.titleExtraLarge24,
              ),
            ),
            Center(
              child: Text(
                profile?.email ?? 'namanh11611@gmail.com',
                style: AppTheme.bodyMedium14.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            UpgradePremiumButton(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'general'.tr(),
                style: AppTheme.titleLarge20,
              ),
            ),
            ProfileItem(
              icon: HugeIcons.strokeRoundedUser,
              text: 'account_information'.tr(),
              onTap: () {},
            ),
            ProfileItem(
              icon: HugeIcons.strokeRoundedIdea,
              text: 'appearances'.tr(),
              onTap: () {
                context.push(Routes.appearances);
              },
            ),
            ProfileItem(
              icon: HugeIcons.strokeRoundedCoinsSwap,
              text: 'language'.tr(),
              onTap: () {
                context.push(Routes.languages);
              },
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'preferences'.tr(),
                style: AppTheme.titleLarge20,
              ),
            ),
            ProfileItem(
              icon: HugeIcons.strokeRoundedNews,
              text: 'term_of_service'.tr(),
              onTap: () {},
            ),
            ProfileItem(
              icon: HugeIcons.strokeRoundedShield01,
              text: 'privacy_policy'.tr(),
              onTap: () {},
            ),
            ProfileItem(
              icon: HugeIcons.strokeRoundedUserMultiple,
              text: 'about_us'.tr(),
              onTap: () {},
            ),
            ProfileItem(
              icon: HugeIcons.strokeRoundedStar,
              text: 'rate_us'.tr(),
              onTap: () {},
            ),
            ProfileItem(
              icon: HugeIcons.strokeRoundedSettingError04,
              text: 'report_a_problem'.tr(),
              onTap: () {},
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'dangerous_zone'.tr(),
                style: AppTheme.titleLarge20,
              ),
            ),
            ProfileItem(
              icon: HugeIcons.strokeRoundedLogout01,
              text: 'log_out'.tr(),
              textColor: dangerousColor,
              onTap: () => _signOut(context),
            ),
            ProfileItem(
              icon: HugeIcons.strokeRoundedDelete01,
              text: 'delete_account'.tr(),
              textColor: dangerousColor,
              onTap: () => _deleteAccount(context),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Version $_version',
                style: AppTheme.bodySmall12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _getPackageInfo() {
    PackageInfo.fromPlatform().then((info) {
      setState(() {
        _version = info.version;
      });
    }).catchError((error) {
      debugPrint('Error: $error');
    });
  }

  void _signOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => CommonDialog(
        title: 'log_out_title'.tr(),
        content: 'log_out_message'.tr(),
        primaryButtonLabel: 'log_out'.tr(),
        primaryButtonBackground: AppColors.rambutan100,
        secondaryButtonLabel: 'cancel'.tr(),
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
              context.showErrorSnackBar('unexpected_error_occurred'.tr());
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
        title: 'delete_account_title'.tr(),
        content: 'delete_account_message'.tr(),
        primaryButtonLabel: 'delete_account'.tr(),
        primaryButtonBackground: AppColors.rambutan100,
        secondaryButtonLabel: 'cancel'.tr(),
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
              context.showErrorSnackBar('unexpected_error_occurred'.tr());
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
