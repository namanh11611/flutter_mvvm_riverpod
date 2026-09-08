import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/routes.dart';
import 'admin_screen.dart' show AdminReportRows;
import 'view_model/admin_view_model.dart';
import 'widgets/admin_widgets.dart';

class AdminReportScreen extends ConsumerWidget {
  const AdminReportScreen({super.key, required this.reportId});
  final String reportId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AdminScaffold(
    section: 1,
    title: 'Report Details',
    backPath: '${Routes.admin}/reports',
    onRefresh: () => ref.invalidate(adminReportProvider(reportId)),
    child: AdminLoad(
      value: ref.watch(adminReportProvider(reportId)),
      retry: () => ref.invalidate(adminReportProvider(reportId)),
      builder: (data) {
        final report = Map<String, dynamic>.from(data['report'] as Map);
        final status = '${report['status']}';
        final accountStatus = '${report['account_status'] ?? 'active'}';
        final history = (data['history'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        final actions = status == 'pending'
            ? ['start_review']
            : status == 'reviewing'
            ? [
                'dismiss',
                'no_action',
                ...accountDecisions(
                  accountStatus,
                  isAdmin: report['target_is_admin'] == true,
                ).where((a) => a != 'reactivate'),
              ]
            : <String>[];
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 24,
              runSpacing: 8,
              children: [
                SelectableText(
                  'Report ID: $reportId\nSubmitted: ${adminDate(report['created_at'])}',
                ),
                AdminStatus(status),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth >= 700
                    ? (constraints.maxWidth - 24) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 24,
                  children: [
                    SizedBox(
                      width: width,
                      child: AdminPanel(
                        title: 'Reporter',
                        child: _Identity(
                          name: '${report['reporter_name'] ?? 'Unknown user'}',
                          id: '${report['reporter_id']}',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: AdminPanel(
                        title: 'Reported User',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Identity(
                              name:
                                  '${report['reported_user_name'] ?? 'Unknown user'}',
                              id: '${report['reported_user_id']}',
                            ),
                            AdminStatus(accountStatus),
                            Text(
                              'Previous reports: ${report['previous_reports'] ?? 'Not available'}',
                            ),
                            Text(
                              'Warnings: ${report['warning_count'] ?? 'Not available'}',
                            ),
                            if (report['suspended_until'] != null)
                              Text(
                                'Suspended until: ${adminDate(report['suspended_until'])}',
                              ),
                            TextButton(
                              onPressed: () => context.push(
                                '${Routes.admin}/users/${report['reported_user_id']}',
                              ),
                              child: const Text(
                                'View user and moderation history',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            AdminPanel(
              title: 'Report Information',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reason',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  AdminReportReason(report['reason']),
                  const SizedBox(height: 24),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SelectableText(
                    '${report['description'] ?? 'No description provided.'}',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Evidence',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Text('No attachments were submitted with this report.'),
                ],
              ),
            ),
            AdminPanel(
              title: 'Admin Review',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (report['reviewed_by'] != null)
                    SelectableText(
                      'Handling admin: ${report['reviewed_by']}\nLast reviewed: ${adminDate(report['reviewed_at'])}',
                    ),
                  if (actions.isNotEmpty) ...[
                    const Text(
                      'Review the report and relevant history before recording a decision. A report alone does not establish a violation.',
                    ),
                    const SizedBox(height: 24),
                    AdminDecisionForm(
                      key: ValueKey('$reportId:$status:$accountStatus'),
                      targetId: '${report['reported_user_id']}',
                      reportId: reportId,
                      actions: actions,
                    ),
                  ] else ...[
                    Text('This case is ${adminLabel(status).toLowerCase()}.'),
                    Text('Completed: ${adminDate(report['reviewed_at'])}'),
                    if (history.isNotEmpty) ...[
                      Text(
                        'Final decision: ${adminLabel(history.last['action'])}',
                      ),
                      SelectableText(
                        '${auditNote(history.last)['reason'] ?? ''}',
                      ),
                    ],
                  ],
                ],
              ),
            ),
            AdminPanel(
              title: 'Case history',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.flag_outlined),
                    title: const Text('Report submitted'),
                    subtitle: Text(adminDate(report['created_at'])),
                  ),
                  AdminHistory(history),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _Identity extends StatelessWidget {
  const _Identity({required this.name, required this.id});
  final String name, id;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(name, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      SelectableText('User ID: $id'),
    ],
  );
}

class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key, required this.userId});
  final String userId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AdminScaffold(
    section: 2,
    title: 'User Details',
    backPath: '${Routes.admin}/users',
    onRefresh: () => ref.invalidate(adminProfileProvider(userId)),
    child: AdminLoad(
      value: ref.watch(adminProfileProvider(userId)),
      retry: () => ref.invalidate(adminProfileProvider(userId)),
      builder: (user) {
        final status =
            user.fields['account_status'] ??
            (user.banned ? 'banned' : 'active');
        final actions = accountDecisions(
          status,
          isAdmin: user.fields['is_admin'] == 'true',
        );
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            AdminPanel(
              title: 'Account Information',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Identity(
                    name: user.fields['display_name'] ?? 'Unnamed user',
                    id: userId,
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    'Email: ${user.fields['email'] ?? 'Not available'}',
                  ),
                  AdminStatus(status),
                  if (user.fields['is_admin'] == 'true')
                    const Text(
                      'Administrator account · moderation actions unavailable',
                    ),
                  if (status == 'suspended')
                    Text(
                      'Suspended until: ${adminDate(user.fields['suspended_until'])}',
                    ),
                  if (status != 'active')
                    SelectableText(
                      'Restriction reason: ${user.fields['restriction_reason'] ?? 'Not available'}',
                    ),
                ],
              ),
            ),
            AdminPanel(
              title: 'Moderation Summary',
              child: Wrap(
                spacing: 32,
                runSpacing: 16,
                children: [
                  Text(
                    'Reports received: ${user.fields['report_count'] ?? 'Not available'}',
                  ),
                  Text(
                    'Warnings: ${user.fields['warning_count'] ?? 'Not available'}',
                  ),
                  Text(
                    'Previous suspensions: ${user.fields['suspension_count'] ?? 'Not available'}',
                  ),
                ],
              ),
            ),
            AdminPanel(
              title: 'Moderation History',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Most recent 50 activities'),
                  const SizedBox(height: 16),
                  AdminHistory(user.history),
                ],
              ),
            ),
            AdminPanel(
              title: 'Reports Received',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Most recent 50 reports'),
                  const SizedBox(height: 16),
                  AdminReportRows(rows: user.reports),
                ],
              ),
            ),
            if (actions.isNotEmpty)
              AdminPanel(
                title: 'Account Actions',
                child: AdminDecisionForm(
                  key: ValueKey('$userId:$status'),
                  targetId: userId,
                  actions: actions,
                ),
              ),
          ],
        );
      },
    ),
  );
}
