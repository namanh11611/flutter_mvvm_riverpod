import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/user_safety.dart';
import '../view_model/report_user_view_model.dart';

class ReportUserAction {
  const ReportUserAction._();
  static Future<void> show({
    required BuildContext context,
    required WidgetRef ref,
    required String targetUserId,
    required String targetDisplayName,
  }) async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _ReportUserSheet(
        targetUserId: targetUserId,
        targetDisplayName: targetDisplayName,
      ),
    );
    if (submitted == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Report submitted. Thank you for helping keep GoBuddy safe.',
          ),
        ),
      );
    }
  }
}

class _ReportUserSheet extends ConsumerStatefulWidget {
  const _ReportUserSheet({
    required this.targetUserId,
    required this.targetDisplayName,
  });
  final String targetUserId, targetDisplayName;
  @override
  ConsumerState<_ReportUserSheet> createState() => _ReportUserSheetState();
}

class _ReportUserSheetState extends ConsumerState<_ReportUserSheet> {
  final _description = TextEditingController();
  UserReportReason? _reason;
  bool _confirming = false;
  String? _error;
  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(reportUserViewModelProvider) || _confirming;
    return PopScope(
      canPop: !busy,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Report User',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text('You are reporting: ${widget.targetDisplayName}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserReportReason>(
                initialValue: _reason,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Why are you reporting this user?',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final reason in UserReportReason.values)
                    DropdownMenuItem(
                      value: reason,
                      child: Text(
                        reason.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                selectedItemBuilder: (context) => [
                  for (final reason in UserReportReason.values)
                    Text(reason.label, overflow: TextOverflow.ellipsis),
                ],
                onChanged: busy
                    ? null
                    : (value) => setState(() {
                        _reason = value;
                        _error = null;
                      }),
              ),
              if (_reason != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_reason!.description),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: _description,
                enabled: !busy,
                maxLength: 1000,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: _reason == UserReportReason.other
                      ? 'Tell us what happened (required)'
                      : 'Tell us what happened (optional)',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() => _error = null),
              ),
              const Text(
                'Reporting sends a case to an administrator. It does not block this user.',
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed:
                        busy ||
                            UserReportReason.validate(
                                  _reason,
                                  _description.text,
                                ) !=
                                null
                        ? null
                        : _submit,
                    child: Text(busy ? 'Submitting...' : 'Continue'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _confirming = true);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit report?'),
        content: SingleChildScrollView(
          child: Text(
            'User: ${widget.targetDisplayName}\nReason: ${_reason!.label}\n\n${_description.text.trim()}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit report'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _confirming = false);
    if (confirmed != true) return;
    try {
      await ref
          .read(reportUserViewModelProvider.notifier)
          .submit(widget.targetUserId, _reason, _description.text);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Unable to submit your report. Please try again.',
        );
      }
    }
  }
}
