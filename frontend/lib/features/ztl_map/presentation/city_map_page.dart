import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../city/data/city_models.dart';
import '../../city/data/city_repository.dart';
import '../../city/presentation/city_selector.dart';
import '../../ztl/data/ztl_repository.dart';
import '../../ztl/presentation/zone_detail_page.dart';
import '../data/map_bundle_api.dart';
import '../data/map_bundle_models.dart';
import 'widgets/gate_bottom_sheet.dart';
import 'widgets/map_legend.dart';
import 'widgets/map_status_filter.dart';
import 'widgets/missing_geometry_panel.dart';
import 'widgets/zone_bottom_sheet.dart';
import 'widgets/ztl_map.dart';

class CityMapPage extends StatefulWidget {
  const CityMapPage({
    super.key,
    required this.cityRepository,
    required this.ztlRepository,
    required this.mapRepository,
    required this.debugBaseUrl,
    required this.isDebugFallback,
  });

  final CityRepository cityRepository;
  final ZtlRepository ztlRepository;
  final ZtlMapRepository mapRepository;
  final String debugBaseUrl;
  final bool isDebugFallback;

  @override
  State<CityMapPage> createState() => _CityMapPageState();
}

class _CityMapPageState extends State<CityMapPage> {
  static const _cityPreferenceKey = 'selected_city_id';

  late Future<List<CityModel>> _citiesFuture;
  Future<CityMapBundle>? _mapFuture;
  String _selectedCityId = 'rome';
  bool _showActive = true;
  bool _showInactive = true;
  bool _showMissing = true;

  @override
  void initState() {
    super.initState();
    _citiesFuture = widget.cityRepository.loadCities();
    _restoreSelectedCity();
  }

  Future<void> _restoreSelectedCity() async {
    final preferences = await SharedPreferences.getInstance();
    final cityId = preferences.getString(_cityPreferenceKey) ?? 'rome';
    setState(() {
      _selectedCityId = cityId;
      _mapFuture = widget.mapRepository.loadCityMap(cityId);
    });
  }

  Future<void> _selectCity(CityModel city) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_cityPreferenceKey, city.id);
    setState(() {
      _selectedCityId = city.id;
      _mapFuture = widget.mapRepository.loadCityMap(city.id);
    });
  }

  Future<void> _reload() async {
    setState(() {
      _citiesFuture = widget.cityRepository.loadCities();
      _mapFuture = widget.mapRepository.loadCityMap(_selectedCityId);
    });
    await _citiesFuture;
    if (_mapFuture != null) {
      await _mapFuture;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ZTL Italy')),
      body: FutureBuilder<List<CityModel>>(
        future: _citiesFuture,
        builder: (context, citySnapshot) {
          if (citySnapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState(message: 'Loading supported cities...');
          }

          if (citySnapshot.hasError) {
            return ErrorState(
              title: 'Couldn’t load supported cities',
              message: 'Check your connection or API setup and try again.',
              actionLabel: 'Retry',
              onAction: () {
                _reload();
              },
              debugDetails: citySnapshot.error.toString(),
            );
          }

          final cities = citySnapshot.data ?? const <CityModel>[];
          if (_mapFuture == null) {
            return const LoadingState(message: 'Loading city map...');
          }

          return FutureBuilder<CityMapBundle>(
            future: _mapFuture,
            builder: (context, mapSnapshot) {
              if (mapSnapshot.connectionState == ConnectionState.waiting) {
                return const LoadingState(message: 'Loading ZTL map...');
              }

              if (mapSnapshot.hasError) {
                final debugDetails = mapSnapshot.error is AppError
                    ? (mapSnapshot.error as AppError).debugDetails
                    : mapSnapshot.error.toString();
                return ErrorState(
                  title: 'Couldn’t load the city map',
                  message: 'Check your connection or API setup and try again.',
                  actionLabel: 'Retry',
                  onAction: () {
                    _reload();
                  },
                  debugDetails:
                      '$debugDetails\nAPI: ${widget.debugBaseUrl}\nSelected city: $_selectedCityId',
                );
              }

              final bundle = mapSnapshot.data!;
              final filteredZones = bundle.zones.where((zone) {
                if (zone.currentStatus.isActive) {
                  return _showActive;
                }
                return _showInactive;
              }).toList();

              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    CitySelector(
                      cities: cities,
                      selectedCityId: _selectedCityId,
                      onSelected: _selectCity,
                    ),
                    const SizedBox(height: 12),
                    MapStatusFilter(
                      showActive: _showActive,
                      showInactive: _showInactive,
                      showMissing: _showMissing,
                      onShowActiveChanged: (value) => setState(() => _showActive = value),
                      onShowInactiveChanged: (value) =>
                          setState(() => _showInactive = value),
                      onShowMissingChanged: (value) => setState(() => _showMissing = value),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 420,
                      child: ZtlMap(
                        bundle: bundle,
                        visibleZones: filteredZones,
                        onZoneTap: (zone) {
                          showModalBottomSheet<void>(
                            context: context,
                            showDragHandle: true,
                            builder: (_) => ZoneBottomSheet(
                              zone: zone,
                              onOpenDetails: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ZoneDetailPage(
                                      repository: widget.ztlRepository,
                                      initialZone: zone,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        onGateTap: (gate) {
                          showModalBottomSheet<void>(
                            context: context,
                            showDragHandle: true,
                            builder: (_) => GateBottomSheet(
                              gate: gate,
                              zone: bundle.zones.firstWhere(
                                (zone) => zone.zoneId == gate.zoneId,
                              ),
                              onOpenZoneDetails: () {
                                Navigator.of(context).pop();
                                final zone = bundle.zones.firstWhere(
                                  (item) => item.zoneId == gate.zoneId,
                                );
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ZoneDetailPage(
                                      repository: widget.ztlRepository,
                                      initialZone: zone,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    const MapLegend(),
                    const SizedBox(height: 12),
                    if (_showMissing)
                      MissingGeometryPanel(
                        city: bundle.city,
                        zones: bundle.missingGeometryZones,
                      ),
                    const SizedBox(height: 12),
                    Text(
                      'Zones',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    for (final zone in filteredZones)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(zone.name),
                        subtitle: Text(zone.currentStatus.reason),
                        trailing: Text(zone.currentStatus.isActive ? 'Active' : 'Inactive'),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ZoneDetailPage(
                                repository: widget.ztlRepository,
                                initialZone: zone,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
