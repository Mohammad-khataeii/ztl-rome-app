class CityModel {
  const CityModel({
    required this.id,
    required this.name,
    required this.country,
    required this.timezone,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.defaultZoom,
    required this.enabled,
    required this.supportedStatus,
    required this.sourceSummary,
    required this.lastVerified,
    required this.hasAnyGeometry,
    required this.missingGeometryReason,
  });

  final String id;
  final String name;
  final String country;
  final String timezone;
  final double centerLatitude;
  final double centerLongitude;
  final double defaultZoom;
  final bool enabled;
  final String supportedStatus;
  final String sourceSummary;
  final String lastVerified;
  final bool hasAnyGeometry;
  final String missingGeometryReason;

  factory CityModel.fromJson(Map<String, dynamic> json) {
    final center = json['center'] as Map<String, dynamic>? ?? const {};
    final geometryStatus =
        json['geometryStatus'] as Map<String, dynamic>? ?? const {};
    return CityModel(
      id: json['id'] as String? ?? 'unknown',
      name: json['name'] as String? ?? 'Unknown city',
      country: json['country'] as String? ?? 'Italy',
      timezone: json['timezone'] as String? ?? 'Europe/Rome',
      centerLatitude: (center['latitude'] as num?)?.toDouble() ?? 0,
      centerLongitude: (center['longitude'] as num?)?.toDouble() ?? 0,
      defaultZoom: (json['defaultZoom'] as num?)?.toDouble() ?? 11,
      enabled: json['enabled'] as bool? ?? false,
      supportedStatus: json['supportedStatus'] as String? ?? 'schedule_only',
      sourceSummary: json['sourceSummary'] as String? ?? '',
      lastVerified: json['lastVerified'] as String? ?? '',
      hasAnyGeometry: geometryStatus['hasAnyGeometry'] as bool? ?? false,
      missingGeometryReason:
          geometryStatus['missingGeometryReason'] as String? ?? '',
    );
  }
}
