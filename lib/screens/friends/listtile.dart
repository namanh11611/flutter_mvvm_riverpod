import 'package:flutter/material.dart';

class BorderedListTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const BorderedListTile({
    super.key,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      
      decoration: BoxDecoration(
        
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black,
          width: 1, 
        ),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 16),
        ),
        trailing: const Icon(
          Icons.open_in_new_rounded,
          color: Color(0xFF3620B3),
          size: 22,
        ),
        onTap: onTap,
      ),
    );
  }
}
