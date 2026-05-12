import 'package:flutter/material.dart';

import '../data/city_models.dart';
import 'widgets/city_chip.dart';

class CitySelector extends StatelessWidget {
  const CitySelector({
    super.key,
    required this.cities,
    required this.selectedCityId,
    required this.onSelected,
  });

  final List<CityModel> cities;
  final String selectedCityId;
  final ValueChanged<CityModel> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final city in cities)
          CityChip(
            label: city.name,
            selected: city.id == selectedCityId,
            onTap: () => onSelected(city),
          ),
      ],
    );
  }
}
