part of 'matchmaking_shell_screen.dart';

class InteractiveTripFormPage extends StatefulWidget {
  final VoidCallback onBack;
  final ValueChanged<MatchmakingTrip> onPublish;
  final Future<String> Function(String, Uint8List, String) onUploadImage;
  final Future<String> Function(String, Uint8List, String, int)
  onUploadGalleryImage;
  final VoidCallback? onDelete;
  final MatchmakingTrip? initialTrip;
  final List<MatchmakingTrip> hostedTrips;
  final LocationSearchService? locationSearchService;
  final DestinationImageService? destinationImageService;
  final bool edit;
  final UserCurrency currency;
  final double currencyRate;
  const InteractiveTripFormPage({
    super.key,
    required this.onBack,
    required this.onPublish,
    required this.onUploadImage,
    required this.onUploadGalleryImage,
    this.onDelete,
    this.initialTrip,
    required this.hostedTrips,
    this.locationSearchService,
    this.destinationImageService,
    this.edit = false,
    this.currency = UserCurrency.myr,
    this.currencyRate = 1,
  });

  @override
  State<InteractiveTripFormPage> createState() =>
      _InteractiveTripFormPageState();
}

class _InteractiveTripFormPageState extends State<InteractiveTripFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _destination,
      _start,
      _end,
      _budget,
      _vacancies,
      _description;
  final _styles = <String>{};
  String _gender = 'Any';
  late TimeOfDay _startTime;
  RangeValues _ages = const RangeValues(22, 40);
  late String _imageUrl;
  Uint8List? _pendingImageBytes;
  String? _pendingImageName;
  final List<Uint8List> _pendingGalleryBytes = [];
  final List<String> _pendingGalleryNames = [];
  late final List<String> _galleryImageUrls;
  bool _isUploadingImage = false;
  String? _dateError;
  final _destinationFocus = FocusNode();
  final _destinationMenu = MenuController();
  late final LocationSearchService _locationSearch;
  late final DestinationImageService _destinationImageSearch;
  Timer? _locationDebounce;
  Timer? _coverDebounce;
  List<String> _locationSuggestions = const [];
  bool _isSearchingLocations = false;
  int _locationRequest = 0;
  int _coverRequest = 0;
  bool _isFindingCover = false;
  String? _coverMessage;
  String? _selectedDestination;
  bool _automaticCoverEnabled = true;
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
    final trip = widget.initialTrip;
    _appliedCurrencyRate = widget.currencyRate;
    _locationSearch = widget.locationSearchService ?? LocationSearchService();
    _destinationImageSearch =
        widget.destinationImageService ?? DestinationImageService();
    _imageUrl = trip?.imageUrl ?? '';
    _galleryImageUrls = [...?trip?.galleryImageUrls];
    // Preserve the current cover until the destination changes, then keep the
    // suggested cover in sync. A photo picked in this editing session still
    // takes priority and disables automatic updates.
    _automaticCoverEnabled = true;
    _destination = TextEditingController(text: trip?.destination ?? '');
    _selectedDestination = trip?.destination;
    _destinationFocus.addListener(_onDestinationFocusChanged);
    _start = TextEditingController(
      text: trip == null ? '' : _dateInput(trip.startDate),
    );
    _end = TextEditingController(
      text: trip == null ? '' : _dateInput(trip.endDate),
    );
    _budget = TextEditingController(
      text: trip == null
          ? ''
          : (trip.budget * widget.currencyRate).round().toString(),
    );
    _vacancies = TextEditingController(text: trip?.vacancies.toString() ?? '');
    _description = TextEditingController(text: trip?.description ?? '');
    _startTime = TimeOfDay.fromDateTime(
      trip?.startTime ?? DateTime(2000, 1, 1, 9),
    );
    if (trip != null) {
      _styles.addAll(trip.styles);
      _gender = trip.gender;
      _ages = RangeValues(trip.minAge.toDouble(), trip.maxAge.toDouble());
    }
  }

  @override
  void didUpdateWidget(covariant InteractiveTripFormPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.edit && widget.currencyRate != _appliedCurrencyRate) {
      _appliedCurrencyRate = widget.currencyRate;
      _budget.text = ((widget.initialTrip?.budget ?? 0) * widget.currencyRate)
          .round()
          .toString();
    }
  }

  @override
  void dispose() {
    _locationDebounce?.cancel();
    _coverDebounce?.cancel();
    _destinationFocus
      ..removeListener(_onDestinationFocusChanged)
      ..dispose();
    for (final item in [
      _destination,
      _start,
      _end,
      _budget,
      _vacancies,
      _description,
    ]) {
      item.dispose();
    }
    super.dispose();
  }

  void _onDestinationFocusChanged() {
    if (!mounted) return;
    setState(() {});
    if (_destinationFocus.hasFocus && _destination.text.trim().length >= 2) {
      _openDestinationMenu();
    } else if (_destinationMenu.isOpen) {
      _destinationMenu.close();
    }
  }

  void _openDestinationMenu() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _destinationFocus.hasFocus &&
          _destination.text.trim().length >= 2 &&
          !_destinationMenu.isOpen) {
        _destinationMenu.open();
      }
    });
  }

  void _searchLocations(String value) {
    _selectedDestination = null;
    if (_automaticCoverEnabled && _pendingImageBytes == null) {
      _coverDebounce?.cancel();
      _coverRequest++;
      _imageUrl = '';
      _isFindingCover = false;
      _coverMessage = value.trim().length < 2
          ? 'Select a destination suggestion to load a matching photo.'
          : 'Select a suggested destination to load its photo.';
    }
    _locationDebounce?.cancel();
    final request = ++_locationRequest;
    if (value.trim().length < 2) {
      if (_destinationMenu.isOpen) _destinationMenu.close();
      setState(() {
        _locationSuggestions = const [];
        _isSearchingLocations = false;
      });
      return;
    }
    setState(() => _isSearchingLocations = true);
    _openDestinationMenu();
    _locationDebounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final results = await _locationSearch.search(value);
        if (!mounted || request != _locationRequest) return;
        setState(() {
          _locationSuggestions = results;
          _isSearchingLocations = false;
          if (_automaticCoverEnabled && results.isEmpty) {
            _coverMessage =
                'No matching destination was found. Enter a real place or add your own photos.';
          }
        });
        _openDestinationMenu();
      } catch (_) {
        if (!mounted || request != _locationRequest) return;
        setState(() {
          _locationSuggestions = const [];
          _isSearchingLocations = false;
          if (_automaticCoverEnabled) {
            _coverMessage =
                'Location search is unavailable. You can add your own photos.';
          }
        });
      }
    });
  }

  void _selectLocation(String location) {
    _locationDebounce?.cancel();
    _locationRequest++;
    setState(() {
      _destination.text = location;
      _selectedDestination = location;
      _destination.selection = TextSelection.collapsed(offset: location.length);
      _locationSuggestions = const [];
      _isSearchingLocations = false;
    });
    _destinationFocus.unfocus();
    if (_destinationMenu.isOpen) _destinationMenu.close();
    _scheduleAutomaticCover(location, immediate: true);
  }

  void _scheduleAutomaticCover(String destination, {bool immediate = false}) {
    if (!_automaticCoverEnabled || _pendingImageBytes != null) return;
    _coverDebounce?.cancel();
    final request = ++_coverRequest;
    if (destination.trim().length < 3) {
      setState(() {
        _imageUrl = '';
        _isFindingCover = false;
      });
      return;
    }
    setState(() {
      _isFindingCover = true;
      _coverMessage = null;
    });
    if (immediate) {
      unawaited(_findAutomaticCover(destination, request));
    } else {
      _coverDebounce = Timer(
        const Duration(milliseconds: 900),
        () => unawaited(_findAutomaticCover(destination, request)),
      );
    }
  }

  Future<void> _findAutomaticCover(String destination, int request) async {
    try {
      final url = await _destinationImageSearch.findImageUrl(destination);
      if (!mounted || request != _coverRequest) return;
      setState(() {
        _imageUrl = url ?? '';
        _isFindingCover = false;
        _coverMessage = url == null
            ? 'No reliable destination photo was found. Please add your own photos.'
            : null;
      });
    } catch (_) {
      if (!mounted || request != _coverRequest) return;
      setState(() {
        _isFindingCover = false;
        _coverMessage =
            'No reliable destination photo was found. Please add your own photos.';
      });
    }
  }

  void _removeCover() {
    _coverDebounce?.cancel();
    _coverRequest++;
    setState(() {
      _imageUrl = '';
      _pendingImageBytes = null;
      _pendingImageName = null;
      _automaticCoverEnabled = false;
      _isFindingCover = false;
      _coverMessage = null;
    });
  }

  void _useDestinationCover() {
    if (_selectedDestination != _destination.text.trim()) {
      setState(() {
        _coverMessage = 'Choose a destination from the suggestions first.';
      });
      return;
    }
    setState(() {
      _automaticCoverEnabled = true;
      _pendingImageBytes = null;
      _pendingImageName = null;
    });
    _scheduleAutomaticCover(_destination.text, immediate: true);
  }

  Widget _destinationField() => MenuAnchor(
    controller: _destinationMenu,
    crossAxisUnconstrained: false,
    alignmentOffset: const Offset(0, 4),
    style: const MenuStyle(
      maximumSize: WidgetStatePropertyAll(Size(double.infinity, 300)),
    ),
    menuChildren: [
      if (_isSearchingLocations)
        const MenuItemButton(
          onPressed: null,
          leadingIcon: SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          child: Text('Searching for locations...'),
        ),
      for (final location in _locationSuggestions)
        MenuItemButton(
          leadingIcon: const Icon(Icons.place_outlined, color: _violet),
          onPressed: () => _selectLocation(location),
          child: Text(location),
        ),
      if (!_isSearchingLocations && _locationSuggestions.isEmpty)
        const MenuItemButton(
          onPressed: null,
          child: Text('No matching destinations found.'),
        ),
    ],
    builder: (context, controller, child) => TextFormField(
      controller: _destination,
      focusNode: _destinationFocus,
      textInputAction: TextInputAction.next,
      onChanged: _searchLocations,
      decoration: _decoration('Start typing a city or place').copyWith(
        prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
        suffixIcon: _isSearchingLocations
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
      validator: (value) => value == null || value.trim().isEmpty
          ? 'Required'
          : _selectedDestination != value.trim()
          ? 'Choose a destination from the suggestions'
          : null,
    ),
  );

  InputDecoration _decoration(String hint, {String? prefix, IconData? icon}) =>
      InputDecoration(
        hintText: hint,
        prefixText: prefix,
        suffixIcon: icon == null ? null : Icon(icon, size: 19),
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

  Widget _field(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    String? prefix,
    IconData? icon,
    int lines = 1,
    bool required = true,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboard,
    inputFormatters: formatters,
    maxLines: lines,
    readOnly: onTap != null,
    showCursor: onTap == null,
    enableInteractiveSelection: onTap == null,
    onTap: onTap,
    onChanged: onChanged,
    decoration: _decoration(hint, prefix: prefix, icon: icon),
    validator: required
        ? (value) => value == null || value.trim().isEmpty ? 'Required' : null
        : null,
  );

  Future<void> _pickDate(TextEditingController controller) async {
    final firstDate = DateUtils.dateOnly(DateTime.now());
    final lastDate = firstDate.add(const Duration(days: 3650));
    var initialDate = DateUtils.dateOnly(
      _parseDate(controller.text) ?? firstDate,
    );
    if (initialDate.isBefore(firstDate) || _isOccupiedDate(initialDate)) {
      final availableDate = _firstAvailableDate(firstDate, lastDate);
      if (availableDate == null) {
        setState(
          () => _dateError = 'No available dates were found in this period.',
        );
        return;
      }
      initialDate = availableDate;
    }
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: (date) => !_isOccupiedDate(date),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          datePickerTheme: DatePickerThemeData(
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return const Color(0xFFDC2626);
              }
              return null;
            }),
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      setState(() {
        controller.text =
            '${date.day.toString().padLeft(2, '0')}/'
            '${date.month.toString().padLeft(2, '0')}/${date.year}';
        _dateError = null;
      });
    }
  }

  bool _isOccupiedDate(DateTime value) {
    final date = DateUtils.dateOnly(value);
    return widget.hostedTrips.any(
      (trip) =>
          trip.id != widget.initialTrip?.id &&
          trip.status != TripStatus.closed &&
          !date.isBefore(DateUtils.dateOnly(trip.startDate)) &&
          !date.isAfter(DateUtils.dateOnly(trip.endDate)),
    );
  }

  DateTime? _firstAvailableDate(DateTime firstDate, DateTime lastDate) {
    var candidate = DateUtils.dateOnly(firstDate);
    final finalDate = DateUtils.dateOnly(lastDate);
    while (!candidate.isAfter(finalDate)) {
      if (!_isOccupiedDate(candidate)) return candidate;
      candidate = candidate.add(const Duration(days: 1));
    }
    return null;
  }

  Future<void> _pickStartTime() async {
    final value = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (value != null) setState(() => _startTime = value);
  }

  Future<void> _pickGalleryImages() async {
    final images = await ImagePicker().pickMultiImage(
      imageQuality: 85,
      maxWidth: 1800,
      limit: 8 - _galleryImageUrls.length - _pendingGalleryBytes.length,
    );
    if (images.isEmpty) return;
    final bytes = await Future.wait(images.map((image) => image.readAsBytes()));
    if (!mounted) return;
    setState(() {
      _pendingGalleryBytes.addAll(bytes);
      _pendingGalleryNames.addAll(images.map((image) => image.name));
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _styles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complete the required fields and select a travel style.',
          ),
        ),
      );
      return;
    }
    final start = _parseDate(_start.text);
    final end = _parseDate(_end.text);
    if (start == null || end == null || end.isBefore(start)) {
      setState(
        () => _dateError = 'End date cannot be earlier than start date.',
      );
      return;
    }
    final validationTrip = MatchmakingTrip(
      id: widget.initialTrip?.id ?? 'new-trip',
      destination: _destination.text.trim(),
      startDate: start,
      endDate: end,
      startTime: DateTime(
        start.year,
        start.month,
        start.day,
        _startTime.hour,
        _startTime.minute,
      ),
      budget: ((int.tryParse(_budget.text) ?? 0) / widget.currencyRate).round(),
      styles: {..._styles},
      hostId: widget.initialTrip?.hostId ?? 'current-user',
      hostName: widget.initialTrip?.hostName ?? '',
      hostInitials: widget.initialTrip?.hostInitials ?? '',
      hostProfilePhotoUrl: widget.initialTrip?.hostProfilePhotoUrl,
      imageUrl: _imageUrl,
      galleryImageUrls: [..._galleryImageUrls],
      gender: _gender,
      minAge: _ages.start.round(),
      maxAge: _ages.end.round(),
      vacancies: int.tryParse(_vacancies.text) ?? 0,
      description: _description.text.trim(),
      isOwned: true,
    );
    try {
      MatchmakingValidation.validateHostAvailability(
        validationTrip,
        widget.hostedTrips,
      );
    } on MatchmakingValidationException catch (error) {
      setState(() => _dateError = error.message);
      return;
    }
    final tripId = widget.initialTrip?.id ?? const Uuid().v4();
    var coverUrl = _imageUrl;
    if (_pendingImageBytes != null && _pendingImageName != null) {
      setState(() => _isUploadingImage = true);
      try {
        coverUrl = await widget.onUploadImage(
          tripId,
          _pendingImageBytes!,
          _pendingImageName!,
        );
      } catch (error) {
        if (!mounted) return;
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not upload trip photo: $error')),
        );
        return;
      }
    }
    final galleryUrls = [..._galleryImageUrls];
    if (_pendingGalleryBytes.isNotEmpty) {
      setState(() => _isUploadingImage = true);
      try {
        for (var index = 0; index < _pendingGalleryBytes.length; index++) {
          galleryUrls.add(
            await widget.onUploadGalleryImage(
              tripId,
              _pendingGalleryBytes[index],
              _pendingGalleryNames[index],
              index,
            ),
          );
        }
      } catch (error) {
        if (!mounted) return;
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not upload trip photos: $error')),
        );
        return;
      }
    }
    if (!mounted) return;
    setState(() => _isUploadingImage = false);
    widget.onPublish(
      MatchmakingTrip(
        id: tripId,
        destination: _destination.text.trim(),
        startDate: start,
        endDate: end,
        startTime: DateTime(
          start.year,
          start.month,
          start.day,
          _startTime.hour,
          _startTime.minute,
        ),
        budget: (int.parse(_budget.text) / widget.currencyRate).round(),
        styles: {..._styles},
        hostId: widget.initialTrip?.hostId ?? 'current-user',
        hostName: widget.initialTrip?.hostName ?? 'Morgan Lee',
        hostInitials: widget.initialTrip?.hostInitials ?? 'ML',
        hostProfilePhotoUrl: widget.initialTrip?.hostProfilePhotoUrl,
        imageUrl: coverUrl,
        galleryImageUrls: galleryUrls,
        gender: _gender,
        minAge: _ages.start.round(),
        maxAge: _ages.end.round(),
        vacancies: int.parse(_vacancies.text),
        description: _description.text.trim(),
        joined: widget.initialTrip?.joined ?? 0,
        verifiedHost: widget.initialTrip?.verifiedHost ?? true,
        status: widget.initialTrip?.status ?? TripStatus.active,
        isOwned: true,
      ),
    );
  }

  DateTime? _parseDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete trip?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onDelete?.call();
  }

  @override
  Widget build(BuildContext context) => FormPage(
    title: widget.edit ? 'Edit Trip' : 'Create Trip',
    onBack: widget.onBack,
    child: Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FieldLabel('COVER PHOTO'),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_pendingImageBytes != null)
                      Image.memory(_pendingImageBytes!, fit: BoxFit.cover)
                    else if (_imageUrl.isNotEmpty)
                      TravelImage(url: _imageUrl, radius: 12)
                    else
                      const ColoredBox(
                        color: _lavender,
                        child: Icon(
                          Icons.landscape_outlined,
                          size: 48,
                          color: _muted,
                        ),
                      ),
                    if (_isFindingCover)
                      const ColoredBox(
                        color: Color(0x66000000),
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed:
                      _isUploadingImage ||
                          _galleryImageUrls.length +
                                  _pendingGalleryBytes.length >=
                              8
                      ? null
                      : _pickGalleryImages,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Add your photos'),
                ),
                if (_imageUrl.isNotEmpty || _pendingImageBytes != null)
                  OutlinedButton.icon(
                    onPressed: _isUploadingImage ? null : _removeCover,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove photo'),
                  ),
                if (!_automaticCoverEnabled)
                  TextButton.icon(
                    onPressed: _isUploadingImage ? null : _useDestinationCover,
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('Use destination photo'),
                  ),
              ],
            ),
            if (_automaticCoverEnabled && _imageUrl.isNotEmpty) ...[
              const SizedBox(height: 4),
              const Text(
                'Suggested destination photo from Wikipedia/Wikimedia Commons',
                style: TextStyle(fontSize: 11, color: _muted),
              ),
            ],
            if (_automaticCoverEnabled &&
                _imageUrl.isEmpty &&
                _coverMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                _coverMessage!,
                style: const TextStyle(fontSize: 11, color: _muted),
              ),
            ],
            if (_galleryImageUrls.isNotEmpty ||
                _pendingGalleryBytes.isNotEmpty) ...[
              const SizedBox(height: 12),
              const FieldLabel('YOUR TRIP PHOTOS'),
              const SizedBox(height: 8),
              SizedBox(
                height: 92,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (
                      var index = 0;
                      index < _galleryImageUrls.length;
                      index++
                    )
                      _GalleryPhoto(
                        image: TravelImage(
                          url: _galleryImageUrls[index],
                          radius: 10,
                        ),
                        onRemove: () =>
                            setState(() => _galleryImageUrls.removeAt(index)),
                      ),
                    for (
                      var index = 0;
                      index < _pendingGalleryBytes.length;
                      index++
                    )
                      _GalleryPhoto(
                        image: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            _pendingGalleryBytes[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                        onRemove: () => setState(() {
                          _pendingGalleryBytes.removeAt(index);
                          _pendingGalleryNames.removeAt(index);
                        }),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            const FieldLabel('DESTINATION'),
            const SizedBox(height: 8),
            _destinationField(),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FieldLabel('START DATE'),
                      const SizedBox(height: 8),
                      _field(
                        _start,
                        'dd/mm/yyyy',
                        keyboard: TextInputType.number,
                        formatters: const [_DateInputFormatter()],
                        icon: Icons.calendar_today_outlined,
                        onTap: () => _pickDate(_start),
                        onChanged: (_) => setState(() => _dateError = null),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FieldLabel('END DATE'),
                      const SizedBox(height: 8),
                      _field(
                        _end,
                        'dd/mm/yyyy',
                        keyboard: TextInputType.number,
                        formatters: const [_DateInputFormatter()],
                        icon: Icons.calendar_today_outlined,
                        onTap: () => _pickDate(_end),
                        onChanged: (_) => setState(() => _dateError = null),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_dateError != null) ...[
              const SizedBox(height: 7),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 17,
                    color: Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _dateError!,
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            const FieldLabel('START TIME'),
            InkWell(
              onTap: _pickStartTime,
              child: InputDecorator(
                decoration: _decoration(
                  'Select start time',
                  icon: Icons.schedule_outlined,
                ),
                child: Text(_startTime.format(context)),
              ),
            ),
            const SizedBox(height: 18),
            FieldLabel('BUDGET (${widget.currency.code})'),
            _field(
              _budget,
              'e.g. 1800',
              prefix: '${widget.currency.symbol} ',
              keyboard: TextInputType.number,
              formatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 18),
            const FieldLabel('TRAVEL STYLE'),
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
            const SizedBox(height: 18),
            const FieldLabel('PREFERRED GENDER'),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: _decoration('Select gender'),
              items: ['Any', 'Female', 'Male']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _gender = value ?? 'Any'),
            ),
            const SizedBox(height: 18),
            const FieldLabel('AGE PREFERENCE'),
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
            const FieldLabel('AVAILABLE VACANCIES'),
            _field(
              _vacancies,
              'e.g. 2',
              keyboard: TextInputType.number,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              icon: Icons.people_outline,
            ),
            const SizedBox(height: 18),
            const FieldLabel('DESCRIPTION (OPTIONAL)'),
            _field(
              _description,
              'Describe your trip and ideal companion...',
              lines: 4,
              required: false,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: _isUploadingImage
                  ? 'Uploading photo...'
                  : widget.edit
                  ? 'Save Changes'
                  : 'Publish Trip',
              onTap: _isUploadingImage ? null : _submit,
            ),
            if (widget.edit) ...[
              const SizedBox(height: 10),
              OutlineButton(label: 'Delete Trip', onTap: _delete),
            ],
          ],
        ),
      ),
    ),
  );
}

class _DateInputFormatter extends TextInputFormatter {
  const _DateInputFormatter();
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final clipped = digits.substring(0, digits.length.clamp(0, 8));
    final buffer = StringBuffer();
    for (var i = 0; i < clipped.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(clipped[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
