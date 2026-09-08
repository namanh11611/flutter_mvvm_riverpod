part of 'matchmaking_shell_screen.dart';

class InteractiveFilterPage extends StatefulWidget {
  final VoidCallback onBack, onReset;
  final ValueChanged<MatchmakingFilters> onApply;
  final MatchmakingFilters initialFilters;
  final UserCurrency currency;
  final double currencyRate;
  const InteractiveFilterPage({
    super.key,
    required this.initialFilters,
    required this.currency,
    this.currencyRate = 1,
    required this.onBack,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<InteractiveFilterPage> createState() => _InteractiveFilterPageState();
}

class _InteractiveFilterPageState extends State<InteractiveFilterPage> {
  final _destination = TextEditingController();
  final _start = TextEditingController();
  final _end = TextEditingController();
  RangeValues _budget = const RangeValues(500, 2500);
  RangeValues _ages = const RangeValues(22, 35);
  String _gender = 'Any';
  final _styles = <String>{};
  late double _appliedCurrencyRate;
  static const _styleOptions = [
    'Adventure',
    'Foodie',
    'Luxury',
    'Backpacker',
    'Nature',
    'Culture',
  ];

  @override
  void initState() {
    super.initState();
    final filters = widget.initialFilters;
    _appliedCurrencyRate = widget.currencyRate;
    _destination.text = filters.destination;
    _start.text = filters.startDate == null
        ? ''
        : _dateInput(filters.startDate!);
    _end.text = filters.endDate == null ? '' : _dateInput(filters.endDate!);
    _budget = RangeValues(
      filters.minBudget * widget.currencyRate,
      filters.maxBudget * widget.currencyRate,
    );
    _ages = RangeValues(filters.minAge.toDouble(), filters.maxAge.toDouble());
    _gender = filters.gender;
    _styles.addAll(filters.styles);
  }

  @override
  void didUpdateWidget(covariant InteractiveFilterPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currencyRate != _appliedCurrencyRate) {
      _appliedCurrencyRate = widget.currencyRate;
      _budget = RangeValues(
        widget.initialFilters.minBudget * widget.currencyRate,
        widget.initialFilters.maxBudget * widget.currencyRate,
      );
    }
  }

  @override
  void dispose() {
    _destination.dispose();
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String hint, {IconData? icon}) => InputDecoration(
    hintText: hint,
    suffixIcon: icon == null ? null : Icon(icon, size: 19, color: _muted),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _border),
    ),
  );

  Future<void> _pickDate(TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) {
      controller.text =
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  Widget _dateField(TextEditingController controller, String hint) => TextField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: const [_DateInputFormatter()],
    decoration: _decoration(hint, icon: Icons.calendar_today_outlined),
    onTap: () => _pickDate(controller),
  );

  void _reset() {
    setState(() {
      _destination.clear();
      _start.clear();
      _end.clear();
      _budget = RangeValues(0, 10000 * widget.currencyRate);
      _ages = const RangeValues(18, 80);
      _gender = 'Any';
      _styles.clear();
    });
    widget.onReset();
  }

  DateTime? _parseOptionalDate(String value) {
    if (value.isEmpty) return null;
    final parts = value.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    final date = DateTime(year, month, day);
    return date.day == day && date.month == month && date.year == year
        ? date
        : null;
  }

  void _apply() {
    final start = _parseOptionalDate(_start.text);
    final end = _parseOptionalDate(_end.text);
    if ((_start.text.isNotEmpty && start == null) ||
        (_end.text.isNotEmpty && end == null) ||
        (start != null && end != null && end.isBefore(start))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid date range.')),
      );
      return;
    }
    widget.onApply(
      MatchmakingFilters(
        destination: _destination.text.trim(),
        startDate: start,
        endDate: end,
        minBudget: (_budget.start / widget.currencyRate).round(),
        maxBudget: (_budget.end / widget.currencyRate).round(),
        minAge: _ages.start.round(),
        maxAge: _ages.end.round(),
        gender: _gender,
        styles: {..._styles},
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FormPage(
    title: 'Search & filter',
    onBack: widget.onBack,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('DESTINATION'),
        TextField(
          controller: _destination,
          decoration: _decoration('Where would you like to go?'),
        ),
        const SizedBox(height: 22),
        const FieldLabel('DATE RANGE'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _dateField(_start, 'Start date')),
            const SizedBox(width: 12),
            Expanded(child: _dateField(_end, 'End date')),
          ],
        ),
        const SizedBox(height: 22),
        FieldLabel('BUDGET (${widget.currency.code})'),
        RangeTitle(
          left: widget.currency.format(_budget.start.round()),
          right: widget.currency.format(_budget.end.round()),
        ),
        RangeSlider(
          values: _budget,
          min: 0,
          max: 10000 * widget.currencyRate,
          divisions: 100,
          labels: RangeLabels(
            widget.currency.format(_budget.start.round()),
            widget.currency.format(_budget.end.round()),
          ),
          onChanged: (value) => setState(() => _budget = value),
        ),
        const SizedBox(height: 16),
        const FieldLabel('AGE RANGE'),
        RangeTitle(
          left: _ages.start.round().toString(),
          right: _ages.end.round().toString(),
        ),
        RangeSlider(
          values: _ages,
          min: 18,
          max: 80,
          divisions: 62,
          labels: RangeLabels(
            _ages.start.round().toString(),
            _ages.end.round().toString(),
          ),
          onChanged: (value) => setState(() => _ages = value),
        ),
        const SizedBox(height: 18),
        const FieldLabel('PREFERRED GENDER'),
        const SizedBox(height: 8),
        Row(
          children: ['Any', 'Female', 'Male']
              .map(
                (gender) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: gender == 'Male' ? 0 : 8),
                    child: ChipButton(
                      label: gender,
                      active: _gender == gender,
                      onTap: () => setState(() => _gender = gender),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 22),
        const FieldLabel('TRAVEL STYLE'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _styleOptions
              .map(
                (style) => ChipButton(
                  label: style,
                  active: _styles.contains(style),
                  onTap: () => setState(
                    () => _styles.contains(style)
                        ? _styles.remove(style)
                        : _styles.add(style),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 32),
        PrimaryButton(label: 'Apply Filters', onTap: _apply),
        const SizedBox(height: 10),
        OutlineButton(label: 'Reset', onTap: _reset),
      ],
    ),
  );
}
