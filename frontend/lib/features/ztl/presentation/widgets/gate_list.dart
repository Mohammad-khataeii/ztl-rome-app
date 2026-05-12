import 'package:flutter/material.dart';

import '../../data/ztl_models.dart';

class GateList extends StatefulWidget {
  const GateList({
    super.key,
    required this.gates,
  });

  final List<GateFeature> gates;

  @override
  State<GateList> createState() => _GateListState();
}

class _GateListState extends State<GateList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    if (widget.gates.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No official gate list is available for this zone yet.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final gates = widget.gates.where((gate) {
      final haystack = '${gate.name} ${gate.reference}'.toLowerCase();
      return haystack.contains(_query.toLowerCase());
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Access gates',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: 'Search by street or reference',
                helperText: '${gates.length} of ${widget.gates.length} gates',
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            for (final gate in gates)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFE3F1EA),
                  foregroundColor: const Color(0xFF0B6B4B),
                  child: Text(gate.id),
                ),
                title: Text(gate.name),
                subtitle: Text(
                  gate.reference.isEmpty
                      ? '${gate.point.latitude.toStringAsFixed(5)}, ${gate.point.longitude.toStringAsFixed(5)}'
                      : gate.reference,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
