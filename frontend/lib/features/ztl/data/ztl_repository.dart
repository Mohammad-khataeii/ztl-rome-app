import '../../../core/errors/app_error.dart';
import 'ztl_api.dart';
import 'ztl_models.dart';

class ZtlRepository {
  const ZtlRepository(this._api);

  final ZtlApi _api;

  Future<List<ZtlZone>> loadZones(String cityId) => _api.fetchZones(cityId);

  Future<ZoneBundle> loadZoneBundle(String cityId, String zoneId) async {
    final zone = await _api.fetchZone(cityId, zoneId);
    GeoJsonFeatureCollection? area;
    GeoJsonFeatureCollection? gates;

    if (zone.geometry.areaEndpoint != null) {
      try {
        area = await _api.fetchArea(zone.geometry.areaEndpoint!);
      } on AppError {
        area = null;
      }
    }

    if (zone.geometry.gatesEndpoint != null) {
      try {
        gates = await _api.fetchGates(zone.geometry.gatesEndpoint!);
      } on AppError {
        gates = null;
      }
    }

    return ZoneBundle(zone: zone, area: area, gates: gates);
  }
}
