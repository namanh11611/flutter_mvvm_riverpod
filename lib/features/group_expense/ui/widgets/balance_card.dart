import 'package:flutter/material.dart';

import '../../model/traveller_balance.dart';
import 'status_chip.dart';
import 'traveller_avatar.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.balance,
    required this.formattedBalance,
  });
  final TravellerBalance balance;
  final String formattedBalance;

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE8E1F4)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: TravellerAvatar(initials: balance.initials),
            title: Text(
              balance.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Align(
              alignment: Alignment.centerLeft,
              child: StatusChip(
                label: _label,
                color: _color,
              ),
            ),
            trailing: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  formattedBalance,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: balance.owes
                        ? const Color(0xFFEF4444)
                        : balance.shouldReceive
                            ? const Color(0xFF10B981)
                            : const Color(0xFF786B91),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  String get _label => switch (balance.status) {
        TravellerBalanceStatus.needsPayment => 'Needs payment',
        TravellerBalanceStatus.pendingConfirmation => 'Pending confirmation',
        TravellerBalanceStatus.settled => 'Settled',
        TravellerBalanceStatus.owed => 'Should receive',
      };

  Color get _color => switch (balance.status) {
        TravellerBalanceStatus.needsPayment => const Color(0xFFEF4444),
        TravellerBalanceStatus.pendingConfirmation => const Color(0xFFF59E0B),
        TravellerBalanceStatus.settled => const Color(0xFF786B91),
        TravellerBalanceStatus.owed => const Color(0xFF10B981),
      };
}
