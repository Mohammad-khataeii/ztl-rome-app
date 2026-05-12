class ZtlZone {
  const ZtlZone({
    required this.id,
    required this.zoneId,
    required this.cityId,
    required this.name,
    required this.city,
    required this.type,
    required this.timezone,
    required this.currentStatus,
    required this.schedule,
    required this.restrictions,
    required this.mapStyle,
    required this.geometry,
    required this.sources,
    required this.disclaimer,
  });

  final String id;
  final String zoneId;
  final String cityId;
  final String name;
  final String city;
  final String type;
  final String timezone;
  final ZoneCurrentStatus currentStatus;
  final ZoneSchedule schedule;
  final ZoneRestrictions restrictions;
  final ZoneMapStyle mapStyle;
  final ZoneGeometry geometry;
  final List<ZoneSource> sources;
  final String disclaimer;

  factory ZtlZone.fromJson(Map<String, dynamic> json) {
    return ZtlZone(
      id: json['id'] as String? ?? 'unknown-zone',
      zoneId: json['zoneId'] as String? ?? json['id'] as String? ?? 'unknown-zone',
      cityId: json['cityId'] as String? ?? 'rome',
      name: json['name'] as String? ?? 'Unknown zone',
      city: json['city'] as String? ?? 'Unknown city',
      type: json['type'] as String? ?? 'unknown',
      timezone: json['timezone'] as String? ?? 'Europe/Rome',
      currentStatus: ZoneCurrentStatus.fromJson(
        json['currentStatus'] as Map<String, dynamic>? ?? const {},
      ),
      schedule: ZoneSchedule.fromJson(
        json['schedule'] as Map<String, dynamic>? ?? const {},
      ),
      restrictions: ZoneRestrictions.fromJson(
        json['restrictions'] as Map<String, dynamic>? ?? const {},
      ),
      mapStyle: ZoneMapStyle.fromJson(
        json['mapStyle'] as Map<String, dynamic>? ?? const {},
      ),
      geometry: ZoneGeometry.fromJson(
        json['geometry'] as Map<String, dynamic>? ?? const {},
      ),
      sources: ((json['sources'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ZoneSource.fromJson)
          .toList(),
      disclaimer: json['disclaimer'] as String? ??
          'Official rules may change. Check the official city source before entering.',
    );
  }
}

class ZoneCurrentStatus {
  const ZoneCurrentStatus({
    required this.isActive,
    required this.checkedAt,
    required this.reason,
    required this.nextChangeAt,
    required this.confidence,
  });

  final bool isActive;
  final DateTime? checkedAt;
  final String reason;
  final DateTime? nextChangeAt;
  final String confidence;

  factory ZoneCurrentStatus.fromJson(Map<String, dynamic> json) {
    return ZoneCurrentStatus(
      isActive: json['isActive'] as bool? ?? false,
      checkedAt: _parseDateTime(json['checkedAt']),
      reason: json['reason'] as String? ?? 'Unavailable',
      nextChangeAt: _parseDateTime(json['nextChangeAt']),
      confidence: json['confidence'] as String? ?? 'missing_data',
    );
  }
}

class ZoneSchedule {
  const ZoneSchedule({
    required this.humanReadableIt,
    required this.humanReadableEn,
    required this.rules,
    required this.exclusions,
  });

  final String humanReadableIt;
  final String humanReadableEn;
  final List<ZoneScheduleRule> rules;
  final List<String> exclusions;

  factory ZoneSchedule.fromJson(Map<String, dynamic> json) {
    return ZoneSchedule(
      humanReadableIt: json['humanReadableIt'] as String? ?? '',
      humanReadableEn: json['humanReadableEn'] as String? ?? '',
      rules: ((json['rules'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ZoneScheduleRule.fromJson)
          .toList(),
      exclusions: ((json['exclusions'] as List<dynamic>?) ?? const [])
          .whereType<String>()
          .toList(),
    );
  }
}

class ZoneScheduleRule {
  const ZoneScheduleRule({
    required this.id,
    required this.labelIt,
    required this.labelEn,
    required this.weekdays,
    required this.startTime,
    required this.endTime,
  });

  final String id;
  final String labelIt;
  final String labelEn;
  final List<int> weekdays;
  final String startTime;
  final String endTime;

  factory ZoneScheduleRule.fromJson(Map<String, dynamic> json) {
    return ZoneScheduleRule(
      id: json['id'] as String? ?? 'unknown-rule',
      labelIt: json['labelIt'] as String? ?? '',
      labelEn: json['labelEn'] as String? ?? '',
      weekdays: ((json['weekdays'] as List<dynamic>?) ?? const [])
          .whereType<num>()
          .map((item) => item.toInt())
          .toList(),
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
    );
  }
}

class ZoneRestrictions {
  const ZoneRestrictions({
    required this.vehicleClasses,
    required this.knownExemptions,
    required this.disabledPermitNote,
    required this.electricVehicleNote,
    required this.motorcyclesCiclomotoriNote,
  });

  final List<String> vehicleClasses;
  final List<String> knownExemptions;
  final String disabledPermitNote;
  final String electricVehicleNote;
  final String motorcyclesCiclomotoriNote;

  factory ZoneRestrictions.fromJson(Map<String, dynamic> json) {
    return ZoneRestrictions(
      vehicleClasses: ((json['vehicleClasses'] as List<dynamic>?) ?? const [])
          .whereType<String>()
          .toList(),
      knownExemptions: ((json['knownExemptions'] as List<dynamic>?) ?? const [])
          .whereType<String>()
          .toList(),
      disabledPermitNote: json['disabledPermitNote'] as String? ?? '',
      electricVehicleNote: json['electricVehicleNote'] as String? ?? '',
      motorcyclesCiclomotoriNote:
          json['motorcyclesCiclomotoriNote'] as String? ?? '',
    );
  }
}

class ZoneMapStyle {
  const ZoneMapStyle({
    required this.fillColorKey,
    required this.strokeColorKey,
    required this.priority,
    required this.visibleByDefault,
  });

  final String fillColorKey;
  final String strokeColorKey;
  final int priority;
  final bool visibleByDefault;

  factory ZoneMapStyle.fromJson(Map<String, dynamic> json) {
    return ZoneMapStyle(
      fillColorKey: json['fillColorKey'] as String? ?? 'default_fill',
      strokeColorKey: json['strokeColorKey'] as String? ?? 'default_stroke',
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      visibleByDefault: json['visibleByDefault'] as bool? ?? true,
    );
  }
}

class ZoneGeometry {
  const ZoneGeometry({
    required this.hasArea,
    required this.hasGates,
    required this.areaEndpoint,
    required this.gatesEndpoint,
    required this.quality,
    required this.bounds,
  });

  final bool hasArea;
  final bool hasGates;
  final String? areaEndpoint;
  final String? gatesEndpoint;
  final String quality;
  final GeoBounds? bounds;

  bool get hasAnyGeometry => hasArea || hasGates;

  factory ZoneGeometry.fromJson(Map<String, dynamic> json) {
    return ZoneGeometry(
      hasArea: json['hasArea'] as bool? ?? false,
      hasGates: json['hasGates'] as bool? ?? false,
      areaEndpoint: json['areaEndpoint'] as String?,
      gatesEndpoint: json['gatesEndpoint'] as String?,
      quality: json['quality'] as String? ?? 'missing',
      bounds: json['bounds'] is Map<String, dynamic>
          ? GeoBounds.fromJson(json['bounds'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ZoneSource {
  const ZoneSource({
    required this.title,
    required this.url,
    required this.publisher,
    required this.lastVerified,
  });

  final String title;
  final String url;
  final String publisher;
  final String lastVerified;

  factory ZoneSource.fromJson(Map<String, dynamic> json) {
    return ZoneSource(
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      publisher: json['publisher'] as String? ?? '',
      lastVerified: json['lastVerified'] as String? ?? '',
    );
  }
}

class GeoBounds {
  const GeoBounds({
    required this.west,
    required this.south,
    required this.east,
    required this.north,
  });

  final double west;
  final double south;
  final double east;
  final double north;

  factory GeoBounds.fromJson(Map<String, dynamic> json) {
    return GeoBounds(
      west: (json['west'] as num?)?.toDouble() ?? 0,
      south: (json['south'] as num?)?.toDouble() ?? 0,
      east: (json['east'] as num?)?.toDouble() ?? 0,
      north: (json['north'] as num?)?.toDouble() ?? 0,
    );
  }
}

class GeoPoint {
  const GeoPoint({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  factory GeoPoint.fromCoordinates(List<dynamic> coordinates) {
    return GeoPoint(
      longitude: (coordinates[0] as num?)?.toDouble() ?? 0,
      latitude: (coordinates[1] as num?)?.toDouble() ?? 0,
    );
  }
}

class GeoJsonFeatureCollection {
  const GeoJsonFeatureCollection({
    required this.type,
    required this.features,
  });

  final String type;
  final List<GeoJsonFeature> features;

  factory GeoJsonFeatureCollection.fromJson(Map<String, dynamic> json) {
    return GeoJsonFeatureCollection(
      type: json['type'] as String? ?? 'FeatureCollection',
      features: ((json['features'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(GeoJsonFeature.fromJson)
          .toList(),
    );
  }

  List<GateFeature> toGateFeatures() {
    return features
        .where((feature) => feature.geometryType == 'Point')
        .map(GateFeature.fromFeature)
        .toList(growable: false);
  }
}

class GeoJsonFeature {
  const GeoJsonFeature({
    required this.id,
    required this.geometryType,
    required this.coordinates,
    required this.properties,
  });

  final dynamic id;
  final String geometryType;
  final dynamic coordinates;
  final Map<String, dynamic> properties;

  factory GeoJsonFeature.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>? ?? const {};
    return GeoJsonFeature(
      id: json['id'],
      geometryType: geometry['type'] as String? ?? 'Unknown',
      coordinates: geometry['coordinates'],
      properties: json['properties'] as Map<String, dynamic>? ?? const {},
    );
  }

  List<List<GeoPoint>> toRings() {
    if (geometryType == 'Polygon') {
      return _polygonRings(coordinates);
    }
    if (geometryType == 'MultiPolygon') {
      return (coordinates as List<dynamic>? ?? const [])
          .whereType<List<dynamic>>()
          .expand(_polygonRings)
          .toList();
    }
    return const [];
  }

  List<List<GeoPoint>> _polygonRings(dynamic polygonCoordinates) {
    return (polygonCoordinates as List<dynamic>? ?? const [])
        .whereType<List<dynamic>>()
        .map(
          (ring) => ring
              .whereType<List<dynamic>>()
              .map(GeoPoint.fromCoordinates)
              .toList(growable: false),
        )
        .where((ring) => ring.isNotEmpty)
        .toList(growable: false);
  }
}

class GateFeature {
  const GateFeature({
    required this.id,
    required this.name,
    required this.reference,
    required this.zoneId,
    required this.zoneName,
    required this.isActive,
    required this.point,
  });

  final String id;
  final String name;
  final String reference;
  final String zoneId;
  final String zoneName;
  final bool isActive;
  final GeoPoint point;

  factory GateFeature.fromFeature(GeoJsonFeature feature) {
    return GateFeature(
      id: '${feature.id ?? feature.properties['ID'] ?? ''}',
      name: feature.properties['gateName'] as String? ??
          feature.properties['LOCALIZZAZ'] as String? ??
          'Unknown gate',
      reference: (feature.properties['gateReference'] as String? ??
              feature.properties['RIFERIMENT'] as String? ??
              '')
          .trim(),
      zoneId: feature.properties['zoneId'] as String? ?? '',
      zoneName: feature.properties['zoneName'] as String? ?? '',
      isActive: feature.properties['statusIsActive'] as bool? ?? false,
      point: GeoPoint.fromCoordinates(
        feature.coordinates as List<dynamic>? ?? const [0, 0],
      ),
    );
  }
}

class ZoneBundle {
  const ZoneBundle({
    required this.zone,
    required this.area,
    required this.gates,
  });

  final ZtlZone zone;
  final GeoJsonFeatureCollection? area;
  final GeoJsonFeatureCollection? gates;
}

DateTime? _parseDateTime(dynamic value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}
