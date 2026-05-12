import 'package:flutter_test/flutter_test.dart';

import 'package:ztl_rome/features/city/data/city_models.dart';
import 'package:ztl_rome/features/ztl/data/ztl_models.dart';
import 'package:ztl_rome/features/ztl_map/data/map_bundle_models.dart';

void main() {
  test('parses city model', () {
    final city = CityModel.fromJson({
      'id': 'rome',
      'name': 'Rome',
      'country': 'Italy',
      'timezone': 'Europe/Rome',
      'center': {'latitude': 41.9028, 'longitude': 12.4964},
      'defaultZoom': 12,
      'enabled': true,
      'supportedStatus': 'partial',
      'sourceSummary': 'Roma Mobilita official pages',
      'lastVerified': '2026-05-12',
      'geometryStatus': {
        'hasAnyGeometry': true,
        'missingGeometryReason': 'Only one Rome zone has geometry.',
      },
    });

    expect(city.id, 'rome');
    expect(city.hasAnyGeometry, isTrue);
    expect(city.centerLatitude, 41.9028);
  });

  test('parses zone model with optional geometry metadata', () {
    final zone = ZtlZone.fromJson({
      'id': 'milan-area-c',
      'zoneId': 'milan-area-c',
      'cityId': 'milan',
      'name': 'Area C',
      'city': 'Milan',
      'type': 'paid_access',
      'timezone': 'Europe/Rome',
      'currentStatus': {
        'isActive': true,
        'checkedAt': '2026-05-12T08:00:00+02:00',
        'reason': 'Mon-Fri 07:30-19:30, excluding holidays.',
        'nextChangeAt': '2026-05-12T19:30:00+02:00',
        'confidence': 'official',
      },
      'schedule': {
        'humanReadableIt': 'Lun-ven 07:30-19:30',
        'humanReadableEn': 'Mon-Fri 07:30-19:30',
        'rules': [],
        'exclusions': ['Italian public holidays.'],
      },
      'restrictions': {
        'vehicleClasses': ['cars'],
        'knownExemptions': ['Official exemptions apply'],
        'disabledPermitNote': 'Check Comune di Milano guidance.',
        'electricVehicleNote': 'Vehicle eligibility depends on official rules.',
        'motorcyclesCiclomotoriNote': 'Check official Milano access rules.',
      },
      'mapStyle': {
        'fillColorKey': 'paid_fill',
        'strokeColorKey': 'paid_stroke',
        'priority': 3,
        'visibleByDefault': true,
      },
      'geometry': {
        'hasArea': false,
        'hasGates': false,
        'areaEndpoint': null,
        'gatesEndpoint': null,
        'quality': 'missing',
        'bounds': null,
      },
      'sources': [
        {
          'title': 'Area C',
          'url': 'https://www.comune.milano.it/argomenti/mobilita/area-c',
          'publisher': 'Comune di Milano',
          'lastVerified': '2026-05-12',
        },
      ],
      'disclaimer': 'Official rules may change. Check the official city source before entering.',
    });

    expect(zone.cityId, 'milan');
    expect(zone.geometry.hasAnyGeometry, isFalse);
    expect(zone.sources.single.publisher, 'Comune di Milano');
  });

  test('parses city map bundle and missing geometry zones', () {
    final bundle = CityMapBundle.fromJson({
      'city': {
        'id': 'rome',
        'name': 'Rome',
        'country': 'Italy',
        'timezone': 'Europe/Rome',
        'center': {'latitude': 41.9028, 'longitude': 12.4964},
        'defaultZoom': 12,
        'enabled': true,
        'supportedStatus': 'partial',
        'sourceSummary': 'Roma Mobilita official pages',
        'lastVerified': '2026-05-12',
        'geometryStatus': {
          'hasAnyGeometry': true,
          'missingGeometryReason': 'Only one Rome zone has geometry.',
        },
      },
      'zones': [
        {
          'id': 'centro-storico-notturna',
          'zoneId': 'centro-storico-notturna',
          'cityId': 'rome',
          'name': 'Centro Storico notturna',
          'city': 'Rome',
          'type': 'nighttime',
          'timezone': 'Europe/Rome',
          'currentStatus': {
            'isActive': true,
            'checkedAt': '2026-05-12T23:30:00+02:00',
            'reason': 'Fri-Sat 23:00-03:00',
            'nextChangeAt': '2026-05-13T03:00:00+02:00',
            'confidence': 'official',
          },
          'schedule': {
            'humanReadableIt': 'Ven-sab 23:00-03:00',
            'humanReadableEn': 'Fri-Sat 23:00-03:00',
            'rules': [],
            'exclusions': [],
          },
          'restrictions': {
            'vehicleClasses': ['cars'],
            'knownExemptions': ['Taxi'],
            'disabledPermitNote': 'Check official rules.',
            'electricVehicleNote': 'Check official rules.',
            'motorcyclesCiclomotoriNote': 'Check official rules.',
          },
          'mapStyle': {
            'fillColorKey': 'night_fill',
            'strokeColorKey': 'night_stroke',
            'priority': 2,
            'visibleByDefault': true,
          },
          'geometry': {
            'hasArea': true,
            'hasGates': true,
            'areaEndpoint': '/api/cities/rome/ztl/zones/centro-storico-notturna/area',
            'gatesEndpoint': '/api/cities/rome/ztl/zones/centro-storico-notturna/gates',
            'quality': 'official',
            'bounds': {'west': 12.47, 'south': 41.89, 'east': 12.5, 'north': 41.91},
          },
          'sources': [],
          'disclaimer': 'Official rules may change.',
        },
      ],
      'areas': {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [12.47, 41.89],
                  [12.5, 41.89],
                  [12.5, 41.91],
                  [12.47, 41.89],
                ],
              ],
            },
            'properties': {
              'zoneId': 'centro-storico-notturna',
            },
          },
        ],
      },
      'gates': {
        'type': 'FeatureCollection',
        'features': [],
      },
      'missingGeometryZones': [
        {
          'zoneId': 'tridente-a1',
          'name': 'Tridente A1',
          'reason': 'Official geometry is not yet available in the dataset.',
        },
      ],
    });

    expect(bundle.zones, hasLength(1));
    expect(bundle.areas.features, hasLength(1));
    expect(bundle.missingGeometryZones.single.zoneId, 'tridente-a1');
  });
}
