import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/ztl_models.dart';

class ZtlMapPainter extends CustomPainter {
  ZtlMapPainter({
    required this.rings,
    required this.gates,
    required this.bounds,
  });

  final List<List<GeoPoint>> rings;
  final List<GateFeature> gates;
  final GeoBounds? bounds;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFEAF0E9);
    canvas.drawRect(Offset.zero & size, background);

    final drawingBounds = _effectiveBounds();
    if (drawingBounds == null) {
      return;
    }

    final path = Path()..fillType = PathFillType.evenOdd;
    for (final ring in rings) {
      if (ring.isEmpty) {
        continue;
      }
      path.moveTo(_x(ring.first, size, drawingBounds), _y(ring.first, size, drawingBounds));
      for (final point in ring.skip(1)) {
        path.lineTo(_x(point, size, drawingBounds), _y(point, size, drawingBounds));
      }
      path.close();
    }

    if (!path.getBounds().isEmpty) {
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF0B6B4B).withValues(alpha: 0.18)
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF0B6B4B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    for (final gate in gates) {
      final center = Offset(
        _x(gate.point, size, drawingBounds),
        _y(gate.point, size, drawingBounds),
      );
      canvas.drawCircle(center, 6, Paint()..color = const Color(0xFFC0392B));
      canvas.drawCircle(
        center,
        6,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  GeoBounds? _effectiveBounds() {
    if (bounds != null) {
      return bounds;
    }

    final allPoints = <GeoPoint>[
      for (final ring in rings) ...ring,
      for (final gate in gates) gate.point,
    ];
    if (allPoints.isEmpty) {
      return null;
    }

    final longitudes = allPoints.map((item) => item.longitude).toList();
    final latitudes = allPoints.map((item) => item.latitude).toList();
    return GeoBounds(
      west: longitudes.reduce(math.min),
      south: latitudes.reduce(math.min),
      east: longitudes.reduce(math.max),
      north: latitudes.reduce(math.max),
    );
  }

  double _x(GeoPoint point, Size size, GeoBounds bounds) {
    final available = math.max(bounds.east - bounds.west, 0.000001);
    return 18 + ((point.longitude - bounds.west) / available) * (size.width - 36);
  }

  double _y(GeoPoint point, Size size, GeoBounds bounds) {
    final available = math.max(bounds.north - bounds.south, 0.000001);
    return 18 + ((bounds.north - point.latitude) / available) * (size.height - 36);
  }

  @override
  bool shouldRepaint(covariant ZtlMapPainter oldDelegate) {
    return oldDelegate.rings != rings ||
        oldDelegate.gates != gates ||
        oldDelegate.bounds != bounds;
  }
}
