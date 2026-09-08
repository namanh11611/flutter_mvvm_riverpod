import 'package:flutter/material.dart';

import '../../model/settlement.dart';
import 'status_chip.dart';

class SettlementCard extends StatelessWidget {
  const SettlementCard({
    super.key,
    required this.description,
    required this.amount,
    required this.paymentMethod,
    required this.date,
    required this.status,
    required this.hasReceipt,
    this.onReceipt,
    this.onRemoveReceipt,
    this.onDelete,
    this.onConfirm,
    this.onReject,
  });
  final String description;
  final String amount;
  final String paymentMethod;
  final String date;
  final SettlementStatus status;
  final bool hasReceipt;
  final VoidCallback? onReceipt;
  final VoidCallback? onRemoveReceipt;
  final VoidCallback? onDelete;
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE8E1F4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const CircleAvatar(child: Icon(Icons.swap_horiz)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(description,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                Flexible(
                  child: Text(
                    amount,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: Text('$paymentMethod • $date')),
                StatusChip(label: _statusLabel, color: _statusColor),
              ]),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                children: [
                  if (hasReceipt && onReceipt == null)
                    const Chip(
                      avatar: Icon(Icons.receipt_long, size: 18),
                      label: Text('Receipt attached'),
                    ),
                  if (onReceipt != null)
                    TextButton.icon(
                      onPressed: onReceipt,
                      icon: Icon(hasReceipt
                          ? Icons.receipt_long
                          : Icons.add_photo_alternate_outlined),
                      label:
                          Text(hasReceipt ? 'Replace receipt' : 'Add receipt'),
                    ),
                  if (hasReceipt && onRemoveReceipt != null)
                    TextButton(
                      onPressed: onRemoveReceipt,
                      child: const Text('Remove receipt'),
                    ),
                  if (onDelete != null)
                    TextButton(
                      onPressed: onDelete,
                      child: const Text('Delete'),
                    ),
                ],
              ),
              if (status == SettlementStatus.pending && onConfirm != null) ...[
                const Divider(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onConfirm,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Confirm Payment Received'),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onReject,
                    child: const Text('Reject Submission'),
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  String get _statusLabel => switch (status) {
        SettlementStatus.pending => 'Pending',
        SettlementStatus.completed => 'Completed',
        SettlementStatus.rejected => 'Rejected',
      };

  Color get _statusColor => switch (status) {
        SettlementStatus.pending => const Color(0xFFF59E0B),
        SettlementStatus.completed => const Color(0xFF10B981),
        SettlementStatus.rejected => const Color(0xFFEF4444),
      };
}
