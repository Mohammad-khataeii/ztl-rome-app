import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const ZtlRomeApp());
}

class ZtlRomeApp extends StatelessWidget {
  const ZtlRomeApp({super.key, this.initialDashboardFuture});

  final Future<ZtlDashboardData>? initialDashboardFuture;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF17201A);
    const green = Color(0xFF0B6B4B);
    const paper = Color(0xFFF7F4EC);

    return MaterialApp(
      title: 'ZTL Rome',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: green,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: paper,
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: ink,
              displayColor: ink,
            ),
        appBarTheme: const AppBarTheme(
          backgroundColor: paper,
          foregroundColor: ink,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            side: BorderSide(color: Color(0xFFE1DED4)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: ZtlHomePage(initialDashboardFuture: initialDashboardFuture),
    );
  }
}

class ZtlHomePage extends StatefulWidget {
  const ZtlHomePage({super.key, this.initialDashboardFuture});

  final Future<ZtlDashboardData>? initialDashboardFuture;

  @override
  State<ZtlHomePage> createState() => _ZtlHomePageState();
}

class _ZtlHomePageState extends State<ZtlHomePage> {
  late final TextEditingController _apiController;
  late Future<ZtlDashboardData> _dashboardFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _apiController = TextEditingController(text: 'http://127.0.0.1:8000');
    _dashboardFuture = widget.initialDashboardFuture ??
        ZtlApiClient(_apiController.text).loadDashboard();
  }

  @override
  void dispose() {
    _apiController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _dashboardFuture = ZtlApiClient(_apiController.text).loadDashboard();
    });
    await _dashboardFuture.catchError((_) => ZtlDashboardData.empty());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZTL Rome'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<ZtlDashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final error = snapshot.error;
          if (error != null) {
            return _ApiErrorPanel(
              controller: _apiController,
              message: error.toString(),
              onRetry: _reload,
            );
          }

          final data = snapshot.requireData;
          final filteredGates = data.gates.where((gate) {
            final haystack = '${gate.name} ${gate.reference}'.toLowerCase();
            return haystack.contains(_query.toLowerCase());
          }).toList();

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _Header(summary: data.summary),
                const SizedBox(height: 14),
                _ConnectionBar(controller: _apiController, onConnect: _reload),
                const SizedBox(height: 14),
                _MapPanel(data: data),
                const SizedBox(height: 14),
                _GateSearch(
                  count: filteredGates.length,
                  total: data.gates.length,
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 10),
                for (final gate in filteredGates) _GateTile(gate: gate),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.summary});

  final ZtlSummary summary;

  @override
  Widget build(BuildContext context) {
    final active = summary.isActive;
    final color = active ? const Color(0xFFC0392B) : const Color(0xFF0B6B4B);
    final label = active ? 'Active now' : 'Not active now';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          summary.name,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Night access gates and the Centro Storico boundary in one place.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _StatusChip(color: color, icon: Icons.traffic, label: label),
            _StatusChip(
              color: const Color(0xFF345995),
              icon: Icons.pin_drop,
              label: '${summary.gateCount} gates',
            ),
            _StatusChip(
              color: const Color(0xFF7B3F61),
              icon: Icons.schedule,
              label: 'Fri-Sat 23:00-03:00',
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          summary.note,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF5D655F),
              ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionBar extends StatelessWidget {
  const _ConnectionBar({required this.controller, required this.onConnect});

  final TextEditingController controller;
  final Future<void> Function() onConnect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 520;
            final field = TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Backend URL',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.url,
              onSubmitted: (_) => onConnect(),
            );
            final button = FilledButton(
              onPressed: onConnect,
              child: const Text('Connect'),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [field, const SizedBox(height: 10), button],
              );
            }

            return Row(
              children: [
                Expanded(child: field),
                const SizedBox(width: 10),
                button,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MapPanel extends StatelessWidget {
  const _MapPanel({required this.data});

  final ZtlDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.25,
            child: CustomPaint(
              painter: ZtlMapPainter(
                polygon: data.areaPolygon,
                gates: data.gates,
                bounds: data.summary.bounds,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Text(
              'The sketch uses the backend GeoJSON boundary and gate coordinates.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5D655F),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GateSearch extends StatelessWidget {
  const _GateSearch({
    required this.count,
    required this.total,
    required this.onChanged,
  });

  final int count;
  final int total;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Access gates',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            labelText: 'Search by street or reference',
            helperText: '$count of $total gates',
            border: const OutlineInputBorder(),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _GateTile extends StatelessWidget {
  const _GateTile({required this.gate});

  final ZtlGate gate;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE3F1EA),
          foregroundColor: const Color(0xFF0B6B4B),
          child: Text(gate.id.toString()),
        ),
        title: Text(gate.name),
        subtitle: Text(
          gate.reference.isEmpty
              ? '${gate.latitude.toStringAsFixed(5)}, ${gate.longitude.toStringAsFixed(5)}'
              : gate.reference,
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _ApiErrorPanel extends StatelessWidget {
  const _ApiErrorPanel({
    required this.controller,
    required this.message,
    required this.onRetry,
  });

  final TextEditingController controller;
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Can’t reach the ZTL API',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        const Text('Start the backend, then connect again.'),
        const SizedBox(height: 14),
        _ConnectionBar(controller: controller, onConnect: onRetry),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(message),
          ),
        ),
      ],
    );
  }
}

class ZtlMapPainter extends CustomPainter {
  ZtlMapPainter({
    required this.polygon,
    required this.gates,
    required this.bounds,
  });

  final List<GeoPoint> polygon;
  final List<ZtlGate> gates;
  final GeoBounds bounds;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFEAF0E9);
    canvas.drawRect(Offset.zero & size, background);

    final gridPaint = Paint()
      ..color = const Color(0xFFD1D8D0)
      ..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      final x = size.width * i / 5;
      final y = size.height * i / 5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (polygon.isEmpty) {
      return;
    }

    final path = Path()
      ..moveTo(_x(polygon.first, size), _y(polygon.first, size));
    for (final point in polygon.skip(1)) {
      path.lineTo(_x(point, size), _y(point, size));
    }
    path.close();

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

    for (final gate in gates) {
      final center = Offset(_x(gate.point, size), _y(gate.point, size));
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

  double _x(GeoPoint point, Size size) {
    final available = math.max(bounds.east - bounds.west, 0.000001);
    return 18 + ((point.longitude - bounds.west) / available) * (size.width - 36);
  }

  double _y(GeoPoint point, Size size) {
    final available = math.max(bounds.north - bounds.south, 0.000001);
    return 18 + ((bounds.north - point.latitude) / available) * (size.height - 36);
  }

  @override
  bool shouldRepaint(covariant ZtlMapPainter oldDelegate) {
    return oldDelegate.polygon != polygon ||
        oldDelegate.gates != gates ||
        oldDelegate.bounds != bounds;
  }
}

class ZtlApiClient {
  ZtlApiClient(String baseUrl) : baseUrl = _cleanBaseUrl(baseUrl);

  final String baseUrl;

  static String _cleanBaseUrl(String value) {
    return value.trim().replaceFirst(RegExp(r'/$'), '');
  }

  Future<ZtlDashboardData> loadDashboard() async {
    final responses = await Future.wait([
      _getJson('/api/ztl/centro-notturna'),
      _getJson('/api/ztl/centro-notturna/area'),
      _getJson('/api/ztl/centro-notturna/gates'),
    ]).timeout(const Duration(seconds: 8));

    return ZtlDashboardData.fromJson(
      responses[0] as Map<String, dynamic>,
      responses[1] as Map<String, dynamic>,
      responses[2] as Map<String, dynamic>,
    );
  }

  Future<dynamic> _getJson(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('GET $path returned ${response.statusCode}.');
    }
    return jsonDecode(response.body);
  }
}

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ZtlDashboardData {
  ZtlDashboardData({
    required this.summary,
    required this.areaPolygon,
    required this.gates,
  });

  final ZtlSummary summary;
  final List<GeoPoint> areaPolygon;
  final List<ZtlGate> gates;

  factory ZtlDashboardData.empty() {
    return ZtlDashboardData(
      summary: ZtlSummary(
        name: 'ZTL Centro Storico Notturna',
        city: 'Roma',
        isActive: false,
        note: '',
        gateCount: 0,
        bounds: const GeoBounds(west: 0, south: 0, east: 1, north: 1),
      ),
      areaPolygon: const [],
      gates: const [],
    );
  }

  factory ZtlDashboardData.fromJson(
    Map<String, dynamic> summaryJson,
    Map<String, dynamic> areaJson,
    Map<String, dynamic> gatesJson,
  ) {
    final feature =
        (areaJson['features'] as List<dynamic>).first as Map<String, dynamic>;
    final geometry = feature['geometry'] as Map<String, dynamic>;
    final rings = geometry['coordinates'] as List<dynamic>;
    final firstRing = rings.first as List<dynamic>;

    return ZtlDashboardData(
      summary: ZtlSummary.fromJson(summaryJson),
      areaPolygon: [
        for (final coordinate in firstRing)
          GeoPoint.fromCoordinates(coordinate as List<dynamic>),
      ],
      gates: [
        for (final gate in gatesJson['gates'] as List<dynamic>)
          ZtlGate.fromJson(gate as Map<String, dynamic>),
      ],
    );
  }
}

class ZtlSummary {
  ZtlSummary({
    required this.name,
    required this.city,
    required this.isActive,
    required this.note,
    required this.gateCount,
    required this.bounds,
  });

  final String name;
  final String city;
  final bool isActive;
  final String note;
  final int gateCount;
  final GeoBounds bounds;

  factory ZtlSummary.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as Map<String, dynamic>;
    final summary = json['summary'] as Map<String, dynamic>;
    return ZtlSummary(
      name: json['name'] as String,
      city: json['city'] as String,
      isActive: status['isActive'] as bool,
      note: status['note'] as String,
      gateCount: summary['gateCount'] as int,
      bounds: GeoBounds.fromJson(summary['bounds'] as Map<String, dynamic>),
    );
  }
}

class ZtlGate {
  ZtlGate({
    required this.id,
    required this.name,
    required this.reference,
    required this.latitude,
    required this.longitude,
  });

  final int id;
  final String name;
  final String reference;
  final double latitude;
  final double longitude;

  GeoPoint get point => GeoPoint(latitude: latitude, longitude: longitude);

  factory ZtlGate.fromJson(Map<String, dynamic> json) {
    return ZtlGate(
      id: json['id'] as int,
      name: json['name'] as String,
      reference: json['reference'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}

class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  factory GeoPoint.fromCoordinates(List<dynamic> coordinates) {
    return GeoPoint(
      longitude: (coordinates[0] as num).toDouble(),
      latitude: (coordinates[1] as num).toDouble(),
    );
  }
}

class GeoBounds {
  const GeoBounds({
    required this.west,
    required this.south,
    required this.east,
    required this.north,
  });

  final double west;
  final double south;
  final double east;
  final double north;

  factory GeoBounds.fromJson(Map<String, dynamic> json) {
    return GeoBounds(
      west: (json['west'] as num).toDouble(),
      south: (json['south'] as num).toDouble(),
      east: (json['east'] as num).toDouble(),
      north: (json['north'] as num).toDouble(),
    );
  }
}
