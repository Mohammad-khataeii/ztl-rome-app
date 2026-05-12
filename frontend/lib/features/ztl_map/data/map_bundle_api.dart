import '../../../core/api/api_client.dart';
import 'map_bundle_models.dart';

class ZtlMapApi {
  const ZtlMapApi(this._client);

  final ApiClient _client;

  Future<CityMapBundle> fetchCityMap(String cityId) async {
    final payload = await _client.getObject('/api/cities/$cityId/ztl/map');
    return CityMapBundle.fromJson(payload);
  }
}

class ZtlMapRepository {
  const ZtlMapRepository(this._api);

  final ZtlMapApi _api;

  Future<CityMapBundle> loadCityMap(String cityId) => _api.fetchCityMap(cityId);
}
