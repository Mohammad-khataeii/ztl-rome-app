import 'city_api.dart';
import 'city_models.dart';

class CityRepository {
  const CityRepository(this._api);

  final CityApi _api;

  Future<List<CityModel>> loadCities() => _api.fetchCities();
}
