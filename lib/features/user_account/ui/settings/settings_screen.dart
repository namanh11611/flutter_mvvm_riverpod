import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mvvm_riverpod/core/extensions/build_context_extension.dart';
import 'package:flutter_mvvm_riverpod/core/routing/routes.dart';
import 'package:flutter_mvvm_riverpod/core/theme/app_colors.dart';
import 'package:flutter_mvvm_riverpod/core/theme/app_theme.dart';
import 'package:flutter_mvvm_riverpod/features/common/ui/providers/app_theme_mode_provider.dart';
import 'package:flutter_mvvm_riverpod/features/common/ui/widgets/common_dialog.dart';
import 'package:flutter_mvvm_riverpod/features/admin/repository/identity_review_repository.dart';
import '../view_model/settings_view_model.dart';

final _adminAccessProvider = FutureProvider.autoDispose<bool>(
  (ref) => const AdminIdentityReviewRepository().isAdmin(),
);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsViewModelProvider);
    final value = settings.value;
    final themeMode = ref.watch(appThemeModeProvider).value ?? ThemeMode.system;
    final isAdmin = ref.watch(_adminAccessProvider).value ?? false;

    return Scaffold(
      backgroundColor: context.secondaryBackgroundColor,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('Settings', style: AppTheme.title20),
        backgroundColor: context.secondaryBackgroundColor,
        foregroundColor: context.primaryTextColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: settings.isLoading && value == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                const _SectionHeader(title: 'Account'),
                const SizedBox(height: 8),
                _SettingsCard(
                  child: _SettingsTile(
                    icon: Icons.logout_rounded,
                    title: 'Sign Out',
                    trailing: value?.isSigningOut == true
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: value?.isSigningOut == true
                        ? null
                        : () => _signOut(context, ref),
                  ),
                ),
                const SizedBox(height: 28),
                const _SectionHeader(
                  title: 'Appearance',
                  description: 'Choose how GoBuddy looks on your device',
                ),
                const SizedBox(height: 12),
                _SettingsCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode_outlined),
                            label: Text('Light'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode_outlined),
                            label: Text('Dark'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.settings_suggest_outlined),
                            label: Text('System'),
                          ),
                        ],
                        selected: {themeMode},
                        showSelectedIcon: false,
                        onSelectionChanged: (selection) {
                          ref
                              .read(appThemeModeProvider.notifier)
                              .updateMode(selection.single);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const _SectionHeader(
                  title: 'Notification Settings',
                  description:
                      'Control how you receive notifications from GoBuddy',
                ),
                const SizedBox(height: 12),
                _SettingsCard(
                  child: _SettingsTile(
                    icon: Icons.travel_explore_rounded,
                    title: 'Trip Matches',
                    subtitle: 'Get notified when someone has a similar trip',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          value?.tripMatchNotificationsEnabled == true
                              ? 'Yes'
                              : 'No',
                          style: AppTheme.title12.copyWith(
                            color: context.secondaryTextColor,
                          ),
                        ),
                        Switch(
                          value: value?.tripMatchNotificationsEnabled ?? true,
                          activeThumbColor: AppColors.brandBackground,
                          activeTrackColor: AppColors.brandSurface,
                          inactiveThumbColor: AppColors.brandTextMuted,
                          inactiveTrackColor: AppColors.brandBorder,
                          onChanged: (enabled) => ref
                              .read(settingsViewModelProvider.notifier)
                              .setTripMatchNotificationsEnabled(enabled),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const _SectionHeader(
                  title: 'Safety',
                  description: 'Manage your personal safety preferences',
                ),
                const SizedBox(height: 12),
                _SettingsCard(
                  child: _SettingsTile(
                    icon: Icons.health_and_safety_outlined,
                    title: 'Safety Check-In',
                    subtitle: 'Configure automatic safety check-in reminders',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.safetyCheckInSettings),
                  ),
                ),
                const SizedBox(height: 28),
                const _SectionHeader(title: 'Privacy'),
                const SizedBox(height: 8),
                _SettingsCard(
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.lock_reset_rounded,
                        title: 'Change Password',
                        subtitle: 'Update your account password',
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push(Routes.changePassword),
                      ),
                      const Divider(height: 1, indent: 56),
                      _SettingsTile(
                        icon: Icons.block_rounded,
                        title: 'Blocked Users',
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push(Routes.blockedUsers),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                if (isAdmin) ...[
                  const _SectionHeader(
                    title: 'Administration',
                    description: 'Review cases that require a manual decision',
                  ),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    child: _SettingsTile(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Identity reviews',
                      subtitle: 'Approve or reject Didit cases in review',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(Routes.identityReviews),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
                _SectionHeader(
                  title: 'Delete Account',
                  color: AppColors.rambutan100,
                ),
                const SizedBox(height: 8),
                _SettingsCard(
                  child: _SettingsTile(
                    icon: Icons.delete_forever_outlined,
                    iconColor: AppColors.rambutan100,
                    title: 'Delete Account',
                    subtitle: 'Permanently remove your account and data',
                    trailing: value?.isDeletingAccount == true
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.rambutan100,
                          ),
                    onTap: value?.isDeletingAccount == true
                        ? null
                        : () => _showDeleteConfirmation(context, ref),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final success = await ref
        .read(settingsViewModelProvider.notifier)
        .signOut();
    if (!context.mounted) return;
    if (success) {
      context.go(Routes.login);
    } else {
      final error = ref.read(settingsViewModelProvider).value?.error;
      context.showErrorSnackBar(error ?? 'Unable to sign out.');
    }
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => CommonDialog(
        title: 'Delete Account?',
        content:
            'Are you sure you want to permanently delete your account? '
            'This action cannot be undone.',
        primaryButtonLabel: 'Delete Account',
        primaryButtonBackground: AppColors.rambutan100,
        secondaryButtonLabel: 'Cancel',
        primaryButtonAction: () => _confirmDeletion(context, ref),
      ),
    );
  }

  Future<void> _confirmDeletion(BuildContext context, WidgetRef ref) async {
    final deleted = await ref
        .read(settingsViewModelProvider.notifier)
        .deleteAccount();
    if (!context.mounted) return;
    if (deleted) {
      context.go(Routes.login);
      return;
    }
    final error = ref.read(settingsViewModelProvider).value?.error;
    context.showErrorSnackBar(error ?? 'Unable to delete your account.');
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.description, this.color});

  final String title;
  final String? description;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.title18.copyWith(
            color: color ?? context.primaryTextColor,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: AppTheme.body14.copyWith(color: context.secondaryTextColor),
          ),
        ],
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.secondaryWidgetColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerColor),
      ),
      child: child,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing,
    this.subtitle,
    this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 64,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: iconColor ?? AppColors.brandSurface),
      title: Text(title, style: AppTheme.title16),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: AppTheme.body14.copyWith(
                color: context.secondaryTextColor,
              ),
            ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
