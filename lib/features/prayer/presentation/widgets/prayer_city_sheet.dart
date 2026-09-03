import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/network/dio_client.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/city_geocoder.dart';
import '../../data/prayer_cities.dart';
import '../providers/prayer_providers.dart';

Future<void> showPrayerCitySheet({
  required BuildContext context,
  required WidgetRef ref,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => const _PrayerCitySheet(),
  );
}

class _PrayerCitySheet extends ConsumerStatefulWidget {
  const _PrayerCitySheet();

  @override
  ConsumerState<_PrayerCitySheet> createState() => _PrayerCitySheetState();
}

class _PrayerCitySheetState extends ConsumerState<_PrayerCitySheet> {
  final _query = TextEditingController();
  Timer? _debounce;
  CancelToken? _cancel;
  var _searching = false;
  var _searchError = false;
  List<CitySearchHit> _remote = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _cancel?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _useGps() async {
    await ref.read(settingsProvider.notifier).setUseGpsLocation();
    ref.invalidate(userPositionProvider);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _selectBundled(PrayerCity city) async {
    await ref
        .read(settingsProvider.notifier)
        .setManualLocation(
          label: city.label,
          latitude: city.latitude,
          longitude: city.longitude,
          cityId: city.id,
          country: city.country,
        );
    ref.invalidate(userPositionProvider);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _selectHit(CitySearchHit hit) async {
    await ref
        .read(settingsProvider.notifier)
        .setManualLocation(
          label: hit.label,
          latitude: hit.latitude,
          longitude: hit.longitude,
          country: hit.country,
        );
    ref.invalidate(userPositionProvider);
    if (mounted) Navigator.of(context).pop();
  }

  void _onQueryChanged(String _) {
    setState(() {});
    _debounce?.cancel();
    _cancel?.cancel();
    final q = _query.text.trim();
    if (q.length < 2) {
      setState(() {
        _remote = const [];
        _searching = false;
        _searchError = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), _runSearch);
  }

  Future<void> _runSearch() async {
    final q = _query.text.trim();
    if (q.length < 2 || !mounted) return;
    final token = CancelToken();
    _cancel = token;
    setState(() {
      _searching = true;
      _searchError = false;
    });
    try {
      final hits = await CityGeocoder(
        ref.read(dioProvider),
        localeCode: ref.read(settingsProvider).localeCode,
      ).search(q, cancelToken: token);
      if (!mounted || token.isCancelled) return;
      setState(() {
        _remote = hits;
        _searching = false;
      });
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel || !mounted) return;
      setState(() {
        _searching = false;
        _searchError = true;
        _remote = const [];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _searchError = true;
        _remote = const [];
      });
    }
  }

  bool _isSelected({String id = '', String label = ''}) {
    final settings = ref.read(settingsProvider);
    if (settings.useGpsLocation) return false;
    if (id.isNotEmpty && settings.locationCityId == id) return true;
    if (label.isNotEmpty && settings.locationLabel == label) return true;
    return false;
  }

  List<CitySearchHit> _remoteWithoutBundled(List<PrayerCity> bundled) {
    return [
      for (final hit in _remote)
        if (!_nearBundled(hit, bundled)) hit,
    ];
  }

  bool _nearBundled(CitySearchHit hit, List<PrayerCity> bundled) {
    for (final city in bundled) {
      final dLat = (city.latitude - hit.latitude).abs();
      final dLng = (city.longitude - hit.longitude).abs();
      if (dLat < 0.08 && dLng < 0.08) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final q = _query.text.trim();
    final bundled = PrayerCities.search(q);
    final remote = _remoteWithoutBundled(bundled);
    final emptySearch =
        q.length >= 2 && !_searching && bundled.isEmpty && remote.isEmpty;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.prayerLocation,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.prayerLocationHint,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _query,
                onChanged: _onQueryChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: t.searchCity,
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Material(
                color: settings.useGpsLocation
                    ? scheme.primaryContainer.withValues(alpha: 0.55)
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _useGps,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.my_location_rounded, color: scheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            t.useCurrentLocation,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (settings.useGpsLocation)
                          Icon(
                            Icons.check_circle_rounded,
                            color: scheme.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_searching)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  t.searchingCities,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: scheme.primary),
                ),
              ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                children: [
                  for (final city in bundled)
                    _CityTile(
                      title: city.name,
                      subtitle: city.country,
                      selected: _isSelected(id: city.id, label: city.label),
                      onTap: () => _selectBundled(city),
                    ),
                  for (final hit in remote)
                    _CityTile(
                      title: hit.name,
                      subtitle: hit.subtitle,
                      selected: _isSelected(label: hit.label),
                      onTap: () => _selectHit(hit),
                    ),
                  if (emptySearch)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                      child: Text(
                        _searchError ? t.noCitiesFound : t.noCitiesFound,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CityTile extends StatelessWidget {
  const _CityTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected
            ? scheme.primaryContainer.withValues(alpha: 0.55)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded, color: scheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
