import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/api/api_client.dart';
import '../core/widgets/error_state.dart';
import '../features/ztl/data/ztl_api.dart';
import '../features/ztl/data/ztl_repository.dart';
import '../features/ztl/presentation/home_page.dart';
import 'app_config.dart';
import 'app_theme.dart';

class ZtlRomeApp extends StatelessWidget {
  const ZtlRomeApp({
    super.key,
    required this.config,
    required this.configurationError,
  });

  final AppConfig? config;
  final String? configurationError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZTL Rome',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (configurationError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ZTL Rome')),
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
    final repository = ZtlRepository(ZtlApi(client));

    return HomePage(
      repository: repository,
      debugBaseUrl: kDebugMode ? config!.apiBaseUrl : null,
      isDebugFallback: config!.isDebugFallback,
    );
  }
}
