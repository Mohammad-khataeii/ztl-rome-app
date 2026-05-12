from __future__ import annotations

import json
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from fastapi import HTTPException

from app.models import CitiesDataset, CityDefinition, SourceReference, ZoneDataset, ZoneDefinition


class ZtlRepository:
    def __init__(self, data_root: Optional[Path] = None) -> None:
        self._data_root = data_root or Path(__file__).resolve().parents[1] / "data"
        cities_path = self._data_root / "cities.json"
        with cities_path.open(encoding="utf-8") as file:
            cities_raw = json.load(file)
        cities_dataset = CitiesDataset.model_validate(cities_raw)
        self._cities = [city for city in cities_dataset.cities if city.enabled]
        self._city_map: Dict[str, CityDefinition] = {city.id: city for city in self._cities}
        self._zones_by_city: Dict[str, List[ZoneDefinition]] = {}
        self._zone_map: Dict[Tuple[str, str], ZoneDefinition] = {}

        for city in self._cities:
            dataset_path = self._data_root / city.id / "zones.json"
            with dataset_path.open(encoding="utf-8") as file:
                zone_raw = json.load(file)
            zone_dataset = ZoneDataset.model_validate(zone_raw)
            self._zones_by_city[city.id] = zone_dataset.zones
            for zone in zone_dataset.zones:
                self._zone_map[(city.id, zone.zone_id)] = zone

    def list_cities(self) -> List[CityDefinition]:
        return self._cities

    def get_city(self, city_id: str) -> CityDefinition:
        city = self._city_map.get(city_id)
        if city is None:
            raise HTTPException(status_code=404, detail=f"Unknown city '{city_id}'.")
        return city

    def list_zones(self, city_id: str) -> List[ZoneDefinition]:
        self.get_city(city_id)
        return self._zones_by_city.get(city_id, [])

    def get_zone(self, city_id: str, zone_id: str) -> ZoneDefinition:
        self.get_city(city_id)
        zone = self._zone_map.get((city_id, zone_id))
        if zone is None:
            raise HTTPException(status_code=404, detail=f"Unknown zone '{zone_id}'.")
        return zone

    def get_rome_zone(self, zone_id: str) -> ZoneDefinition:
        return self.get_zone("rome", zone_id)

    def get_area_geojson(self, city_id: str, zone_id: str) -> dict:
        zone = self.get_zone(city_id, zone_id)
        if not zone.geometry.area_file:
            raise HTTPException(
                status_code=404,
                detail=f"Area geometry unavailable for '{zone_id}'.",
            )
        return self._load_geojson(city_id, zone.geometry.area_file)

    def get_gates_geojson(self, city_id: str, zone_id: str) -> dict:
        zone = self.get_zone(city_id, zone_id)
        if not zone.geometry.gates_file:
            raise HTTPException(
                status_code=404,
                detail=f"Gate geometry unavailable for '{zone_id}'.",
            )
        return self._load_geojson(city_id, zone.geometry.gates_file)

    def get_bounds(self, city_id: str, zone_id: str) -> Optional[dict]:
        zone = self.get_zone(city_id, zone_id)
        if not zone.geometry.area_file:
            return None
        geojson = self._load_geojson(city_id, zone.geometry.area_file)
        coordinates = self._collect_coordinates(geojson)
        if not coordinates:
            return None
        longitudes = [item[0] for item in coordinates]
        latitudes = [item[1] for item in coordinates]
        return {
            "west": min(longitudes),
            "south": min(latitudes),
            "east": max(longitudes),
            "north": max(latitudes),
        }

    def list_sources(self, city_id: Optional[str] = None) -> List[SourceReference]:
        deduped = {}
        zone_groups = [self.list_zones(city_id)] if city_id else self._zones_by_city.values()
        for zone_list in zone_groups:
            for zone in zone_list:
                for source in zone.sources:
                    deduped[str(source.url)] = source
        return list(deduped.values())

    def _load_geojson(self, city_id: str, filename: str) -> dict:
        path = self._data_root / city_id / "geojson" / filename
        with path.open(encoding="utf-8") as file:
            return json.load(file)

    def _collect_coordinates(self, geojson: dict) -> List[List[float]]:
        points: List[List[float]] = []
        for feature in geojson.get("features", []):
            geometry = feature.get("geometry") or {}
            geometry_type = geometry.get("type")
            coordinates = geometry.get("coordinates")
            if geometry_type == "Polygon":
                for ring in coordinates or []:
                    points.extend(ring)
            elif geometry_type == "MultiPolygon":
                for polygon in coordinates or []:
                    for ring in polygon:
                        points.extend(ring)
            elif geometry_type == "Point" and coordinates:
                points.append(coordinates)
        return points
