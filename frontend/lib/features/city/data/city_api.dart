import '../../../core/api/api_client.dart';
import 'city_models.dart';

class CityApi {
  const CityApi(this._client);

  final ApiClient _client;

  Future<List<CityModel>> fetchCities() async {
    final payload = await _client.getObject('/api/cities');
    final cities = payload['cities'] as List<dynamic>? ?? const [];
    return cities
        .whereType<Map<String, dynamic>>()
        .map(CityModel.fromJson)
        .toList();
  }
}
