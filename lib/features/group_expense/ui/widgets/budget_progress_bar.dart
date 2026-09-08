import 'package:flutter/material.dart';

class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({super.key, required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LinearProgressIndicator(
          minHeight: 10,
          value: progress.clamp(0, 1),
          backgroundColor: const Color(0xFFE9DDFE),
          color:
              progress > 1 ? const Color(0xFFEF4444) : const Color(0xFF7C3AED),
        ),
      );
}
