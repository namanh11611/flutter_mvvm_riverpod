import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/extensions/build_context_extension.dart';
import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../model/travel_footprint.dart';
import '../model/country_catalog.dart';
import '../repository/travel_footprint_repository.dart';
import '../../matchmaking/repository/location_search_service.dart';

class TravelFootprintScreen extends ConsumerStatefulWidget {
  const TravelFootprintScreen({super.key});

  @override
  ConsumerState<TravelFootprintScreen> createState() =>
      _TravelFootprintScreenState();
}

class _TravelFootprintScreenState extends ConsumerState<TravelFootprintScreen> {
  final _reportKey = GlobalKey();
  bool _sharing = false;

  Future<void> _reload() => ref.refresh(travelFootprintProvider.future);

  @override
  Widget build(BuildContext context) {
    final footprint = ref.watch(travelFootprintProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Travel Footprint')),
      body: footprint.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(error: error, retry: _reload),
        data: (data) => RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              RepaintBoundary(
                key: _reportKey,
                child: _TravelReportCard(
                  footprint: data,
                  sharing: _sharing,
                  onShare: _shareReport,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => _addCountry(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add visited country'),
              ),
              const SizedBox(height: 20),
              Text('Countries visited', style: AppTheme.title18),
              const SizedBox(height: 10),
              if (data.countries.isEmpty)
                const _EmptyCard(
                  text:
                      'Add your first country to start your travel footprint.',
                )
              else
                _CountryList(countries: data.countries),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addCountry(BuildContext context) async {
    final current = ref.read(travelFootprintProvider).value;
    if (current == null) return;
    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (_) => _CountryPickerDialog(
        initialCodes: current.countries.map((item) => item.code).toSet(),
      ),
    );
    if (selected == null) return;
    try {
      final repository = ref.read(travelFootprintRepositoryProvider);
      final existing = {for (final item in current.countries) item.code: item};
      for (final code in existing.keys.where(
        (code) => !selected.contains(code),
      )) {
        await repository.removeCountry(existing[code]!.id);
      }
      for (final option in countryCatalog.where(
        (item) =>
            selected.contains(item.code) && !existing.containsKey(item.code),
      )) {
        await repository.addCountry(option.name, option.code);
      }
      await _reload();
    } catch (error) {
      if (context.mounted) context.showErrorSnackBar(_friendly(error));
    }
  }

  Future<void> _shareReport() async {
    setState(() => _sharing = true);
    await WidgetsBinding.instance.endOfFrame;
    try {
      final boundary =
          _reportKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/gobuddy-travel-footprint.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'My GoBuddy travel footprint');
    } catch (error) {
      if (mounted) {
        context.showErrorSnackBar('Unable to create the travel report image.');
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}

class CountryFootprintScreen extends ConsumerWidget {
  const CountryFootprintScreen({super.key, required this.countryId});
  final String countryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(travelFootprintProvider);
    return async.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: _ErrorView(
          error: error,
          retry: () => ref.refresh(travelFootprintProvider.future),
        ),
      ),
      data: (footprint) {
        final country = footprint.countries
            .where((item) => item.id == countryId)
            .firstOrNull;
        if (country == null) {
          return const Scaffold(
            body: Center(child: Text('Country not found.')),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text('${_flag(country.code)}  ${country.name}'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${country.cities.length} ${country.cities.length == 1 ? 'city' : 'cities'} visited',
                style: AppTheme.body16.copyWith(
                  color: AppColors.brandTextMuted,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => _addCity(context, ref, country),
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Add visited city'),
              ),
              const SizedBox(height: 16),
              if (country.cities.isEmpty)
                const _EmptyCard(text: 'No visited cities added yet.')
              else
                Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < country.cities.length; i++) ...[
                        _CityTile(
                          city: country.cities[i],
                          onRename: () =>
                              _renameCity(context, ref, country.cities[i]),
                          onDelete: () =>
                              _deleteCity(context, ref, country.cities[i]),
                        ),
                        if (i < country.cities.length - 1)
                          const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 28),
              TextButton.icon(
                onPressed: () => _removeCountry(context, ref, country),
                icon: const Icon(Icons.delete_outline),
                label: Text('Remove ${country.name} from visited'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.rambutan100,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addCity(
    BuildContext context,
    WidgetRef ref,
    VisitedCountry country,
  ) async {
    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (_) => _CityPickerDialog(country: country),
    );
    if (selected == null) return;
    final repository = ref.read(travelFootprintRepositoryProvider);
    final existing = {for (final city in country.cities) city.name: city};
    for (final name in existing.keys.where(
      (name) => !selected.contains(name),
    )) {
      await repository.removeCity(existing[name]!.id);
    }
    for (final name in selected.where((name) => !existing.containsKey(name))) {
      await repository.addCity(country.id, name);
    }
    ref.invalidate(travelFootprintProvider);
  }

  Future<void> _renameCity(
    BuildContext context,
    WidgetRef ref,
    VisitedCity city,
  ) async {
    final name = await _textDialog(
      context,
      title: 'Rename city',
      label: 'City name',
      initial: city.name,
    );
    if (name == null) return;
    await ref.read(travelFootprintRepositoryProvider).renameCity(city.id, name);
    ref.invalidate(travelFootprintProvider);
  }

  Future<void> _deleteCity(
    BuildContext context,
    WidgetRef ref,
    VisitedCity city,
  ) async {
    if (!await _confirm(context, 'Remove ${city.name}?')) return;
    await ref.read(travelFootprintRepositoryProvider).removeCity(city.id);
    ref.invalidate(travelFootprintProvider);
  }

  Future<void> _removeCountry(
    BuildContext context,
    WidgetRef ref,
    VisitedCountry country,
  ) async {
    if (!await _confirm(
      context,
      'Remove ${country.name} and all its cities?',
    )) {
      return;
    }
    await ref.read(travelFootprintRepositoryProvider).removeCountry(country.id);
    ref.invalidate(travelFootprintProvider);
    if (context.mounted) context.pop();
  }
}

class _TravelReportCard extends StatelessWidget {
  const _TravelReportCard({
    required this.footprint,
    required this.sharing,
    required this.onShare,
  });
  final TravelFootprint footprint;
  final bool sharing;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: context.secondaryWidgetColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: context.dividerColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'MY TRAVEL FOOTPRINT',
              style: AppTheme.title12.copyWith(
                color: AppColors.brandTextMuted,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            if (!sharing)
              OutlinedButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share_outlined, size: 18),
                label: const Text('Share'),
              ),
          ],
        ),
        Text(
          '${footprint.worldPercent.toStringAsFixed(footprint.worldPercent < 1 ? 1 : 0)}%',
          style: AppTheme.title32.copyWith(
            fontSize: 54,
            color: AppColors.brandPrimary,
          ),
        ),
        Text(
          '${footprint.countryCount} of 195 countries visited',
          style: AppTheme.body14.copyWith(color: AppColors.brandTextMuted),
        ),
        const SizedBox(height: 16),
        Container(
          height: 130,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.expenseSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.public_rounded,
                size: 92,
                color: AppColors.brandBorder,
              ),
              Wrap(
                spacing: 4,
                children: footprint.countries
                    .take(8)
                    .map(
                      (item) => Text(
                        _flag(item.code),
                        style: const TextStyle(fontSize: 24),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _Metric(
                icon: Icons.map_outlined,
                value: '${footprint.countryCount}',
                label: 'Countries',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Metric(
                icon: Icons.location_city_outlined,
                value: '${footprint.cityCount}',
                label: 'Cities',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Metric(
                icon: Icons.public,
                value: '${footprint.worldPercent.toStringAsFixed(0)}%',
                label: 'World',
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      border: Border.all(color: context.dividerColor),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        Icon(icon, color: AppColors.brandSurface, size: 20),
        Text(value, style: AppTheme.title20),
        Text(
          label,
          style: AppTheme.body12.copyWith(color: AppColors.brandTextMuted),
        ),
      ],
    ),
  );
}

class _CountryList extends StatelessWidget {
  const _CountryList({required this.countries});
  final List<VisitedCountry> countries;
  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: [
        for (var i = 0; i < countries.length; i++) ...[
          ListTile(
            leading: Text(
              _flag(countries[i].code),
              style: const TextStyle(fontSize: 27),
            ),
            title: Text(countries[i].name, style: AppTheme.title16),
            subtitle: Text('${countries[i].cities.length} cities'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(Routes.travelCountry(countries[i].id)),
          ),
          if (i < countries.length - 1) const Divider(height: 1),
        ],
      ],
    ),
  );
}

class _CityTile extends StatelessWidget {
  const _CityTile({
    required this.city,
    required this.onRename,
    required this.onDelete,
  });
  final VisitedCity city;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(
      Icons.location_on_outlined,
      color: AppColors.brandSurface,
    ),
    title: Text(city.name),
    trailing: PopupMenuButton<String>(
      onSelected: (v) => v == 'rename' ? onRename() : onDelete(),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'rename', child: Text('Rename')),
        PopupMenuItem(value: 'delete', child: Text('Remove')),
      ],
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Center(child: Text(text, textAlign: TextAlign.center)),
    ),
  );
}

class _CountryPickerDialog extends StatefulWidget {
  const _CountryPickerDialog({required this.initialCodes});
  final Set<String> initialCodes;

  @override
  State<_CountryPickerDialog> createState() => _CountryPickerDialogState();
}

class _CountryPickerDialogState extends State<_CountryPickerDialog> {
  late final Set<String> _selected = {...widget.initialCodes};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = countryCatalog
        .where(
          (item) =>
              item.name.toLowerCase().startsWith(_query.trim().toLowerCase()),
        )
        .toList(growable: false);
    return Dialog.fullscreen(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text('Add visited countries', style: AppTheme.title20),
                        const SizedBox(height: 4),
                        Text(
                          'Tap a country to add it. Tap again to remove.',
                          textAlign: TextAlign.center,
                          style: AppTheme.body14.copyWith(
                            color: AppColors.brandTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                autofocus: false,
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Search countries...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final selected = _selected.contains(item.code);
                  return ListTile(
                    minTileHeight: 68,
                    leading: Text(
                      _flag(item.code),
                      style: const TextStyle(fontSize: 30),
                    ),
                    title: Text(item.name, style: AppTheme.title16),
                    trailing: CircleAvatar(
                      backgroundColor: selected
                          ? AppColors.brandSurface.withValues(alpha: .14)
                          : AppColors.expenseSurface,
                      child: Icon(
                        selected ? Icons.check : Icons.add,
                        color: AppColors.brandSurface,
                      ),
                    ),
                    onTap: () => setState(() {
                      selected
                          ? _selected.remove(item.code)
                          : _selected.add(item.code);
                    }),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => context.pop(_selected),
                  child: Text('Done · ${_selected.length} added'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CityPickerDialog extends StatefulWidget {
  const _CityPickerDialog({required this.country});
  final VisitedCountry country;

  @override
  State<_CityPickerDialog> createState() => _CityPickerDialogState();
}

class _CityPickerDialogState extends State<_CityPickerDialog> {
  final _search = LocationSearchService();
  late final Set<String> _selected = {
    for (final city in widget.country.cities) city.name,
  };
  late List<String> _results = _selected.toList()..sort();
  Timer? _debounce;
  bool _loading = false;
  String? _searchMessage;
  int _revision = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _query(String value) {
    _debounce?.cancel();
    final revision = ++_revision;
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _results = _selected.toList()..sort();
        _searchMessage = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _results = _results
          .where((name) => name.toLowerCase().startsWith(query.toLowerCase()))
          .toList();
      _loading = true;
      _searchMessage = null;
    });
    _debounce = Timer(const Duration(milliseconds: 150), () async {
      try {
        final found = await _search.searchCities(
          query,
          widget.country.code,
          countryName: widget.country.name,
        );
        if (mounted && revision == _revision) {
          setState(() {
            _results = found;
            _searchMessage = found.isEmpty
                ? 'No matching cities found in ${widget.country.name}.'
                : null;
          });
        }
      } catch (_) {
        if (mounted && revision == _revision) {
          setState(() {
            _results = const [];
            _searchMessage =
                'City search is unavailable. Check your connection and try again.';
          });
        }
      } finally {
        if (mounted && revision == _revision) setState(() => _loading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    child: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('Add visited cities', style: AppTheme.title20),
                      const SizedBox(height: 4),
                      Text(
                        'Search cities in ${widget.country.name}. Tap to add or remove.',
                        textAlign: TextAlign.center,
                        style: AppTheme.body14.copyWith(
                          color: AppColors.brandTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              autofocus: true,
              onChanged: _query,
              decoration: InputDecoration(
                hintText: 'Search cities...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      _searchMessage ??
                          (_loading
                              ? 'Searching cities...'
                              : 'Type to search cities.'),
                      style: AppTheme.body14.copyWith(
                        color: AppColors.brandTextMuted,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final name = _results[index];
                      final selected = _selected.contains(name);
                      return ListTile(
                        minTileHeight: 68,
                        leading: const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.brandSurface,
                        ),
                        title: Text(name, style: AppTheme.title16),
                        trailing: CircleAvatar(
                          backgroundColor: selected
                              ? AppColors.brandSurface.withValues(alpha: .14)
                              : AppColors.expenseSurface,
                          child: Icon(
                            selected ? Icons.check : Icons.add,
                            color: AppColors.brandSurface,
                          ),
                        ),
                        onTap: () => setState(() {
                          selected
                              ? _selected.remove(name)
                              : _selected.add(name);
                        }),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () => context.pop(_selected),
                child: Text('Done · ${_selected.length} added'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.retry});
  final Object error;
  final Future<void> Function() retry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_friendly(error), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: retry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

Future<String?> _textDialog(
  BuildContext context, {
  required String title,
  required String label,
  String? initial,
}) {
  final c = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: c,
        autofocus: true,
        decoration: InputDecoration(labelText: label),
      ),
      actions: [
        TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () =>
              c.text.trim().isEmpty ? null : context.pop(c.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

Future<bool> _confirm(BuildContext context, String title) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text(
          'This change will be saved to your travel footprint.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    ) ??
    false;
String _flag(String code) => code
    .toUpperCase()
    .codeUnits
    .map((c) => String.fromCharCode(c + 127397))
    .join();
String _friendly(Object error) =>
    'Unable to update your travel footprint. Check the details and try again.';
