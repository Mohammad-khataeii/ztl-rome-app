import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.isDebugFallback,
  });

  final String apiBaseUrl;
  final bool isDebugFallback;

  static const _apiBaseUrlDefine = String.fromEnvironment('ZTL_API_BASE_URL');

  factory AppConfig.fromEnvironment() {
    final trimmed = _apiBaseUrlDefine.trim();
    if (trimmed.isNotEmpty && _isValidBaseUrl(trimmed)) {
      return AppConfig(apiBaseUrl: trimmed, isDebugFallback: false);
    }

    if (kDebugMode) {
      return const AppConfig(
        apiBaseUrl: 'http://127.0.0.1:8000',
        isDebugFallback: true,
      );
    }

    throw StateError(
      'ZTL_API_BASE_URL is required for non-debug builds.',
    );
  }

  static bool _isValidBaseUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }
}
