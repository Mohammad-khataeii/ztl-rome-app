import 'package:flutter/material.dart';

import '../../../../core/widgets/status_chip.dart';
import '../../data/ztl_models.dart';

class ZoneCard extends StatelessWidget {
  const ZoneCard({
    super.key,
    required this.zone,
    required this.onTap,
  });

  final ZtlZone zone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = zone.currentStatus.isActive;

    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      zone.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 10),
              StatusChip(
                color: active
                    ? const Color(0xFFC0392B)
                    : const Color(0xFF0B6B4B),
                icon: active ? Icons.block : Icons.check_circle,
                label: active ? 'Active now' : 'Not active now',
              ),
              const SizedBox(height: 10),
              Text(zone.currentStatus.reason),
              const SizedBox(height: 8),
              Text('Today: ${zone.schedule.humanReadableEn}'),
              const SizedBox(height: 8),
              Text(_warning(zone)),
            ],
          ),
        ),
      ),
    );
  }

  String _warning(ZtlZone zone) {
    if (zone.currentStatus.confidence == 'missing_data') {
      return 'Some official data is missing.';
    }
    return 'Official rules may change. Check the official city source before entering.';
  }
}
