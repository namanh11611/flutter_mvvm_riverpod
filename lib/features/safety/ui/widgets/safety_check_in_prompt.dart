import 'package:flutter/material.dart';

import '../../../../core/routing/router.dart';
import '../../../../core/routing/routes.dart';
import '../../../common/remote/supabase_client.dart';
import '../../model/safety_check_in.dart';
import '../../repository/safety_check_in_repository.dart';

Future<void> showSafetyCheckInPrompt(
  BuildContext context, {
  String? checkInId,
  String? tripId,
  bool createRecord = true,
  Future<void> Function()? onResponded,
}) async {
  if (!context.mounted) return;
  var promptId = checkInId;
  if (promptId == null && createRecord) {
    try {
      promptId = (await SupabaseSafetyCheckInRepository(supabase)
              .createPrompt(tripId: tripId))
          .id;
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
      return;
    }
  }
  if (!context.mounted) return;
  final resolvedPromptId = promptId;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _SafetyCheckInDialog(
      checkInId: resolvedPromptId,
      onResponded: onResponded,
    ),
  );
}

class _SafetyCheckInDialog extends StatefulWidget {
  const _SafetyCheckInDialog({required this.checkInId, this.onResponded});
  final String? checkInId;
  final Future<void> Function()? onResponded;

  @override
  State<_SafetyCheckInDialog> createState() => _SafetyCheckInDialogState();
}

class _SafetyCheckInDialogState extends State<_SafetyCheckInDialog> {
  bool _saving = false;
  String? _error;

  Future<void> _respond(SafetyCheckInStatus status) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.checkInId != null) {
        final repository = SupabaseSafetyCheckInRepository(supabase);
        await repository.respond(widget.checkInId!, status);
      }
      await widget.onResponded?.call();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(
        content: Text(status == SafetyCheckInStatus.safe
            ? 'Check-in confirmed. Stay safe!'
            : 'Opening emergency help.'),
      ));
      if (status == SafetyCheckInStatus.needsHelp) {
        router.go(Routes.sos);
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        icon: const Icon(Icons.health_and_safety_outlined, size: 42),
        title: const Text('Safety check-in'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Are you safe? Please respond within 15 minutes. If you do not respond, your emergency contacts may be alerted with your last available location.',
              textAlign: TextAlign.center,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed:
                _saving ? null : () => _respond(SafetyCheckInStatus.needsHelp),
            icon: const Icon(Icons.sos),
            label: const Text('Need help'),
          ),
          FilledButton.icon(
            onPressed:
                _saving ? null : () => _respond(SafetyCheckInStatus.safe),
            icon: _saving
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            label: const Text("I'm safe"),
          ),
        ],
      );
}
