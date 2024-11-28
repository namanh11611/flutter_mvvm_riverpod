import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_mvvm_riverpod/features/common/presentation/widgets/circle_outline_button.dart';

class CommonBackButton extends StatelessWidget {
  final Function()? onBack;
  final Color? color;

  const CommonBackButton({
    super.key,
    this.onBack,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CircleOutlineButton(
      icon: Icons.arrow_back_ios_new,
      color: color,
      onPressed: onBack ??
          () {
            context.pop();
          },
    );
  }
}
