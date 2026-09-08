import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(children: [
          Icon(icon, size: 42, color: const Color(0xFF9B8DB8)),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Color(0xFF786B91))),
        ]),
      );
}
