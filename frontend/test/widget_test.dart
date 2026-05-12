import 'package:flutter_test/flutter_test.dart';

import 'package:ztl_rome/main.dart';

void main() {
  testWidgets('shows ZTL dashboard data', (WidgetTester tester) async {
    await tester.pumpWidget(
      ZtlRomeApp(initialDashboardFuture: Future.value(_sampleDashboard())),
    );
    await tester.pump();

    expect(find.text('ZTL Rome'), findsOneWidget);
    expect(find.text('ZTL Centro Storico Notturna'), findsOneWidget);
    expect(find.text('1 gates'), findsOneWidget);
    expect(find.text('Largo dei Fiorentini'), findsOneWidget);
  });
}

ZtlDashboardData _sampleDashboard() {
  return ZtlDashboardData(
    summary: ZtlSummary(
      name: 'ZTL Centro Storico Notturna',
      city: 'Roma',
      isActive: false,
      note: 'Always confirm official notices before driving.',
      gateCount: 1,
      bounds: const GeoBounds(
        west: 12.464,
        south: 41.890,
        east: 12.489,
        north: 41.913,
      ),
    ),
    areaPolygon: const [
      GeoPoint(latitude: 41.890, longitude: 12.464),
      GeoPoint(latitude: 41.913, longitude: 12.464),
      GeoPoint(latitude: 41.913, longitude: 12.489),
      GeoPoint(latitude: 41.890, longitude: 12.489),
    ],
    gates: [
      ZtlGate(
        id: 8,
        name: 'Largo dei Fiorentini',
        reference: 'Lungotevere dei Sangallo',
        latitude: 41.89914,
        longitude: 12.46478,
      ),
    ],
  );
}
