import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/app_error.dart';

class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<Map<String, dynamic>> getObject(String path) async {
    final jsonValue = await _getJson(path);
    if (jsonValue is Map<String, dynamic>) {
      return jsonValue;
    }
    throw const AppError(message: 'Unexpected API response.');
  }

  Future<List<dynamic>> getList(String path) async {
    final jsonValue = await _getJson(path);
    if (jsonValue is List<dynamic>) {
      return jsonValue;
    }
    throw const AppError(message: 'Unexpected API response.');
  }

  Future<dynamic> _getJson(String path) async {
    final uri = Uri.parse('$baseUrl$path');

    late http.Response response;
    try {
      response = await _client.get(uri);
    } catch (error) {
      throw AppError(
        message: 'Couldn’t reach the Rome ZTL service.',
        debugDetails: error.toString(),
      );
    }

    if (response.statusCode >= 400) {
      final detail = _extractErrorDetail(response.body);
      throw AppError(
        message: detail ?? 'The Rome ZTL service returned an error.',
        debugDetails: 'HTTP ${response.statusCode} for $path',
      );
    }

    try {
      return jsonDecode(response.body);
    } catch (error) {
      throw AppError(
        message: 'The Rome ZTL service returned unreadable data.',
        debugDetails: error.toString(),
      );
    }
  }

  String? _extractErrorDetail(String body) {
    try {
      final value = jsonDecode(body);
      if (value is Map<String, dynamic> && value['detail'] is String) {
        return value['detail'] as String;
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
