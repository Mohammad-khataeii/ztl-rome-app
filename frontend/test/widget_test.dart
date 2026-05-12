import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ztl_rome/core/api/api_client.dart';
import 'package:ztl_rome/core/widgets/error_state.dart';
import 'package:ztl_rome/core/widgets/loading_state.dart';
import 'package:ztl_rome/features/city/data/city_models.dart';
import 'package:ztl_rome/features/city/presentation/city_selector.dart';
import 'package:ztl_rome/features/ztl/data/ztl_api.dart';
import 'package:ztl_rome/features/ztl/data/ztl_models.dart';
import 'package:ztl_rome/features/ztl/data/ztl_repository.dart';
import 'package:ztl_rome/features/ztl/presentation/zone_detail_page.dart';
import 'package:ztl_rome/features/ztl/presentation/widgets/zone_card.dart';
import 'package:ztl_rome/features/ztl_map/data/map_bundle_models.dart';
import 'package:ztl_rome/features/ztl_map/presentation/widgets/missing_geometry_panel.dart';

void main() {
  testWidgets('loading state shows progress', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoadingState()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading ZTL data...'), findsOneWidget);
  });

  testWidgets('error state shows retry action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ErrorState(
          title: 'Error',
          message: 'Something went wrong.',
          actionLabel: 'Retry',
          onAction: () {},
          debugDetails: 'GET http://127.0.0.1:8000/api/cities/rome/ztl/map failed',
        ),
      ),
    );

    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('/api/cities/rome/ztl/map'), findsOneWidget);
  });

  testWidgets('city selector renders supported cities', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CitySelector(
            cities: const [
              CityModel(
                id: 'rome',
                name: 'Rome',
                country: 'Italy',
                timezone: 'Europe/Rome',
                centerLatitude: 41.9028,
                centerLongitude: 12.4964,
                defaultZoom: 12,
                enabled: true,
                supportedStatus: 'partial',
                sourceSummary: 'Roma Mobilita',
                lastVerified: '2026-05-12',
                hasAnyGeometry: true,
                missingGeometryReason: 'Only one zone has geometry.',
              ),
              CityModel(
                id: 'milan',
                name: 'Milan',
                country: 'Italy',
                timezone: 'Europe/Rome',
                centerLatitude: 45.4642,
                centerLongitude: 9.19,
                defaultZoom: 11,
                enabled: true,
                supportedStatus: 'schedule_only',
                sourceSummary: 'Comune di Milano',
                lastVerified: '2026-05-12',
                hasAnyGeometry: false,
                missingGeometryReason: 'Geometry pending.',
              ),
              CityModel(
                id: 'florence',
                name: 'Florence',
                country: 'Italy',
                timezone: 'Europe/Rome',
                centerLatitude: 43.7696,
                centerLongitude: 11.2558,
                defaultZoom: 12,
                enabled: true,
                supportedStatus: 'schedule_only',
                sourceSummary: 'Comune di Firenze',
                lastVerified: '2026-05-12',
                hasAnyGeometry: false,
                missingGeometryReason: 'Geometry pending.',
              ),
            ],
            selectedCityId: 'rome',
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Rome'), findsOneWidget);
    expect(find.text('Milan'), findsOneWidget);
    expect(find.text('Florence'), findsOneWidget);
  });

  testWidgets('missing geometry panel appears for schedule-only cities', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MissingGeometryPanel(
            city: const CityModel(
              id: 'milan',
              name: 'Milan',
              country: 'Italy',
              timezone: 'Europe/Rome',
              centerLatitude: 45.4642,
              centerLongitude: 9.19,
              defaultZoom: 11,
              enabled: true,
              supportedStatus: 'schedule_only',
              sourceSummary: 'Comune di Milano',
              lastVerified: '2026-05-12',
              hasAnyGeometry: false,
              missingGeometryReason: 'Geometry pending.',
            ),
            zones: const [
              MissingGeometryZone(
                zoneId: 'milan-area-c',
                name: 'Area C',
                reason: 'Official geometry is not yet available in the dataset.',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Geometry unavailable'), findsOneWidget);
    expect(find.text('Area C'), findsOneWidget);
  });

  testWidgets('zone card shows active label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ZoneCard(
          zone: sampleZone(isActive: true),
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Active now'), findsOneWidget);
  });

  testWidgets('zone detail page renders sources and restrictions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ZoneDetailPage(
                      repository: FakeZtlRepository(),
                      initialZone: sampleZone(isActive: false),
                    ),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Restrictions and exemptions'), findsOneWidget);
    expect(find.text('Official sources'), findsOneWidget);
  });
}

class FakeZtlRepository extends ZtlRepository {
  FakeZtlRepository() : super(ZtlApi(ApiClient(baseUrl: 'https://example.com')));

  @override
  Future<ZoneBundle> loadZoneBundle(String cityId, String zoneId) async {
    return ZoneBundle(
      zone: sampleZone(isActive: false),
      area: null,
      gates: null,
    );
  }
}

ZtlZone sampleZone({required bool isActive}) {
  return ZtlZone(
    id: 'centro-storico-notturna',
    zoneId: 'centro-storico-notturna',
    cityId: 'rome',
    name: 'Centro Storico notturna',
    city: 'Rome',
    type: 'nighttime',
    timezone: 'Europe/Rome',
    currentStatus: ZoneCurrentStatus(
      isActive: isActive,
      checkedAt: DateTime.parse('2026-05-12T22:30:00+02:00'),
      reason: isActive ? 'Fri-Sat 23:00-03:00' : 'Outside scheduled hours.',
      nextChangeAt: DateTime.parse('2026-05-16T23:00:00+02:00'),
      confidence: 'official',
    ),
    schedule: const ZoneSchedule(
      humanReadableIt: 'Ven-sab 23:00-03:00',
      humanReadableEn: 'Fri-Sat 23:00-03:00',
      rules: [
        ZoneScheduleRule(
          id: 'night',
          labelIt: 'Ven-sab 23:00-03:00',
          labelEn: 'Fri-Sat 23:00-03:00',
          weekdays: [4, 5],
          startTime: '23:00',
          endTime: '03:00',
        ),
      ],
      exclusions: ['Italian public holidays.', 'Night ZTL suspended in August.'],
    ),
    restrictions: const ZoneRestrictions(
      vehicleClasses: ['cars'],
      knownExemptions: ['Taxi'],
      disabledPermitNote: 'Disabled permits follow official city rules.',
      electricVehicleNote: 'Check the official city source for EV access.',
      motorcyclesCiclomotoriNote: 'Check official motorcycle rules before entering.',
    ),
    mapStyle: const ZoneMapStyle(
      fillColorKey: 'night_fill',
      strokeColorKey: 'night_stroke',
      priority: 2,
      visibleByDefault: true,
    ),
    geometry: const ZoneGeometry(
      hasArea: false,
      hasGates: false,
      areaEndpoint: null,
      gatesEndpoint: null,
      quality: 'missing',
      bounds: null,
    ),
    sources: const [
      ZoneSource(
        title: 'ZTL in Centro',
        url: 'https://romamobilita.it/muoversi-a-roma/ztl-in-centro/',
        publisher: 'Roma Mobilita',
        lastVerified: '2026-05-12',
      ),
    ],
    disclaimer: 'Official rules may change. Check Roma Mobilita before entering.',
  );
}
