import 'package:flutter/material.dart';

import '../../data/ztl_models.dart';
import '../painters/ztl_map_painter.dart';

class ZoneMapPanel extends StatelessWidget {
  const ZoneMapPanel({
    super.key,
    required this.zone,
    required this.area,
    required this.gates,
  });

  final ZtlZone zone;
  final GeoJsonFeatureCollection? area;
  final GeoJsonFeatureCollection? gates;

  @override
  Widget build(BuildContext context) {
    if (!zone.geometry.hasAnyGeometry) {
      return const _EmptyGeometryCard(
        title: 'Boundary unavailable',
        message: 'This beta does not yet have an official boundary dataset here.',
      );
    }

    final rings = <List<GeoPoint>>[];
    for (final feature in area?.features ?? const <GeoJsonFeature>[]) {
      rings.addAll(feature.toRings());
    }
    final gateFeatures = gates?.toGateFeatures() ?? const <GateFeature>[];

    if (rings.isEmpty && gateFeatures.isEmpty) {
      return const _EmptyGeometryCard(
        title: 'Geometry unavailable',
        message: 'The API did not return usable geometry for this zone.',
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.25,
            child: CustomPaint(
              painter: ZtlMapPainter(
                rings: rings,
                gates: gateFeatures,
                bounds: zone.geometry.bounds,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Text(
              'Map preview only. Official rules still come from the official city source.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5D655F),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyGeometryCard extends StatelessWidget {
  const _EmptyGeometryCard({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(message),
          ],
        ),
      ),
    );
  }
}
