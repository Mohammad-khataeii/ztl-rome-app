import 'package:flutter/material.dart';

import '../../data/ztl_models.dart';

class StatusTimeline extends StatelessWidget {
  const StatusTimeline({
    super.key,
    required this.zone,
  });

  final ZtlZone zone;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            Text('Next change: ${_nextChangeText(zone.currentStatus.nextChangeAt)}'),
            const SizedBox(height: 10),
            for (final rule in zone.schedule.rules) ...[
              Text(rule.labelEn),
              const SizedBox(height: 4),
            ],
            if (zone.schedule.exclusions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Exclusions: ${zone.schedule.exclusions.join(' ')}'),
            ],
          ],
        ),
      ),
    );
  }

  String _nextChangeText(DateTime? value) {
    if (value == null) {
      return 'Unavailable';
    }
    return value.toLocal().toString();
  }
}
