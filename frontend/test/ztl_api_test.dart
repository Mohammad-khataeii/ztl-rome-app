import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ztl_rome/core/api/api_client.dart';
import 'package:ztl_rome/core/errors/app_error.dart';
import 'package:ztl_rome/features/ztl/data/ztl_api.dart';

void main() {
  test('fetches list of zones from API', () async {
    final client = ApiClient(
      baseUrl: 'https://example.com',
      client: MockClient((request) async {
        return http.Response(
          '{"zones":[{"id":"centro-storico-notturna","name":"ZTL Centro Storico notturna","city":"Roma","type":"nighttime","timezone":"Europe/Rome","currentStatus":{"isActive":true,"checkedAt":"2026-05-12T23:30:00+02:00","reason":"Fri-Sat 23:00-03:00","nextChangeAt":"2026-05-13T03:00:00+02:00","confidence":"official"},"schedule":{"humanReadableIt":"Ven-sab 23:00-03:00","humanReadableEn":"Fri-Sat 23:00-03:00","rules":[],"exclusions":[]},"restrictions":{"vehicleClasses":["automobili"],"knownExemptions":["Taxi"],"disabledPermitNote":"Disabled","electricVehicleNote":"EV","motorcyclesCiclomotoriNote":"Moto"},"geometry":{"hasArea":false,"hasGates":false,"areaEndpoint":null,"gatesEndpoint":null,"bounds":null},"sources":[],"disclaimer":"Official rules may change. Check Roma Mobilità before entering."}]}',
          200,
        );
      }),
    );

    final api = ZtlApi(client);
    final zones = await api.fetchZones();

    expect(zones, hasLength(1));
    expect(zones.single.currentStatus.isActive, isTrue);
  });

  test('surfaces clean API errors', () async {
    final client = ApiClient(
      baseUrl: 'https://example.com',
      client: MockClient((request) async {
        return http.Response('{"detail":"Unknown zone."}', 404);
      }),
    );

    final api = ZtlApi(client);

    expect(
      () => api.fetchZone('missing'),
      throwsA(isA<AppError>()),
    );
  });
}
