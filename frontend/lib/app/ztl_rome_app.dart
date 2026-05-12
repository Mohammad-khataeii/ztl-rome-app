import 'package:flutter/material.dart';

import '../core/api/api_client.dart';
import '../core/widgets/error_state.dart';
import '../features/city/data/city_api.dart';
import '../features/city/data/city_repository.dart';
import '../features/ztl/data/ztl_api.dart';
import '../features/ztl/data/ztl_repository.dart';
import '../features/ztl_map/data/map_bundle_api.dart';
import '../features/ztl_map/presentation/city_map_page.dart';
import 'app_config.dart';
import 'app_theme.dart';

class ZtlItalyApp extends StatelessWidget {
  const ZtlItalyApp({
    super.key,
    required this.config,
    required this.configurationError,
  });

  final AppConfig? config;
  final String? configurationError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZTL Italy',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (configurationError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ZTL Italy')),
        body: ErrorState(
          title: 'App configuration needed',
          message: 'Set ZTL_API_BASE_URL before running this build.',
          actionLabel: null,
          onAction: null,
          debugDetails: configurationError,
        ),
      );
    }

    final client = ApiClient(baseUrl: config!.apiBaseUrl);
    final cityRepository = CityRepository(CityApi(client));
    final ztlRepository = ZtlRepository(ZtlApi(client));
    final mapRepository = ZtlMapRepository(ZtlMapApi(client));

    return CityMapPage(
      cityRepository: cityRepository,
      ztlRepository: ztlRepository,
      mapRepository: mapRepository,
      debugBaseUrl: config!.apiBaseUrl,
      isDebugFallback: config!.isDebugFallback,
    );
  }
}
