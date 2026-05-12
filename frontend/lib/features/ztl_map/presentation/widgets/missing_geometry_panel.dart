import 'package:flutter/material.dart';

import '../../../city/data/city_models.dart';
import '../../data/map_bundle_models.dart';

class MissingGeometryPanel extends StatelessWidget {
  const MissingGeometryPanel({
    super.key,
    required this.city,
    required this.zones,
  });

  final CityModel city;
  final List<MissingGeometryZone> zones;

  @override
  Widget build(BuildContext context) {
    if (zones.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Geometry unavailable',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(city.missingGeometryReason),
            const SizedBox(height: 10),
            for (final zone in zones)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(zone.name),
                subtitle: Text(zone.reason),
              ),
          ],
        ),
      ),
    );
  }
}
