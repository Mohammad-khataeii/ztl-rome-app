import 'package:flutter/material.dart';

import '../../../ztl/data/ztl_models.dart';

class GateBottomSheet extends StatelessWidget {
  const GateBottomSheet({
    super.key,
    required this.gate,
    required this.zone,
    required this.onOpenZoneDetails,
  });

  final GateFeature gate;
  final ZtlZone zone;
  final VoidCallback onOpenZoneDetails;

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
              gate.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            if (gate.reference.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(gate.reference),
            ],
            const SizedBox(height: 6),
            Text(zone.name),
            const SizedBox(height: 6),
            Text(zone.currentStatus.isActive ? 'Zone active now' : 'Zone not active now'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onOpenZoneDetails,
              child: const Text('Open zone details'),
            ),
          ],
        ),
      ),
    );
  }
}
