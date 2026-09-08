import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../common/ui/widgets/common_header.dart';
import 'view_model/emergency_contacts_view_model.dart';

class EmergencyContactsScreen extends ConsumerWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(emergencyContactsViewModelProvider);

    ref.listen(
        emergencyContactsViewModelProvider.select((value) => value.error),
        (previous, next) {
      if (next == null || next == previous) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next)));
      ref.read(emergencyContactsViewModelProvider.notifier).clearError();
    });

    return Scaffold(
      body: Column(
        children: [
          const CommonHeader(header: 'Emergency contacts'),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.contacts.isEmpty
                    ? const _EmptyContacts()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
                        itemCount: state.contacts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final contact = state.contacts[index];
                          return Card(
                            elevation: 0,
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.fromLTRB(16, 8, 8, 8),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.rambutan10,
                                child: Text(
                                  contact.name.substring(0, 1).toUpperCase(),
                                  style: AppTheme.title16.copyWith(
                                    color: AppColors.rambutan100,
                                  ),
                                ),
                              ),
                              title:
                                  Text(contact.name, style: AppTheme.title16),
                              subtitle: Text(
                                '${contact.phoneNumber}\n${contact.email}',
                                style: AppTheme.body14,
                              ),
                              isThreeLine: true,
                              trailing: IconButton(
                                tooltip: 'Remove contact',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _confirmDelete(
                                  context,
                                  ref,
                                  contact.id,
                                  contact.name,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'live-location',
            onPressed: () => context.push(Routes.liveLocation),
            icon: const Icon(Icons.location_on_outlined),
            label: const Text('Share live location'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add-contact',
            onPressed: () => context.push(Routes.addEmergencyContact),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Add contact'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String contactId,
    String contactName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove emergency contact?'),
        content: Text('$contactName will no longer receive safety alerts.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(emergencyContactsViewModelProvider.notifier)
          .deleteContact(contactId);
    }
  }
}

class _EmptyContacts extends StatelessWidget {
  const _EmptyContacts();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.health_and_safety_outlined, size: 64),
            const SizedBox(height: 16),
            Text('No emergency contacts yet', style: AppTheme.title20),
            const SizedBox(height: 8),
            Text(
              'Add someone you trust so they can receive future trip and safety alerts.',
              textAlign: TextAlign.center,
              style: AppTheme.body14,
            ),
          ],
        ),
      ),
    );
  }
}
