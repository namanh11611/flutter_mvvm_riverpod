import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../repository/identity_review_repository.dart';
import 'widgets/admin_theme.dart';
import 'widgets/admin_widgets.dart';

class IdentityReviewsScreen extends StatefulWidget {
  const IdentityReviewsScreen({super.key});

  @override
  State<IdentityReviewsScreen> createState() => _IdentityReviewsScreenState();
}

class _IdentityReviewsScreenState extends State<IdentityReviewsScreen> {
  final _repository = const AdminIdentityReviewRepository();
  late Future<bool> _access;
  late Future<AdminIdentityReviewQueue> _queue;

  @override
  void initState() {
    super.initState();
    _access = _repository.isAdmin();
    _queue = _access.then(
      (allowed) => allowed
          ? _repository.fetchQueue()
          : const AdminIdentityReviewQueue(items: [], unmatchedCount: 0),
    );
  }

  void _reload() => _queue = _repository.fetchQueue();

  Future<void> _refresh() async {
    setState(_reload);
    await _queue;
  }

  @override
  Widget build(BuildContext context) => AdminScaffold(
    section: 4,
    title: 'Review Verification',
    onRefresh: _refresh,
    child: FutureBuilder<bool>(
      future: _access,
      builder: (context, accessSnapshot) {
        if (accessSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (accessSnapshot.data != true) {
          return const _MessageView(
            icon: Icons.lock_outline_rounded,
            message: 'Admin access is required to review identities.',
          );
        }
        return _buildQueue();
      },
    ),
  );

  Widget _buildQueue() => FutureBuilder<AdminIdentityReviewQueue>(
    future: _queue,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return _MessageView(
          icon: Icons.error_outline,
          message: snapshot.error.toString(),
          action: FilledButton(
            onPressed: _refresh,
            child: const Text('Try again'),
          ),
        );
      }
      final queue =
          snapshot.data ??
          const AdminIdentityReviewQueue(items: [], unmatchedCount: 0);
      final reviews = queue.items;
      if (reviews.isEmpty) {
        return RefreshIndicator(
          onRefresh: _refresh,
          child: _MessageView(
            icon: Icons.verified_user_outlined,
            message: queue.unmatchedCount > 0
                ? '${queue.unmatchedCount} Didit verification(s) need review, but they are not linked to a GoBuddy verification attempt.'
                : 'No identity verifications need review.',
            scrollable: true,
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final review = reviews[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.manage_search_rounded),
                ),
                title: Text(review.displayName),
                subtitle: Text(
                  review.submittedAt == null
                      ? 'Didit status: ${review.providerStatus}'
                      : 'Didit status: ${review.providerStatus}\nSubmitted ${DateFormat.yMMMd().add_jm().format(review.submittedAt!.toLocal())}',
                ),
                isThreeLine: review.submittedAt != null,
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => _IdentityReviewDetailsScreen(
                        verificationId: review.id,
                        repository: _repository,
                      ),
                    ),
                  );
                  await _refresh();
                },
              ),
            );
          },
        ),
      );
    },
  );
}

class _IdentityReviewDetailsScreen extends StatefulWidget {
  const _IdentityReviewDetailsScreen({
    required this.verificationId,
    required this.repository,
  });

  final String verificationId;
  final AdminIdentityReviewRepository repository;

  @override
  State<_IdentityReviewDetailsScreen> createState() =>
      _IdentityReviewDetailsScreenState();
}

class _IdentityReviewDetailsScreenState
    extends State<_IdentityReviewDetailsScreen> {
  late Future<AdminIdentityReviewDetails> _details;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _details = widget.repository.fetchDetails(widget.verificationId);
  }

  Future<void> _decide(String decision) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(switch (decision) {
          'Declined' => 'Reject verification',
          'Resubmitted' => 'Request resubmission',
          _ => 'Approve verification',
        }),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 1000,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: switch (decision) {
              'Declined' => 'Rejection reason',
              'Resubmitted' => 'Resubmission instructions',
              _ => 'Review note',
            },
            hintText: switch (decision) {
              'Declined' =>
                'Explain what failed and what the user should correct.',
              'Resubmitted' =>
                'Explain what the user must capture or provide again.',
              _ => 'Record why this verification is approved.',
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: Text(switch (decision) {
              'Declined' => 'Reject',
              'Resubmitted' => 'Request resubmission',
              _ => 'Approve',
            }),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || !mounted) return;
    setState(() => _submitting = true);
    try {
      await widget.repository.submitDecision(
        verificationId: widget.verificationId,
        decision: decision,
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (decision) {
            'Declined' => 'Verification rejected in Didit.',
            'Resubmitted' => 'Resubmission requested in Didit.',
            _ => 'Verification approved in Didit.',
          }),
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: AdminTheme.from(Theme.of(context)),
    child: Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Review Verification')),
        body: FutureBuilder<AdminIdentityReviewDetails>(
          future: _details,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              if (snapshot.hasError) {
                return _MessageView(
                  icon: Icons.error_outline,
                  message: snapshot.error.toString(),
                );
              }
              return const Center(child: CircularProgressIndicator());
            }
            final details = snapshot.data!;
            final groups = _factGroups(_decisionFacts(details.decision));
            final images = _decisionImages(details.decision);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ReviewHeader(review: details.review),
                        const SizedBox(height: 24),
                        for (final group in groups.entries)
                          AdminPanel(
                            title: group.key,
                            child: _FactGrid(facts: group.value),
                          ),
                        if (groups.isEmpty)
                          const AdminPanel(
                            title: 'Verification Information',
                            child: Text(
                              'Didit did not return additional verification details.',
                            ),
                          ),
                        if (images.isNotEmpty)
                          AdminPanel(
                            title: 'Evidence',
                            trailing: Text(
                              '${images.length} ${images.length == 1 ? 'image' : 'images'}',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            child: _EvidenceGrid(images: images),
                          ),
                        _DecisionPanel(
                          submitting: _submitting,
                          onDecision: _decide,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader({required this.review});

  final AdminIdentityReview review;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Wrap(
          spacing: 24,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: scheme.onPrimary.withValues(alpha: .14),
              foregroundColor: scheme.onPrimary,
              child: const Icon(Icons.badge_outlined, size: 30),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 220, maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.displayName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    review.submittedAt == null
                        ? 'Submitted date unavailable'
                        : 'Submitted ${DateFormat.yMMMd().add_jm().format(review.submittedAt!.toLocal())}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onPrimary.withValues(alpha: .82),
                    ),
                  ),
                ],
              ),
            ),
            Chip(
              avatar: const Icon(Icons.manage_search_rounded, size: 18),
              label: Text(review.providerStatus),
              backgroundColor: scheme.surface,
              side: BorderSide.none,
              labelStyle: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FactGrid extends StatelessWidget {
  const _FactGrid({required this.facts});

  final List<(String, String)> facts;

  @override
  Widget build(BuildContext context) {
    final scores = facts.where(_isScoreFact).toList(growable: false);
    final scoreGroups = <String, List<(String, String)>>{};
    for (final score in scores) {
      scoreGroups.putIfAbsent(_factSubsection(score.$1), () => []).add(score);
    }
    final details = facts.where((fact) => !_isScoreFact(fact));
    final subsections = <String, List<(String, String)>>{};
    for (final fact in details) {
      final subsection = _factSubsection(fact.$1);
      subsections.putIfAbsent(subsection, () => []).add(fact);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (scores.isNotEmpty) ...[
          Text(
            'Quality Scores',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < scoreGroups.entries.length; i++) ...[
            _ScoreSubsection(
              title: scoreGroups.entries.elementAt(i).key,
              scores: scoreGroups.entries.elementAt(i).value,
            ),
            if (i < scoreGroups.length - 1) const SizedBox(height: 16),
          ],
          if (subsections.isNotEmpty) const SizedBox(height: 24),
        ],
        for (var i = 0; i < subsections.entries.length; i++) ...[
          _FactSubsection(
            title: subsections.entries.elementAt(i).key,
            facts: subsections.entries.elementAt(i).value,
          ),
          if (i < subsections.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _ScoreSubsection extends StatelessWidget {
  const _ScoreSubsection({required this.title, required this.scores});

  final String title;
  final List<(String, String)> scores;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .04),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title == 'General' ? 'Overall Scores' : title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [for (final score in scores) _ScoreRing(fact: score)],
          ),
        ],
      ),
    ),
  );
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.fact});

  final (String, String) fact;

  @override
  Widget build(BuildContext context) {
    final raw = double.tryParse(fact.$2.replaceAll('%', '').trim());
    final normalized = raw == null
        ? 0.0
        : (raw > 1 ? raw / 100 : raw).clamp(0.0, 1.0);
    final color = normalized >= .8
        ? const Color(0xFF23856D)
        : normalized >= .6
        ? const Color(0xFFC27A16)
        : Theme.of(context).colorScheme.error;
    final display = raw == null ? fact.$2 : '${(normalized * 100).round()}%';
    final label = _factDisplayLabel(fact.$1);
    return SizedBox(
      width: 132,
      child: Column(
        children: [
          SizedBox.square(
            dimension: 82,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: normalized,
                    strokeWidth: 7,
                    strokeCap: StrokeCap.round,
                    color: color,
                    backgroundColor: color.withValues(alpha: .15),
                  ),
                ),
                Text(
                  display,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _FactSubsection extends StatelessWidget {
  const _FactSubsection({required this.title, required this.facts});

  final String title;
  final List<(String, String)> facts;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .04),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != 'General') ...[
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Divider(height: 20),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 820
                  ? 3
                  : constraints.maxWidth >= 500
                  ? 2
                  : 1;
              const spacing = 16.0;
              final width =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: 14,
                children: [
                  for (final fact in facts)
                    SizedBox(
                      width: width,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _factDisplayLabel(fact.$1),
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            fact.$2,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}

bool _isScoreFact((String, String) fact) =>
    fact.$1.toLowerCase().contains('score') &&
    double.tryParse(fact.$2.replaceAll('%', '').trim()) != null;

List<String> _factParts(String label) => label
    .split(RegExp(r'\s+[>›·]\s+'))
    .where((part) => part.trim().isNotEmpty)
    .toList(growable: false);

String _factSubsection(String label) {
  final parts = _factParts(label);
  final lower = parts.map((part) => part.toLowerCase()).toList();
  if (lower.any((part) => part.contains('front'))) return 'Front Image';
  if (lower.any((part) => part.contains('back'))) return 'Back Image';
  final warningIndex = lower.indexWhere((part) => part.contains('warning'));
  if (warningIndex >= 0 && warningIndex + 1 < parts.length) {
    final item = int.tryParse(parts[warningIndex + 1]);
    if (item != null) return 'Warning $item';
  }

  final meaningful = parts
      .where((part) => !RegExp(r'^\d+$').hasMatch(part.trim()))
      .toList(growable: false);
  if (meaningful.length < 2) return 'General';
  final parent = meaningful[meaningful.length - 2];
  if ({
    'id verifications',
    'document verification',
    'face matches',
    'liveness checks',
  }.contains(parent.toLowerCase())) {
    return 'General';
  }
  return parent;
}

String _factDisplayLabel(String label) {
  final parts = _factParts(label);
  if (parts.isEmpty) return label;
  var result = parts.last.replaceFirst(
    RegExp(r'^(front|back)\s+(side\s+)?(image\s+)?', caseSensitive: false),
    '',
  );
  if (result.toLowerCase() == 'score' && parts.length > 1) {
    final parent = parts[parts.length - 2];
    if (!RegExp(r'^\d+$').hasMatch(parent.trim())) result = '$parent score';
  }
  return result.isEmpty ? parts.last : result;
}

class _EvidenceGrid extends StatelessWidget {
  const _EvidenceGrid({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 900
          ? 3
          : constraints.maxWidth >= 560
          ? 2
          : 1;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: images.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
        ),
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ColoredBox(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .05),
            child: Image.network(
              images[index],
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image_outlined, size: 32),
                      SizedBox(height: 8),
                      Text('Evidence image unavailable'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _DecisionPanel extends StatelessWidget {
  const _DecisionPanel({required this.submitting, required this.onDecision});

  final bool submitting;
  final ValueChanged<String> onDecision;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AdminPanel(
      title: 'Make a Decision',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Review the information and evidence above before choosing an outcome. A review note is required.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (submitting) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 680;
              final buttons = [
                OutlinedButton.icon(
                  onPressed: submitting
                      ? null
                      : () => onDecision('Resubmitted'),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Request resubmission'),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.error,
                    side: BorderSide(color: scheme.error),
                  ),
                  onPressed: submitting ? null : () => onDecision('Declined'),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Reject verification'),
                ),
                FilledButton.icon(
                  onPressed: submitting ? null : () => onDecision('Approved'),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Approve verification'),
                ),
              ];
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < buttons.length; i++) ...[
                      SizedBox(height: 48, child: buttons[i]),
                      if (i < buttons.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  for (var i = 0; i < buttons.length; i++) ...[
                    Expanded(child: SizedBox(height: 48, child: buttons[i])),
                    if (i < buttons.length - 1) const SizedBox(width: 12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

List<(String, String)> _decisionFacts(Map<String, dynamic> decision) {
  final facts = <(String, String)>[];
  void visit(Object? value, String path) {
    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString();
        final next = path.isEmpty ? key : '$path › $key';
        if (entry.value is String ||
            entry.value is num ||
            entry.value is bool) {
          if (!key.toLowerCase().contains('image') &&
              !key.toLowerCase().contains('video') &&
              !key.toLowerCase().contains('token')) {
            facts.add((_label(next), entry.value.toString()));
          }
        } else {
          visit(entry.value, next);
        }
      }
    } else if (value is List) {
      for (var i = 0; i < value.length; i++) {
        visit(value[i], path.isEmpty ? '${i + 1}' : '$path › ${i + 1}');
      }
    }
  }

  visit(decision, '');
  return facts.take(80).toList(growable: false);
}

Map<String, List<(String, String)>> _factGroups(List<(String, String)> facts) {
  final groups = <String, List<(String, String)>>{};
  for (final fact in facts) {
    final key = fact.$1.toLowerCase();
    final group = switch (key) {
      _
          when key.contains('document') ||
              key.contains('id verification') ||
              key.contains('nfc') =>
        'Document Verification',
      _ when key.contains('face') || key.contains('liveness') =>
        'Face & Liveness Checks',
      _
          when key.contains('aml') ||
              key.contains('database') ||
              key.contains('phone') ||
              key.contains('email') ||
              key.contains('ip analys') =>
        'Additional Checks',
      _
          when key.contains('session') ||
              key.contains('status') ||
              key.contains('workflow') ||
              key.contains('vendor') ||
              key.contains('created') =>
        'Session Overview',
      _ => 'Other Information',
    };
    groups.putIfAbsent(group, () => []).add(fact);
  }
  return groups;
}

List<String> _decisionImages(Map<String, dynamic> decision) {
  final images = <String>{};
  void visit(Object? value, String key) {
    if (value is Map) {
      for (final entry in value.entries) {
        visit(entry.value, entry.key.toString());
      }
    } else if (value is List) {
      for (final item in value) {
        visit(item, key);
      }
    } else if (value is String &&
        key.toLowerCase().contains('image') &&
        Uri.tryParse(value)?.isScheme('https') == true) {
      images.add(value);
    }
  }

  visit(decision, '');
  return images.take(12).toList(growable: false);
}

String _label(String value) => value
    .replaceAll('_', ' ')
    .split(' › ')
    .map(
      (part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}',
    )
    .join(' › ');

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.message,
    this.action,
    this.scrollable = false,
  });

  final IconData icon;
  final String message;
  final Widget? action;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final child = Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
    if (!scrollable) return child;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * .7, child: child),
      ],
    );
  }
}
