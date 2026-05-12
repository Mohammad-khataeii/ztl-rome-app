import 'package:flutter/material.dart';

class MapStatusFilter extends StatelessWidget {
  const MapStatusFilter({
    super.key,
    required this.showActive,
    required this.showInactive,
    required this.showMissing,
    required this.onShowActiveChanged,
    required this.onShowInactiveChanged,
    required this.onShowMissingChanged,
  });

  final bool showActive;
  final bool showInactive;
  final bool showMissing;
  final ValueChanged<bool> onShowActiveChanged;
  final ValueChanged<bool> onShowInactiveChanged;
  final ValueChanged<bool> onShowMissingChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: const Text('Active now'),
          selected: showActive,
          onSelected: onShowActiveChanged,
        ),
        FilterChip(
          label: const Text('Not active'),
          selected: showInactive,
          onSelected: onShowInactiveChanged,
        ),
        FilterChip(
          label: const Text('Geometry missing'),
          selected: showMissing,
          onSelected: onShowMissingChanged,
        ),
      ],
    );
  }
}
