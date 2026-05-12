import '../../../core/api/api_client.dart';
import 'ztl_models.dart';

class ZtlApi {
  const ZtlApi(this._client);

  final ApiClient _client;

  Future<List<ZtlZone>> fetchZones() async {
    final payload = await _client.getObject('/api/ztl/zones');
    final zones = payload['zones'] as List<dynamic>? ?? const [];
    return zones
        .whereType<Map<String, dynamic>>()
        .map(ZtlZone.fromJson)
        .toList();
  }

  Future<ZtlZone> fetchZone(String zoneId) async {
    final payload = await _client.getObject('/api/ztl/zones/$zoneId');
    return ZtlZone.fromJson(payload);
  }

  Future<GeoJsonFeatureCollection?> fetchArea(String endpoint) async {
    final payload = await _client.getObject(endpoint);
    return GeoJsonFeatureCollection.fromJson(payload);
  }

  Future<GeoJsonFeatureCollection?> fetchGates(String endpoint) async {
    final payload = await _client.getObject(endpoint);
    return GeoJsonFeatureCollection.fromJson(payload);
  }
}
