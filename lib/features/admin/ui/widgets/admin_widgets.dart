import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/routing/routes.dart';
import '../view_model/admin_view_model.dart';
import 'admin_theme.dart';
import '../../../safety/model/user_safety.dart';

const adminLabels = {
  'all': 'All',
  'pending': 'Pending',
  'reviewing': 'Under Review',
  'resolved': 'Resolved',
  'dismissed': 'Dismissed',
  'active': 'Active',
  'suspended': 'Suspended',
  'banned': 'Banned',
  'start_review': 'Review started',
  'dismiss': 'Dismiss / No violation',
  'no_action': 'Resolve without account action',
  'warning': 'Issue warning',
  'suspend': 'Suspend user',
  'ban': 'Ban user',
  'reactivate': 'Reactivate user',
  'review': 'Report reviewed',
  'unban': 'User reactivated',
  'removeImage': 'Image removed',
};
String adminLabel(Object? value) =>
    UserReportReason.fromValue(value?.toString())?.label ??
    adminLabels[value] ??
    value?.toString() ??
    'Not available';
String adminDate(Object? value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  return date == null
      ? 'Not available'
      : DateFormat('dd MMM yyyy, HH:mm').format(date.toLocal());
}

String shortId(Object? value) {
  final text = value?.toString() ?? '';
  return text.length > 8 ? text.substring(0, 8) : text;
}

Map<String, dynamic> auditNote(Map<String, dynamic> event) {
  try {
    final data = jsonDecode(event['reason']?.toString() ?? '');
    if (data is Map) return Map<String, dynamic>.from(data);
  } catch (_) {
    /* Older audit records may contain plain text. */
  }
  return {'reason': event['reason']};
}

class AdminScaffold extends ConsumerWidget {
  const AdminScaffold({
    super.key,
    required this.section,
    required this.title,
    required this.child,
    required this.onRefresh,
    this.backPath,
  });
  final int section;
  final String title;
  final Widget child;
  final VoidCallback onRefresh;
  final String? backPath;
  static const labels = [
    'Dashboard',
    'Reports',
    'Users',
    'Activity Logs',
    'Review Verification',
  ];
  static const icons = [
    Icons.dashboard_outlined,
    Icons.flag_outlined,
    Icons.people_outline,
    Icons.history,
    Icons.verified_user_outlined,
  ];
  static const paths = [
    Routes.admin,
    '${Routes.admin}/reports',
    '${Routes.admin}/users',
    '${Routes.admin}/activity',
    Routes.identityReviews,
  ];
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    void navigate(int index) => context.go(paths[index]);
    return Theme(
      data: AdminTheme.from(Theme.of(context)),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(title),
            automaticallyImplyLeading: !wide,
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: 'Sign out',
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  try {
                    await ref.read(adminViewModelProvider.notifier).signOut();
                    if (context.mounted) context.go(Routes.login);
                  } catch (_) {
                    if (context.mounted) {
                      adminMessage(
                        context,
                        'Unable to sign out. Please try again.',
                      );
                    }
                  }
                },
              ),
            ],
          ),
          drawer: wide
              ? null
              : NavigationDrawer(
                  selectedIndex: section,
                  onDestinationSelected: navigate,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('GoBuddy Admin'),
                    ),
                    for (var i = 0; i < labels.length; i++)
                      NavigationDrawerDestination(
                        icon: Icon(icons[i]),
                        label: SizedBox(
                          width: 140,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(labels[i]),
                          ),
                        ),
                      ),
                  ],
                ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide)
                NavigationRail(
                  extended: true,
                  selectedIndex: section,
                  onDestinationSelected: navigate,
                  leading: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('GoBuddy Admin'),
                  ),
                  destinations: [
                    for (var i = 0; i < labels.length; i++)
                      NavigationRailDestination(
                        icon: Icon(icons[i]),
                        label: Text(labels[i]),
                      ),
                  ],
                ),
              if (wide) const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (backPath != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => context.go(backPath!),
                          icon: const Icon(Icons.arrow_back),
                          label: Text(
                            section == 1 ? 'Back to reports' : 'Back to users',
                          ),
                        ),
                      ),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminLoad<T> extends StatelessWidget {
  const AdminLoad({
    super.key,
    required this.value,
    required this.builder,
    required this.retry,
  });
  final AsyncValue<T> value;
  final Widget Function(T) builder;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => value.when(
    skipLoadingOnRefresh: false,
    loading: () => const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
    ),
    error: (_, stack) => Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Unable to load data. Please try again.'),
            TextButton(onPressed: retry, child: const Text('Retry')),
          ],
        ),
      ),
    ),
    data: builder,
  );
}

class AdminPanel extends StatelessWidget {
  const AdminPanel({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.compact = false,
  });
  final bool compact;
  final String title;
  final Widget child;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.only(bottom: compact ? 16 : 24),
    child: Padding(
      padding: EdgeInsets.all(compact ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              ?trailing,
            ],
          ),
          SizedBox(height: compact ? 4 : 16),
          child,
        ],
      ),
    ),
  );
}

class AdminStatus extends StatelessWidget {
  const AdminStatus(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final (color, icon) = switch (status) {
      'pending' => (
        dark ? const Color(0xFFFFD18B) : const Color(0xFF805000),
        Icons.schedule,
      ),
      'reviewing' => (
        dark ? const Color(0xFFCDB5FF) : AdminTheme.violet,
        Icons.manage_search,
      ),
      'suspended' => (
        dark ? const Color(0xFFFFD18B) : const Color(0xFF805000),
        Icons.pause_circle_outline,
      ),
      'banned' => (
        dark ? const Color(0xFFFFB4D3) : const Color(0xFF96345C),
        Icons.block,
      ),
      'active' || 'resolved' => (
        dark ? const Color(0xFF8EDBC9) : const Color(0xFF226858),
        Icons.check_circle_outline,
      ),
      _ => (scheme.onSurfaceVariant, Icons.remove_circle_outline),
    };
    return Chip(
      label: Text(adminLabel(status), style: TextStyle(color: color)),
      side: BorderSide.none,
      backgroundColor: Color.alphaBlend(
        color.withValues(alpha: dark ? 0.18 : 0.10),
        scheme.surface,
      ),
      avatar: Icon(icon, size: 16, color: color),
    );
  }
}

class AdminFilter extends StatelessWidget {
  const AdminFilter({
    super.key,
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });
  final String label, value;
  final Map<String, String> values;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 200,
    child: DropdownButtonFormField<String>(
      key: ValueKey('$label:$value'),
      initialValue: values.containsKey(value) ? value : values.keys.first,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final e in values.entries)
          DropdownMenuItem(
            value: e.key,
            child: Text(e.value, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    ),
  );
}

class AdminHistory extends StatelessWidget {
  const AdminHistory(this.events, {super.key, this.showTarget = false});
  final bool showTarget;
  final List<Map<String, dynamic>> events;
  @override
  Widget build(BuildContext context) => events.isEmpty
      ? const Text('No moderation activity yet.')
      : Column(
          children: [
            for (final event in events)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history),
                title: Text(
                  '${adminLabel(event['action'])}${auditNote(event)['days'] == null ? '' : ' · ${auditNote(event)['days']} days'}',
                ),
                subtitle: SelectableText(
                  '${adminDate(event['created_at'])} · Admin ${event['actor_id']}\n${showTarget ? 'Target: ${event['target_id']}\n' : ''}${auditNote(event)['report_status'] == null ? '' : 'Report: ${adminLabel(auditNote(event)['report_status'])}\n'}${auditNote(event)['reason'] ?? ''}',
                ),
                trailing: event['report_id'] == null && !showTarget
                    ? null
                    : IconButton(
                        tooltip:
                            event['report_id'] != null ||
                                event['action'] == 'review'
                            ? 'Open report'
                            : 'Open user',
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () => context.push(
                          '${Routes.admin}/${event['report_id'] != null || event['action'] == 'review' ? 'reports' : 'users'}/${event['report_id'] ?? event['target_id']}',
                        ),
                      ),
              ),
          ],
        );
}

void adminMessage(BuildContext context, String message) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(message)));

List<String> accountDecisions(String status, {bool isAdmin = false}) => isAdmin
    ? []
    : switch (status) {
        'active' => ['warning', 'suspend', 'ban'],
        'suspended' => ['ban', 'reactivate'],
        'banned' => ['reactivate'],
        _ => [],
      };

class AdminDecisionForm extends ConsumerStatefulWidget {
  const AdminDecisionForm({
    super.key,
    required this.targetId,
    required this.actions,
    this.reportId,
  });
  final String targetId;
  final List<String> actions;
  final String? reportId;
  @override
  ConsumerState<AdminDecisionForm> createState() => _AdminDecisionFormState();
}

class _AdminDecisionFormState extends ConsumerState<AdminDecisionForm> {
  final _note = TextEditingController();
  String? _action;
  int _days = 7;
  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(adminViewModelProvider);
    final action = widget.actions.contains(_action)
        ? _action!
        : widget.actions.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _note,
          enabled: !busy,
          maxLength: 1000,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Admin note',
            hintText: 'Internal review note and reason for this decision...',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const Text('Internal notes are visible only to administrators.'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in widget.actions)
              ChoiceChip(
                label: Text(adminLabel(option)),
                selected: action == option,
                onSelected: busy
                    ? null
                    : (_) => setState(() => _action = option),
              ),
          ],
        ),
        if (action == 'suspend')
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: AdminFilter(
              label: 'Suspension duration',
              value: '$_days',
              values: {
                for (final n in [1, 3, 7, 30])
                  '$n': '$n ${n == 1 ? 'day' : 'days'}',
              },
              onChanged: busy
                  ? (_) {}
                  : (v) => setState(() => _days = int.parse(v)),
            ),
          ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            icon: Icon(busy ? Icons.hourglass_top : Icons.check),
            label: Text(
              action == 'start_review'
                  ? 'Start review'
                  : widget.reportId != null
                  ? 'Save decision / Close case'
                  : 'Save decision',
            ),
            onPressed: busy || _note.text.trim().isEmpty
                ? null
                : () => _submit(action),
          ),
        ),
      ],
    );
  }

  Future<void> _submit(String action) async {
    final note = _note.text.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          action == 'ban' ? 'Permanently ban user?' : '${adminLabel(action)}?',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (action == 'ban')
                const Text(
                  'This permanently restricts the account. Confirm that you have reviewed the case.',
                ),
              if (action == 'suspend')
                Text('The account will be restricted for $_days days.'),
              if (action == 'reactivate')
                const Text('This restores access to the account.'),
              if (action == 'dismiss' || action == 'no_action')
                const Text(
                  'The case will close without an account restriction.',
                ),
              const SizedBox(height: 16),
              SelectableText('User: ${widget.targetId}\n\nReason: $note'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm decision'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(adminViewModelProvider.notifier)
          .decide(
            widget.targetId,
            action,
            note,
            reportId: widget.reportId,
            days: action == 'suspend' ? _days : null,
          );
      if (mounted) {
        _note.clear();
        adminMessage(context, 'Decision saved.');
      }
    } catch (_) {
      if (mounted) {
        adminMessage(
          context,
          'Unable to save the decision. Refresh and check the current status before retrying.',
        );
      }
    }
  }
}

class AdminReportReason extends StatelessWidget {
  const AdminReportReason(this.value, {super.key, this.compact = false});
  final bool compact;
  final Object? value;
  @override
  Widget build(BuildContext context) {
    final reason = UserReportReason.fromValue(value?.toString());
    final attention = reason?.attention ?? 0;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          adminLabel(value),
          maxLines: compact ? 1 : 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (attention > 0)
          Text(
            attention == 2
                ? 'Safety concern - review first'
                : 'Higher review attention',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: attention == 2 ? scheme.error : scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}
