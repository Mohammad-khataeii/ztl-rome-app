import 'package:flutter_test/flutter_test.dart';

import 'package:ztl_rome/features/ztl/data/ztl_models.dart';

void main() {
  test('parses zone model with optional geometry', () {
    final zone = ZtlZone.fromJson({
      'id': 'tridente-a1',
      'name': 'ZTL Tridente A1',
      'city': 'Roma',
      'type': 'daytime',
      'timezone': 'Europe/Rome',
      'currentStatus': {
        'isActive': false,
        'checkedAt': '2026-05-12T10:00:00+02:00',
        'reason': 'Outside scheduled hours.',
        'nextChangeAt': '2026-05-13T06:30:00+02:00',
        'confidence': 'official',
      },
      'schedule': {
        'humanReadableIt': 'Lun-ven 06:30-19:00',
        'humanReadableEn': 'Mon-Fri 06:30-19:00',
        'rules': [],
        'exclusions': ['Italian public holidays.'],
      },
      'restrictions': {
        'vehicleClasses': ['automobili', 'motocicli'],
        'knownExemptions': ['Taxi'],
        'disabledPermitNote': 'Disabled permit note',
        'electricVehicleNote': 'EV note',
        'motorcyclesCiclomotoriNote': 'Moto note',
      },
      'geometry': {
        'hasArea': false,
        'hasGates': false,
        'areaEndpoint': null,
        'gatesEndpoint': null,
        'bounds': null,
      },
      'sources': [
        {
          'title': 'ZTL in Centro',
          'url': 'https://romamobilita.it/muoversi-a-roma/ztl-in-centro/',
          'publisher': 'Roma Servizi per la Mobilità',
          'lastVerified': '2026-05-12',
        },
      ],
      'disclaimer': 'Official rules may change. Check Roma Mobilità before entering.',
    });

    expect(zone.id, 'tridente-a1');
    expect(zone.geometry.hasArea, isFalse);
    expect(zone.sources.single.publisher, 'Roma Servizi per la Mobilità');
  });

  test('parses multipolygon geojson without crashing', () {
    final collection = GeoJsonFeatureCollection.fromJson({
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'MultiPolygon',
            'coordinates': [
              [
                [
                  [12.4, 41.8],
                  [12.5, 41.8],
                  [12.5, 41.9],
                  [12.4, 41.8],
                ],
              ],
            ],
          },
          'properties': {},
        },
      ],
    });

    expect(collection.features.single.toRings(), isNotEmpty);
  });
}
