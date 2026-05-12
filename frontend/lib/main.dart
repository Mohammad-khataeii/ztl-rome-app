import 'package:flutter/material.dart';

import 'app/app_config.dart';
import 'app/ztl_rome_app.dart';

void main() {
  AppConfig? config;
  String? configurationError;

  try {
    config = AppConfig.fromEnvironment();
  } on StateError catch (error) {
    configurationError = error.message?.toString() ?? error.toString();
  }

  runApp(
    ZtlRomeApp(
      config: config,
      configurationError: configurationError,
    ),
  );
}
