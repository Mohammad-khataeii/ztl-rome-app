import '../../ztl/data/ztl_models.dart';
import '../../city/data/city_models.dart';

class CityMapBundle {
  const CityMapBundle({
    required this.city,
    required this.zones,
    required this.areas,
    required this.gates,
    required this.missingGeometryZones,
  });

  final CityModel city;
  final List<ZtlZone> zones;
  final GeoJsonFeatureCollection areas;
  final GeoJsonFeatureCollection gates;
  final List<MissingGeometryZone> missingGeometryZones;

  factory CityMapBundle.fromJson(Map<String, dynamic> json) {
    return CityMapBundle(
      city: CityModel.fromJson(json['city'] as Map<String, dynamic>? ?? const {}),
      zones: ((json['zones'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ZtlZone.fromJson)
          .toList(),
      areas: GeoJsonFeatureCollection.fromJson(
        json['areas'] as Map<String, dynamic>? ?? const {},
      ),
      gates: GeoJsonFeatureCollection.fromJson(
        json['gates'] as Map<String, dynamic>? ?? const {},
      ),
      missingGeometryZones: ((json['missingGeometryZones'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MissingGeometryZone.fromJson)
          .toList(),
    );
  }
}

class MissingGeometryZone {
  const MissingGeometryZone({
    required this.zoneId,
    required this.name,
    required this.reason,
  });

  final String zoneId;
  final String name;
  final String reason;

  factory MissingGeometryZone.fromJson(Map<String, dynamic> json) {
    return MissingGeometryZone(
      zoneId: json['zoneId'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown zone',
      reason: json['reason'] as String? ?? 'Geometry unavailable.',
    );
  }
}
