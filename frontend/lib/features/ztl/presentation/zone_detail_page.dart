import 'package:flutter/material.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../data/ztl_models.dart';
import '../data/ztl_repository.dart';
import 'widgets/gate_list.dart';
import 'widgets/source_disclaimer.dart';
import 'widgets/status_timeline.dart';
import 'widgets/zone_map_panel.dart';

class ZoneDetailPage extends StatefulWidget {
  const ZoneDetailPage({
    super.key,
    required this.repository,
    required this.initialZone,
  });

  final ZtlRepository repository;
  final ZtlZone initialZone;

  @override
  State<ZoneDetailPage> createState() => _ZoneDetailPageState();
}

class _ZoneDetailPageState extends State<ZoneDetailPage> {
  late Future<ZoneBundle> _bundleFuture;

  @override
  void initState() {
    super.initState();
    _bundleFuture = widget.repository.loadZoneBundle(widget.initialZone.id);
  }

  Future<void> _reload() async {
    setState(() {
      _bundleFuture = widget.repository.loadZoneBundle(widget.initialZone.id);
    });
    await _bundleFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.initialZone.name)),
      body: FutureBuilder<ZoneBundle>(
        future: _bundleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }

          if (snapshot.hasError) {
            return ErrorState(
              title: 'Couldn’t load this zone',
              message: 'Please try again.',
              actionLabel: 'Retry',
              onAction: () {
                _reload();
              },
              debugDetails: snapshot.error is AppError
                  ? (snapshot.error as AppError).debugDetails
                  : snapshot.error.toString(),
            );
          }

          final bundle = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _StatusPanel(zone: bundle.zone),
                const SizedBox(height: 16),
                StatusTimeline(zone: bundle.zone),
                const SizedBox(height: 16),
                ZoneMapPanel(zone: bundle.zone, area: bundle.area, gates: bundle.gates),
                const SizedBox(height: 16),
                _RestrictionsPanel(zone: bundle.zone),
                const SizedBox(height: 16),
                GateList(gates: bundle.gates?.toGateFeatures() ?? const []),
                const SizedBox(height: 16),
                _SourcesPanel(zone: bundle.zone),
                const SizedBox(height: 16),
                const SourceDisclaimer(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.zone});

  final ZtlZone zone;

  @override
  Widget build(BuildContext context) {
    final active = zone.currentStatus.isActive;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              active ? 'Active now' : 'Not active now',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: active
                        ? const Color(0xFFC0392B)
                        : const Color(0xFF0B6B4B),
                  ),
            ),
            const SizedBox(height: 8),
            Text(zone.currentStatus.reason),
            const SizedBox(height: 12),
            Text(
              'Schedule (IT): ${zone.schedule.humanReadableIt}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Schedule (EN): ${zone.schedule.humanReadableEn}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _RestrictionsPanel extends StatelessWidget {
  const _RestrictionsPanel({required this.zone});

  final ZtlZone zone;

  @override
  Widget build(BuildContext context) {
    final restrictions = zone.restrictions;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restrictions and exemptions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            Text('Vehicle classes: ${restrictions.vehicleClasses.join(', ')}'),
            const SizedBox(height: 8),
            Text('Known exemptions: ${restrictions.knownExemptions.join(', ')}'),
            const SizedBox(height: 8),
            Text(restrictions.disabledPermitNote),
            const SizedBox(height: 8),
            Text(restrictions.electricVehicleNote),
            const SizedBox(height: 8),
            Text(restrictions.motorcyclesCiclomotoriNote),
          ],
        ),
      ),
    );
  }
}

class _SourcesPanel extends StatelessWidget {
  const _SourcesPanel({required this.zone});

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
              'Official sources',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            for (final source in zone.sources) ...[
              SelectableText('${source.title}\n${source.url}\nLast verified: ${source.lastVerified}'),
              const SizedBox(height: 10),
            ],
            Text(zone.disclaimer),
          ],
        ),
      ),
    );
  }
}
