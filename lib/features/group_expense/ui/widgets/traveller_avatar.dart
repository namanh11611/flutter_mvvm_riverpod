import 'package:flutter/material.dart';

class TravellerAvatar extends StatelessWidget {
  const TravellerAvatar({
    super.key,
    required this.initials,
    this.imagePath,
    this.radius = 22,
  });
  final String initials;
  final String? imagePath;
  final double radius;

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFE9DDFE),
        foregroundImage: imagePath == null ? null : NetworkImage(imagePath!),
        child:
            Text(initials, style: const TextStyle(fontWeight: FontWeight.w700)),
      );
}
