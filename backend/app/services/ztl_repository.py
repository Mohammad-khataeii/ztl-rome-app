from __future__ import annotations

import json
from pathlib import Path
from typing import Dict, List, Optional

from fastapi import HTTPException

from app.models import SourceReference, ZoneDataset, ZoneDefinition


class ZtlRepository:
    def __init__(self, data_dir: Optional[Path] = None) -> None:
        self._data_dir = data_dir or Path(__file__).resolve().parents[1] / "data" / "rome"
        dataset_path = self._data_dir / "zones.json"
        with dataset_path.open(encoding="utf-8") as file:
            raw_data = json.load(file)
        dataset = ZoneDataset.model_validate(raw_data)
        self._zones = dataset.zones
        self._zone_map: Dict[str, ZoneDefinition] = {zone.id: zone for zone in dataset.zones}
        if len(self._zone_map) != len(self._zones):
            raise ValueError("Duplicate zone identifiers found in zones.json")

    def list_zones(self) -> List[ZoneDefinition]:
        return self._zones

    def get_zone(self, zone_id: str) -> ZoneDefinition:
        zone = self._zone_map.get(zone_id)
        if zone is None:
            raise HTTPException(status_code=404, detail=f"Unknown zone '{zone_id}'.")
        return zone

    def get_area_geojson(self, zone_id: str) -> dict:
        zone = self.get_zone(zone_id)
        if not zone.geometry.area_file:
            raise HTTPException(
                status_code=404,
                detail=f"Area geometry unavailable for '{zone_id}'.",
            )
        return self._load_geojson(zone.geometry.area_file)

    def get_gates_geojson(self, zone_id: str) -> dict:
        zone = self.get_zone(zone_id)
        if not zone.geometry.gates_file:
            raise HTTPException(
                status_code=404,
                detail=f"Gate geometry unavailable for '{zone_id}'.",
            )
        return self._load_geojson(zone.geometry.gates_file)

    def get_bounds(self, zone_id: str) -> Optional[dict]:
        zone = self.get_zone(zone_id)
        if not zone.geometry.area_file:
            return None
        geojson = self._load_geojson(zone.geometry.area_file)
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

    def list_sources(self) -> List[SourceReference]:
        deduped = {}
        for zone in self._zones:
            for source in zone.sources:
                deduped[str(source.url)] = source
        return list(deduped.values())

    def _load_geojson(self, filename: str) -> dict:
        with (self._data_dir / "geojson" / filename).open(encoding="utf-8") as file:
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
