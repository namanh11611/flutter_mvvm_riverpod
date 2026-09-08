import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Chip(
        label: Text(label),
        backgroundColor: color.withValues(alpha: 0.12),
        side: BorderSide.none,
        labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
      );
}
