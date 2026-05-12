import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ztl_rome/core/api/api_client.dart';
import 'package:ztl_rome/core/errors/app_error.dart';
import 'package:ztl_rome/features/city/data/city_api.dart';
import 'package:ztl_rome/features/ztl/data/ztl_api.dart';
import 'package:ztl_rome/features/ztl_map/data/map_bundle_api.dart';

void main() {
  test('fetches enabled cities from API', () async {
    final client = ApiClient(
      baseUrl: 'https://example.com',
      client: MockClient((request) async {
        return http.Response(
          '{"cities":[{"id":"rome","name":"Rome","country":"Italy","timezone":"Europe/Rome","center":{"latitude":41.9028,"longitude":12.4964},"defaultZoom":12,"enabled":true,"supportedStatus":"partial","sourceSummary":"Roma Mobilita official pages","lastVerified":"2026-05-12","geometryStatus":{"hasAnyGeometry":true,"missingGeometryReason":"Only one zone has geometry."}}]}',
          200,
        );
      }),
    );

    final api = CityApi(client);
    final cities = await api.fetchCities();

    expect(cities, hasLength(1));
    expect(cities.single.id, 'rome');
  });

  test('fetches city zones from API', () async {
    final client = ApiClient(
      baseUrl: 'https://example.com',
      client: MockClient((request) async {
        expect(request.url.path, '/api/cities/milan/ztl/zones');
        return http.Response(
          '{"zones":[{"id":"milan-area-c","zoneId":"milan-area-c","cityId":"milan","name":"Area C","city":"Milan","type":"paid_access","timezone":"Europe/Rome","currentStatus":{"isActive":true,"checkedAt":"2026-05-12T08:00:00+02:00","reason":"Mon-Fri 07:30-19:30, excluding holidays.","nextChangeAt":"2026-05-12T19:30:00+02:00","confidence":"official"},"schedule":{"humanReadableIt":"Lun-ven 07:30-19:30","humanReadableEn":"Mon-Fri 07:30-19:30","rules":[],"exclusions":["Italian public holidays."]},"restrictions":{"vehicleClasses":["cars"],"knownExemptions":["Official exemptions apply"],"disabledPermitNote":"Check Comune di Milano guidance.","electricVehicleNote":"Vehicle eligibility depends on official rules.","motorcyclesCiclomotoriNote":"Check official Milano access rules."},"mapStyle":{"fillColorKey":"paid_fill","strokeColorKey":"paid_stroke","priority":3,"visibleByDefault":true},"geometry":{"hasArea":false,"hasGates":false,"areaEndpoint":null,"gatesEndpoint":null,"quality":"missing","bounds":null},"sources":[],"disclaimer":"Official rules may change. Check the official city source before entering."}]}',
          200,
        );
      }),
    );

    final api = ZtlApi(client);
    final zones = await api.fetchZones('milan');

    expect(zones, hasLength(1));
    expect(zones.single.zoneId, 'milan-area-c');
  });

  test('fetches city map bundle', () async {
    final client = ApiClient(
      baseUrl: 'https://example.com',
      client: MockClient((request) async {
        expect(request.url.path, '/api/cities/rome/ztl/map');
        return http.Response(
          '{"city":{"id":"rome","name":"Rome","country":"Italy","timezone":"Europe/Rome","center":{"latitude":41.9028,"longitude":12.4964},"defaultZoom":12,"enabled":true,"supportedStatus":"partial","sourceSummary":"Roma Mobilita official pages","lastVerified":"2026-05-12","geometryStatus":{"hasAnyGeometry":true,"missingGeometryReason":"Only one zone has geometry."}},"zones":[],"areas":{"type":"FeatureCollection","features":[]},"gates":{"type":"FeatureCollection","features":[]},"missingGeometryZones":[{"zoneId":"tridente-a1","name":"Tridente A1","reason":"Official geometry is not yet available in the dataset."}]}',
          200,
        );
      }),
    );

    final api = ZtlMapApi(client);
    final bundle = await api.fetchCityMap('rome');

    expect(bundle.city.id, 'rome');
    expect(bundle.missingGeometryZones.single.zoneId, 'tridente-a1');
  });

  test('surfaces clean API errors', () async {
    final client = ApiClient(
      baseUrl: 'https://example.com',
      client: MockClient((request) async {
        return http.Response('{"detail":"Unknown city."}', 404);
      }),
    );

    final api = ZtlApi(client);

    expect(
      () => api.fetchZone('missing', 'missing-zone'),
      throwsA(isA<AppError>()),
    );
  });
}
