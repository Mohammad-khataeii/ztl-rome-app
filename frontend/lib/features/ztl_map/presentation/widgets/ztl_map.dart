import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../ztl/data/ztl_models.dart';
import '../../data/map_bundle_models.dart';

class ZtlMap extends StatelessWidget {
  const ZtlMap({
    super.key,
    required this.bundle,
    required this.visibleZones,
    required this.onZoneTap,
    required this.onGateTap,
  });

  final CityMapBundle bundle;
  final List<ZtlZone> visibleZones;
  final ValueChanged<ZtlZone> onZoneTap;
  final ValueChanged<GateFeature> onGateTap;

  @override
  Widget build(BuildContext context) {
    final polygons = _buildPolygons();
    final gates = _buildGateFeatures();
    final center = LatLng(bundle.city.centerLatitude, bundle.city.centerLongitude);

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: bundle.city.defaultZoom,
        onTap: (tapPosition, latLng) => _handleMapTap(latLng),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'app.ztl_italy',
        ),
        PolygonLayer(polygons: polygons),
        MarkerLayer(
          markers: [
            for (final gate in gates)
              Marker(
                point: LatLng(gate.point.latitude, gate.point.longitude),
                width: 28,
                height: 28,
                child: GestureDetector(
                  onTap: () => onGateTap(gate),
                  child: const Icon(Icons.location_on, color: Color(0xFF345995)),
                ),
              ),
          ],
        ),
      ],
    );
  }

  List<Polygon> _buildPolygons() {
    final zoneById = {for (final zone in visibleZones) zone.zoneId: zone};
    return bundle.areas.features
        .where((feature) => zoneById.containsKey(feature.properties['zoneId']))
        .expand((feature) {
      final zone = zoneById[feature.properties['zoneId']]!;
      final rings = _ringsFromFeature(feature);
      return rings.map(
        (ring) => Polygon(
          points: ring
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList(growable: false),
          color: _fillColor(zone),
          borderColor: _strokeColor(zone),
          borderStrokeWidth: math.max(1, zone.mapStyle.priority.toDouble() / 2),
        ),
      );
    }).toList();
  }

  List<GateFeature> _buildGateFeatures() {
    return bundle.gates.features
        .where((feature) => visibleZones.any((zone) => zone.zoneId == feature.properties['zoneId']))
        .map(GateFeature.fromFeature)
        .toList();
  }

  void _handleMapTap(LatLng latLng) {
    final zone = visibleZones.firstWhereOrNull(
      (candidate) => bundle.areas.features.any(
        (feature) =>
            feature.properties['zoneId'] == candidate.zoneId &&
            _containsPoint(_ringsFromFeature(feature), latLng),
      ),
    );
    if (zone != null) {
      onZoneTap(zone);
    }
  }

  List<List<GeoPoint>> _ringsFromFeature(GeoJsonFeature feature) {
    if (feature.geometryType == 'Polygon') {
      return _polygonRings(feature.coordinates);
    }
    if (feature.geometryType == 'MultiPolygon') {
      final polygons = (feature.coordinates as List<dynamic>? ?? const []);
      return polygons
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
              .toList(),
        )
        .where((ring) => ring.isNotEmpty)
        .toList();
  }

  bool _containsPoint(List<List<GeoPoint>> rings, LatLng point) {
    for (final ring in rings) {
      if (_pointInRing(ring, point)) {
        return true;
      }
    }
    return false;
  }

  bool _pointInRing(List<GeoPoint> ring, LatLng point) {
    var inside = false;
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final xi = ring[i].longitude;
      final yi = ring[i].latitude;
      final xj = ring[j].longitude;
      final yj = ring[j].latitude;
      final intersects = ((yi > point.latitude) != (yj > point.latitude)) &&
          (point.longitude <
              (xj - xi) * (point.latitude - yi) / ((yj - yi) == 0 ? 0.000001 : (yj - yi)) + xi);
      if (intersects) {
        inside = !inside;
      }
    }
    return inside;
  }

  Color _fillColor(ZtlZone zone) {
    return zone.currentStatus.isActive
        ? const Color(0xFFC0392B).withValues(alpha: 0.26)
        : const Color(0xFF0B6B4B).withValues(alpha: 0.18);
  }

  Color _strokeColor(ZtlZone zone) {
    return zone.currentStatus.isActive
        ? const Color(0xFFC0392B)
        : const Color(0xFF0B6B4B);
  }
}
