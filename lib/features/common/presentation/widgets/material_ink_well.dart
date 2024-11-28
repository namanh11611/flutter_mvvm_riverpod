import 'package:flutter/material.dart';

class MaterialInkWell extends StatelessWidget {
  final Function()? onTap;
  final Widget child;
  final double radius;

  const MaterialInkWell({
    super.key,
    required this.onTap,
    required this.child,
    this.radius = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        onTap: onTap,
        child: child,
      ),
    );
  }
}
