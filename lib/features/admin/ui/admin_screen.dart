import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/routes.dart';
import '../model/moderation.dart';
import 'view_model/admin_view_model.dart';
import 'widgets/admin_widgets.dart';
import 'widgets/admin_theme.dart';
import '../../safety/model/user_safety.dart';
export 'admin_detail_screens.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key, this.section = 0, this.status = 'all'});
  final int section;
  final String status;
  @override
  Widget build(BuildContext context) => switch (section) {
    0 => const AdminDashboardScreen(),
    3 => const AdminActivityScreen(),
    _ => AdminCollectionScreen(
      key: ValueKey('$section:$status'),
      reports: section == 1,
      initialStatus: status,
    ),
  };
}

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => AdminScaffold(
    section: 0,
    title: 'Admin Dashboard',
    onRefresh: () => ref.invalidate(adminDashboardProvider),
    child: AdminLoad(
      value: ref.watch(adminDashboardProvider),
      retry: () => ref.invalidate(adminDashboardProvider),
      builder: (data) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Items requiring attention',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final entry in const {
                    'pending': 'Pending Reports',
                    'reviewing': 'Under Review',
                    'suspended': 'Suspended Users',
                    'banned': 'Banned Users',
                  }.entries)
                    SizedBox(
                      width: width,
                      height:
                          112 + 32 * MediaQuery.textScalerOf(context).scale(1),
                      child: Card(
                        color: AdminTheme.metric(
                          entry.key,
                          Theme.of(context).brightness == Brightness.dark,
                        ).background,
                        margin: EdgeInsets.zero,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => context.go(
                            '${Routes.admin}/${['suspended', 'banned'].contains(entry.key) ? 'users' : 'reports'}?status=${entry.key}',
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.value,
                                  style: TextStyle(
                                    color: AdminTheme.metric(
                                      entry.key,
                                      Theme.of(context).brightness ==
                                          Brightness.dark,
                                    ).foreground,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${data['counts'][entry.key] ?? '-'}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineLarge
                                            ?.copyWith(
                                              color: AdminTheme.metric(
                                                entry.key,
                                                Theme.of(context).brightness ==
                                                    Brightness.dark,
                                              ).foreground,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 20,
                                      color: AdminTheme.metric(
                                        entry.key,
                                        Theme.of(context).brightness ==
                                            Brightness.dark,
                                      ).foreground,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              Text('Reports received today: ${data['counts']['today'] ?? '—'}'),
              Text('Resolved reports: ${data['counts']['resolved'] ?? '—'}'),
            ],
          ),
          const SizedBox(height: 24),
          AdminPanel(
            title: 'Recent Reports',
            compact: true,
            trailing: TextButton(
              onPressed: () => context.go('${Routes.admin}/reports'),
              child: const Text('View all'),
            ),
            child: AdminReportRows(
              compact: true,
              rows: (data['recent'] as List)
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList(),
            ),
          ),
          AdminPanel(
            title: 'Recent Admin Activities',
            trailing: TextButton(
              onPressed: () => context.go('${Routes.admin}/activity'),
              child: const Text('View all'),
            ),
            child: AdminHistory(
              (data['activity'] as List? ?? [])
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList(),
            ),
          ),
        ],
      ),
    ),
  );
}

class AdminCollectionScreen extends ConsumerStatefulWidget {
  const AdminCollectionScreen({
    super.key,
    required this.reports,
    required this.initialStatus,
  });
  final bool reports;
  final String initialStatus;
  @override
  ConsumerState<AdminCollectionScreen> createState() =>
      _AdminCollectionScreenState();
}

class _AdminCollectionScreenState extends ConsumerState<AdminCollectionScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '', _category = 'all', _date = 'all', _sort = 'newest';
  late String _status;
  int _page = 0;
  @override
  void initState() {
    super.initState();
    final allowed = widget.reports
        ? ['all', 'pending', 'reviewing', 'resolved', 'dismissed']
        : ['all', 'active', 'suspended', 'banned'];
    _status = allowed.contains(widget.initialStatus)
        ? widget.initialStatus
        : 'all';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _change(VoidCallback update) => setState(() {
    update();
    _page = 0;
  });
  @override
  Widget build(BuildContext context) {
    final query = (
      reports: widget.reports,
      page: _page,
      filter: jsonEncode({
        'search': _query,
        'status': _status,
        if (widget.reports) ...{
          'category': _category,
          'since': _since(_date),
          'oldest': _sort == 'oldest',
        },
      }),
    );
    return AdminScaffold(
      section: widget.reports ? 1 : 2,
      title: widget.reports ? 'Reports' : 'User Management',
      onRefresh: () => ref.invalidate(adminItemsProvider(query)),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: widget.reports
                  ? 'Search report ID / username / user ID...'
                  : 'Search username / email / user ID...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _debounce?.cancel();
                  _search.clear();
                  _change(() => _query = '');
                },
              ),
            ),
            onChanged: (value) {
              _debounce?.cancel();
              _debounce = Timer(
                const Duration(milliseconds: 350),
                () => _change(() => _query = value.trim()),
              );
            },
            onSubmitted: (value) {
              _debounce?.cancel();
              _change(() => _query = value.trim());
            },
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 16,
              runSpacing: 16,
              children:
                  [
                        AdminFilter(
                          label: 'Status',
                          value: _status,
                          values: {
                            for (final s
                                in widget.reports
                                    ? [
                                        'all',
                                        'pending',
                                        'reviewing',
                                        'resolved',
                                        'dismissed',
                                      ]
                                    : ['all', 'active', 'suspended', 'banned'])
                              s: adminLabel(s),
                          },
                          onChanged: (v) => _change(() => _status = v),
                        ),
                        if (widget.reports) ...[
                          AdminFilter(
                            label: 'Category',
                            value: _category,
                            values: {
                              'all': 'All',
                              for (final reason in UserReportReason.values)
                                reason.name: reason.label,
                            },
                            onChanged: (v) => _change(() => _category = v),
                          ),
                          AdminFilter(
                            label: 'Date',
                            value: _date,
                            values: _dates,
                            onChanged: (v) => _change(() => _date = v),
                          ),
                          AdminFilter(
                            label: 'Sort',
                            value: _sort,
                            values: const {
                              'newest': 'Newest first',
                              'oldest': 'Oldest first',
                            },
                            onChanged: (v) => _change(() => _sort = v),
                          ),
                        ],
                      ]
                      .map(
                        (filter) => SizedBox(
                          width: widget.reports
                              ? (constraints.maxWidth - 16) / 2
                              : 200,
                          child: filter,
                        ),
                      )
                      .toList(),
            ),
          ),
          const SizedBox(height: 24),
          AdminLoad<List<ModerationItem>>(
            value: ref.watch(adminItemsProvider(query)),
            retry: () => ref.invalidate(adminItemsProvider(query)),
            builder: (items) => Column(
              children: [
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No results.'),
                  )
                else if (widget.reports)
                  AdminReportRows(rows: items.map((e) => e.data).toList())
                else
                  _UserRows(rows: items.map((e) => e.data).toList()),
                const SizedBox(height: 16),
                _Pagination(
                  page: _page,
                  hasNext: items.length == 50,
                  onChanged: (page) => setState(() => _page = page),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminReportRows extends StatelessWidget {
  const AdminReportRows({super.key, required this.rows, this.compact = false});
  final bool compact;
  final List<Map<String, dynamic>> rows;
  @override
  Widget build(BuildContext context) {
    void open(Map<String, dynamic> row) =>
        context.push('${Routes.admin}/reports/${row['id']}');
    if (rows.isEmpty) return const Text('No reports found.');
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 760
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                horizontalMargin: compact ? 8 : 16,
                headingRowHeight: compact ? 40 : 56,
                dataRowMinHeight: compact ? 40 : 48,
                dataRowMaxHeight: compact ? 48 : 56,
                columns: const [
                  DataColumn(label: Text('Report ID')),
                  DataColumn(label: Text('Reported User')),
                  DataColumn(label: Text('Reason')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Action')),
                ],
                rows: [
                  for (final r in rows)
                    DataRow(
                      cells: [
                        DataCell(
                          Tooltip(
                            message: '${r['id']}',
                            child: Text(shortId(r['id'])),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 140,
                            child: Text(
                              '${r['reported_user_name'] ?? 'Unknown user'}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 210,
                            child: AdminReportReason(
                              r['reason'],
                              compact: compact,
                            ),
                          ),
                        ),
                        DataCell(Text(adminDate(r['created_at']))),
                        DataCell(
                          compact
                              ? Text(
                                  adminLabel(r['status']),
                                  style: Theme.of(context).textTheme.bodySmall,
                                )
                              : AdminStatus('${r['status']}'),
                        ),
                        DataCell(
                          TextButton(
                            onPressed: () => open(r),
                            child: const Text('View Details'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            )
          : compact
          ? Column(
              children: [
                for (var index = 0; index < rows.length; index++) ...[
                  if (index > 0) const Divider(height: 1, thickness: 1),
                  InkWell(
                    onTap: () => open(rows[index]),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${rows[index]['reported_user_name'] ?? 'Unknown user'} - ${adminLabel(rows[index]['reason'])}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${adminDate(rows[index]['created_at'])} · ${adminLabel(rows[index]['status'])}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            )
          : Column(
              children: [
                for (final r in rows)
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      onTap: () => open(r),
                      title: Text(
                        '${r['reported_user_name'] ?? 'Unknown user'}',
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${shortId(r['id'])} · ${adminDate(r['created_at'])}',
                          ),
                          AdminReportReason(r['reason']),
                          AdminStatus('${r['status']}'),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _UserRows extends StatelessWidget {
  const _UserRows({required this.rows});
  final List<Map<String, dynamic>> rows;
  @override
  Widget build(BuildContext context) {
    void open(Map<String, dynamic> row) =>
        context.push('${Routes.admin}/users/${row['id']}');
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 760
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                horizontalMargin: 16,
                columns: const [
                  DataColumn(label: Text('User')),
                  DataColumn(label: Text('Account Status')),
                  DataColumn(label: Text('Reports')),
                  DataColumn(label: Text('Warnings')),
                  DataColumn(label: Text('Action')),
                ],
                rows: [
                  for (final r in rows)
                    DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 220,
                            child: Text(
                              '${r['display_name'] ?? 'Unnamed user'}\n${r['email'] ?? r['id']}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(AdminStatus('${r['account_status']}')),
                        DataCell(Text('${r['report_count']}')),
                        DataCell(Text('${r['warning_count']}')),
                        DataCell(
                          TextButton(
                            onPressed: () => open(r),
                            child: const Text('View'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            )
          : Column(
              children: [
                for (final r in rows)
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      onTap: () => open(r),
                      title: Text('${r['display_name'] ?? 'Unnamed user'}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${r['email'] ?? r['id']}'),
                          AdminStatus('${r['account_status']}'),
                          Text(
                            'Reports: ${r['report_count']} · Warnings: ${r['warning_count']}',
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
              ],
            ),
    );
  }
}

const _dates = {
  'all': 'All dates',
  'today': 'Today',
  'week': 'Last 7 days',
  'month': 'Last 30 days',
};
String? _since(String value) {
  if (value == 'all') return null;
  final now = DateTime.now();
  final date = DateTime(now.year, now.month, now.day).subtract(
    Duration(
      days: value == 'week'
          ? 6
          : value == 'month'
          ? 29
          : 0,
    ),
  );
  return date.toUtc().toIso8601String();
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.page,
    required this.hasNext,
    required this.onChanged,
  });
  final int page;
  final bool hasNext;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      TextButton(
        onPressed: page > 0 ? () => onChanged(page - 1) : null,
        child: const Text('Previous'),
      ),
      Text('Page ${page + 1}'),
      TextButton(
        onPressed: hasNext ? () => onChanged(page + 1) : null,
        child: const Text('Next'),
      ),
    ],
  );
}

class AdminActivityScreen extends ConsumerStatefulWidget {
  const AdminActivityScreen({super.key});
  @override
  ConsumerState<AdminActivityScreen> createState() =>
      _AdminActivityScreenState();
}

class _AdminActivityScreenState extends ConsumerState<AdminActivityScreen> {
  String _actor = '', _action = 'all', _date = 'all';
  int _page = 0;
  void _change(VoidCallback change) => setState(() {
    change();
    _page = 0;
  });
  @override
  Widget build(BuildContext context) {
    final filter = jsonEncode({
      'actor': _actor,
      'type': _action,
      'since': _since(_date),
      'page': _page,
    });
    return AdminScaffold(
      section: 3,
      title: 'Activity Logs',
      onRefresh: () => ref.invalidate(adminActivityProvider(filter)),
      child: AdminLoad(
        value: ref.watch(adminActivityProvider(filter)),
        retry: () => ref.invalidate(adminActivityProvider(filter)),
        builder: (data) {
          final rows = (data['items'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          final admins = {
            for (final a in data['admins'] as List)
              '${a['id']}': '${a['name']}',
          };
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  AdminFilter(
                    label: 'Admin',
                    value: _actor,
                    values: {'': 'All admins', ...admins},
                    onChanged: (v) => _change(() => _actor = v),
                  ),
                  AdminFilter(
                    label: 'Action',
                    value: _action,
                    values: {
                      for (final a in [
                        'all',
                        'start_review',
                        'dismiss',
                        'no_action',
                        'warning',
                        'suspend',
                        'ban',
                        'reactivate',
                        'review',
                        'unban',
                        'removeImage',
                      ])
                        a: adminLabel(a),
                    },
                    onChanged: (v) => _change(() => _action = v),
                  ),
                  AdminFilter(
                    label: 'Date',
                    value: _date,
                    values: _dates,
                    onChanged: (v) => _change(() => _date = v),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (rows.isEmpty)
                const Text('No activity matches these filters.')
              else
                LayoutBuilder(
                  builder: (context, constraints) => constraints.maxWidth >= 760
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 16,
                            horizontalMargin: 16,
                            columns: const [
                              DataColumn(label: Text('Time')),
                              DataColumn(label: Text('Admin')),
                              DataColumn(label: Text('Action')),
                              DataColumn(label: Text('Target')),
                              DataColumn(label: Text('Note')),
                            ],
                            rows: [
                              for (final e in rows)
                                DataRow(
                                  cells: [
                                    DataCell(Text(adminDate(e['created_at']))),
                                    DataCell(
                                      Text(
                                        admins[e['actor_id']] ??
                                            shortId(e['actor_id']),
                                      ),
                                    ),
                                    DataCell(Text(adminLabel(e['action']))),
                                    DataCell(
                                      TextButton(
                                        onPressed: () => context.push(
                                          '${Routes.admin}/${e['report_id'] != null || e['action'] == 'review' ? 'reports' : 'users'}/${e['report_id'] ?? e['target_id']}',
                                        ),
                                        child: Text(
                                          shortId(
                                            e['report_id'] ?? e['target_id'],
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 240,
                                        child: Text(
                                          '${auditNote(e)['reason'] ?? ''}',
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      onTap: () => showDialog<void>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Internal note'),
                                          content: SingleChildScrollView(
                                            child: SelectableText(
                                              '${auditNote(e)['reason'] ?? ''}',
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Close'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        )
                      : AdminHistory(rows, showTarget: true),
                ),
              const SizedBox(height: 24),
              _Pagination(
                page: _page,
                hasNext: rows.length == 50,
                onChanged: (v) => setState(() => _page = v),
              ),
            ],
          );
        },
      ),
    );
  }
}
