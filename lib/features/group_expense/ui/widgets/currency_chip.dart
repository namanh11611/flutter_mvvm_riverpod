import 'package:flutter/material.dart';

class CurrencyChip extends StatelessWidget {
  const CurrencyChip({
    super.key,
    required this.currency,
    required this.selected,
    required this.onSelected,
  });
  final String currency;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) => ChoiceChip(
        label: Text(currency),
        selected: selected,
        onSelected: onSelected,
      );
}
