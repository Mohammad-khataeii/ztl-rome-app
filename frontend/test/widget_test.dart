import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ztl_rome/core/api/api_client.dart';
import 'package:ztl_rome/core/widgets/error_state.dart';
import 'package:ztl_rome/core/widgets/loading_state.dart';
import 'package:ztl_rome/features/ztl/data/ztl_api.dart';
import 'package:ztl_rome/features/ztl/data/ztl_models.dart';
import 'package:ztl_rome/features/ztl/data/ztl_repository.dart';
import 'package:ztl_rome/features/ztl/presentation/home_page.dart';
import 'package:ztl_rome/features/ztl/presentation/zone_detail_page.dart';
import 'package:ztl_rome/features/ztl/presentation/widgets/gate_list.dart';
import 'package:ztl_rome/features/ztl/presentation/widgets/status_timeline.dart';
import 'package:ztl_rome/features/ztl/presentation/widgets/zone_card.dart';
import 'package:ztl_rome/features/ztl/presentation/widgets/zone_map_panel.dart';

void main() {
  testWidgets('loading state shows progress', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoadingState()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading Rome ZTL data...'), findsOneWidget);
  });

  testWidgets('error state shows retry action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ErrorState(
          title: 'Error',
          message: 'Something went wrong.',
          actionLabel: 'Retry',
          onAction: () {},
        ),
      ),
    );

    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('zone card shows active label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ZoneCard(
          zone: _sampleZone(isActive: true),
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Active now'), findsOneWidget);
  });

  testWidgets('status timeline renders next change', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: StatusTimeline(zone: _sampleZone(isActive: false))),
    );

    expect(find.textContaining('Next change:'), findsOneWidget);
  });

  testWidgets('gate list shows empty state gracefully', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: GateList(gates: [])),
    );

    expect(find.textContaining('No official gate list'), findsOneWidget);
  });

  testWidgets('zone map panel handles missing geometry', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ZoneMapPanel(
          zone: _sampleZone(isActive: false),
          area: null,
          gates: null,
        ),
      ),
    );

    expect(find.text('Boundary unavailable'), findsOneWidget);
  });

  testWidgets('home page renders multiple zones', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          repository: FakeZtlRepository(),
          debugBaseUrl: 'http://127.0.0.1:8000',
          isDebugFallback: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rome ZTL zones'), findsOneWidget);
    expect(find.text('ZTL Centro Storico notturna'), findsWidgets);
    expect(find.text('ZTL Tridente A1'), findsOneWidget);
  });

  testWidgets('zone detail page renders sources and restrictions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ZoneDetailPage(
          repository: FakeZtlRepository(),
          initialZone: _sampleZone(isActive: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Restrictions and exemptions'), findsOneWidget);
    expect(find.text('Official sources'), findsOneWidget);
  });
}

class FakeZtlRepository extends ZtlRepository {
  FakeZtlRepository()
      : super(
          ZtlApi(
            ApiClient(baseUrl: 'https://example.com'),
          ),
        );

  @override
  Future<List<ZtlZone>> loadZones() async {
    return [
      _sampleZone(isActive: true),
      _sampleTridenteZone(),
    ];
  }

  @override
  Future<ZoneBundle> loadZoneBundle(String zoneId) async {
    return ZoneBundle(
      zone: _sampleZone(isActive: false),
      area: null,
      gates: null,
    );
  }
}

ZtlZone _sampleZone({required bool isActive}) {
  return ZtlZone(
    id: 'centro-storico-notturna',
    name: 'ZTL Centro Storico notturna',
    city: 'Roma',
    type: 'nighttime',
    timezone: 'Europe/Rome',
    currentStatus: ZoneCurrentStatus(
      isActive: isActive,
      checkedAt: DateTime.parse('2026-05-12T22:30:00+02:00'),
      reason: isActive ? 'Fri-Sat 23:00-03:00' : 'Outside scheduled hours.',
      nextChangeAt: DateTime.parse('2026-05-16T23:00:00+02:00'),
      confidence: 'official',
    ),
    schedule: ZoneSchedule(
      humanReadableIt: 'Ven-sab 23:00-03:00',
      humanReadableEn: 'Fri-Sat 23:00-03:00',
      rules: const [
        ZoneScheduleRule(
          id: 'night',
          labelIt: 'Ven-sab 23:00-03:00',
          labelEn: 'Fri-Sat 23:00-03:00',
          weekdays: [4, 5],
          startTime: '23:00',
          endTime: '03:00',
          holidayPolicy: 'exclude',
          activeMonths: null,
          excludedMonths: [8],
          sourceTitles: ['ZTL in Centro'],
        ),
      ],
      exclusions: const ['Italian public holidays.', 'Night ZTL suspended in August.'],
    ),
    restrictions: const ZoneRestrictions(
      vehicleClasses: ['automobili'],
      knownExemptions: ['Taxi'],
      disabledPermitNote: 'Disabled permit note',
      electricVehicleNote: 'EV note',
      motorcyclesCiclomotoriNote: 'Motorcycles note',
    ),
    geometry: const ZoneGeometry(
      hasArea: false,
      hasGates: false,
      areaEndpoint: null,
      gatesEndpoint: null,
      bounds: null,
    ),
    sources: const [
      ZoneSource(
        title: 'ZTL in Centro',
        url: 'https://romamobilita.it/muoversi-a-roma/ztl-in-centro/',
        publisher: 'Roma Servizi per la Mobilità',
        lastVerified: '2026-05-12',
      ),
    ],
    disclaimer: 'Official rules may change. Check Roma Mobilità before entering.',
  );
}

ZtlZone _sampleTridenteZone() {
  return ZtlZone(
    id: 'tridente-a1',
    name: 'ZTL Tridente A1',
    city: 'Roma',
    type: 'daytime',
    timezone: 'Europe/Rome',
    currentStatus: ZoneCurrentStatus(
      isActive: false,
      checkedAt: DateTime.parse('2026-05-12T10:00:00+02:00'),
      reason: 'Outside scheduled hours.',
      nextChangeAt: DateTime.parse('2026-05-13T06:30:00+02:00'),
      confidence: 'official',
    ),
    schedule: ZoneSchedule(
      humanReadableIt: 'Lun-ven 06:30-19:00',
      humanReadableEn: 'Mon-Fri 06:30-19:00',
      rules: const [],
      exclusions: const ['Italian public holidays.'],
    ),
    restrictions: const ZoneRestrictions(
      vehicleClasses: ['automobili', 'motocicli'],
      knownExemptions: ['Taxi'],
      disabledPermitNote: 'Disabled permit note',
      electricVehicleNote: 'EV note',
      motorcyclesCiclomotoriNote: 'Motorcycles need A1 authorization.',
    ),
    geometry: const ZoneGeometry(
      hasArea: false,
      hasGates: false,
      areaEndpoint: null,
      gatesEndpoint: null,
      bounds: null,
    ),
    sources: const [
      ZoneSource(
        title: 'ZTL in Centro',
        url: 'https://romamobilita.it/muoversi-a-roma/ztl-in-centro/',
        publisher: 'Roma Servizi per la Mobilità',
        lastVerified: '2026-05-12',
      ),
    ],
    disclaimer: 'Official rules may change. Check Roma Mobilità before entering.',
  );
}
