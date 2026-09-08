import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mvvm_riverpod/core/extensions/build_context_extension.dart';
import 'package:flutter_mvvm_riverpod/core/theme/app_colors.dart';
import 'package:flutter_mvvm_riverpod/core/theme/app_theme.dart';
import 'package:flutter_mvvm_riverpod/features/safety/ui/view_model/blocked_users_view_model.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedUsers = ref.watch(blockedUsersViewModelProvider);
    return Scaffold(
      backgroundColor: context.secondaryBackgroundColor,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('Blocked Users', style: AppTheme.title20),
        backgroundColor: context.secondaryBackgroundColor,
        foregroundColor: context.primaryTextColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: blockedUsers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('$error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => ref.invalidate(blockedUsersViewModelProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ]),
          ),
        ),
        data: (users) => users.isEmpty
            ? Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person_off_outlined,
                size: 56,
                color: AppColors.brandSurface,
              ),
              const SizedBox(height: 16),
              Text('No blocked users', style: AppTheme.title20),
              const SizedBox(height: 8),
              Text(
                'People you block will appear here.',
                textAlign: TextAlign.center,
                style: AppTheme.body16.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
            ],
          ),
        ))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user.avatarUrl == null
                          ? null
                          : NetworkImage(user.avatarUrl!),
                      child: user.avatarUrl == null
                          ? Text(user.displayName.substring(0, 1).toUpperCase())
                          : null,
                    ),
                    title: Text(user.displayName),
                    subtitle: Text('Blocked ${_date(user.blockedAt)}'),
                    trailing: TextButton(
                      onPressed: () => ref
                          .read(blockedUsersViewModelProvider.notifier)
                          .unblock(user.userId),
                      child: const Text('Unblock'),
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _date(DateTime value) =>
      '${value.day}/${value.month}/${value.year}';
}
