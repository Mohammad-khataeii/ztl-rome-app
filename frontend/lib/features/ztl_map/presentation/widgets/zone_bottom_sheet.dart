import 'package:flutter/material.dart';

import '../../../ztl/data/ztl_models.dart';

class ZoneBottomSheet extends StatelessWidget {
  const ZoneBottomSheet({
    super.key,
    required this.zone,
    required this.onOpenDetails,
  });

  final ZtlZone zone;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              zone.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(zone.currentStatus.isActive ? 'Active now' : 'Not active now'),
            const SizedBox(height: 6),
            Text(zone.currentStatus.reason),
            const SizedBox(height: 6),
            Text('Next change: ${zone.currentStatus.nextChangeAt ?? 'Unavailable'}'),
            const SizedBox(height: 6),
            Text(zone.schedule.humanReadableEn),
            const SizedBox(height: 6),
            Text(zone.sources.isNotEmpty ? zone.sources.first.url : zone.disclaimer),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onOpenDetails,
              child: const Text('Open details'),
            ),
          ],
        ),
      ),
    );
  }
}
