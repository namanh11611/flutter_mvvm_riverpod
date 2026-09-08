import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GroupExpenseAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const GroupExpenseAppBar({
    super.key,
    required this.title,
    this.actions,
    this.fallbackRoute,
  });

  final String title;
  final List<Widget>? actions;
  final String? fallbackRoute;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
        backgroundColor: const Color(0xFF281958),
        foregroundColor: Colors.white,
        leading: fallbackRoute != null
            ? IconButton(
                tooltip: 'Back',
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(fallbackRoute!);
                  }
                },
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        title: Text(title),
        actions: actions,
      );
}
