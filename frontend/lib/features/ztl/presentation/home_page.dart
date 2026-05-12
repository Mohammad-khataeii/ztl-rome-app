import 'package:flutter/material.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../data/ztl_models.dart';
import '../data/ztl_repository.dart';
import 'widgets/source_disclaimer.dart';
import 'widgets/zone_card.dart';
import 'zone_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.repository,
    required this.debugBaseUrl,
    required this.isDebugFallback,
  });

  final ZtlRepository repository;
  final String? debugBaseUrl;
  final bool isDebugFallback;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<ZtlZone>> _zonesFuture;

  @override
  void initState() {
    super.initState();
    _zonesFuture = widget.repository.loadZones();
  }

  Future<void> _reload() async {
    setState(() {
      _zonesFuture = widget.repository.loadZones();
    });
    await _zonesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZTL Rome'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              _reload();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<ZtlZone>>(
        future: _zonesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }

          if (snapshot.hasError) {
            return ErrorState(
              title: 'Couldn’t load Rome ZTL data',
              message: 'Check your connection or API setup and try again.',
              actionLabel: 'Retry',
              onAction: () {
                _reload();
              },
              debugDetails: snapshot.error is AppError
                  ? (snapshot.error as AppError).debugDetails
                  : snapshot.error.toString(),
            );
          }

          final zones = snapshot.data ?? const [];
          final primaryZone = _choosePrimaryZone(zones);

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _PrimaryStatusCard(
                  zone: primaryZone,
                  debugBaseUrl: widget.debugBaseUrl,
                  isDebugFallback: widget.isDebugFallback,
                ),
                const SizedBox(height: 16),
                Text(
                  'Rome ZTL zones',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                for (final zone in zones)
                  ZoneCard(
                    zone: zone,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ZoneDetailPage(
                            repository: widget.repository,
                            initialZone: zone,
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 8),
                const SourceDisclaimer(),
              ],
            ),
          );
        },
      ),
    );
  }

  ZtlZone? _choosePrimaryZone(List<ZtlZone> zones) {
    for (final zone in zones) {
      if (zone.currentStatus.isActive) {
        return zone;
      }
    }
    return zones.isEmpty ? null : zones.first;
  }
}

class _PrimaryStatusCard extends StatelessWidget {
  const _PrimaryStatusCard({
    required this.zone,
    required this.debugBaseUrl,
    required this.isDebugFallback,
  });

  final ZtlZone? zone;
  final String? debugBaseUrl;
  final bool isDebugFallback;

  @override
  Widget build(BuildContext context) {
    final statusText = zone == null
        ? 'Unavailable'
        : zone!.currentStatus.isActive
            ? 'Active now'
            : 'Not active now';
    final statusColor = zone == null
        ? const Color(0xFF7B3F61)
        : zone!.currentStatus.isActive
            ? const Color(0xFFC0392B)
            : const Color(0xFF0B6B4B);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Can I enter now?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              zone?.name ?? 'No zone data available.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text(
              statusText,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            if (zone != null) ...[
              const SizedBox(height: 8),
              Text(zone!.currentStatus.reason),
              const SizedBox(height: 8),
              Text(
                _nextChangeLabel(zone!),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF5D655F),
                    ),
              ),
            ],
            if (debugBaseUrl != null) ...[
              const SizedBox(height: 12),
              Text(
                isDebugFallback
                    ? 'Debug API fallback: $debugBaseUrl'
                    : 'Debug API: $debugBaseUrl',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF5D655F),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _nextChangeLabel(ZtlZone zone) {
    final nextChangeAt = zone.currentStatus.nextChangeAt;
    if (nextChangeAt == null) {
      return 'Next change unavailable.';
    }
    return 'Next change: ${nextChangeAt.toLocal()}';
  }
}
