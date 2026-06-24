"""
External data endpoints (weather, sea, tides, water quality, transport).
All external HTTP calls are mocked — these tests verify our routing,
snapshot fallback logic, and response schemas, not the external APIs.
"""
from unittest.mock import patch, AsyncMock

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.beach import Beach
from app.models.snapshot import ApiSnapshot

FAKE_WEATHER = {
    "forecasts": [
        {"date": "2026-04-27", "min_temp": 14.0, "max_temp": 24.0,
         "precipitation_prob": 5.0, "wind_speed": 2.0, "wind_direction": "Norte",
         "weather_type_id": 2, "weather_type_desc": "Poucas nuvens"},
    ],
    "global_id_local": 1151200,
}

FAKE_SEA = {
    "forecasts": [
        {"date": "2026-04-27", "wave_height_max": 1.5, "wave_height_min": 0.8,
         "wave_period_max": 8.0, "sea_surface_temp": 16.0},
    ],
    "global_id_local": 1111026,
}

FAKE_TIDES = {
    "station_id": "PT_150505_2",
    "station_name": "Setúbal - Tróia",
    "current_height": 1.47,
    "direction": "rising",
    "observed_at": "2026-04-27T14:23:00+00:00",
    "entries": [],
    "note": "Real-time observation — tide table not available",
}

FAKE_WATER = {
    "station_id": "PTCQ8P",
    "classification": "Excelente",
    "sampled_at": "2024",
    "parameters": {"eea_quality_raw": "1 - Excellent", "season": 2024},
}


class TestWeatherEndpoint:
    async def test_returns_live_forecast(self, client: AsyncClient, beach: Beach):
        with (
            patch("app.api.weather.ipma.fetch_weather_forecast", return_value=FAKE_WEATHER),
            patch("app.api.weather.open_meteo.fetch_weather", return_value=None),
        ):
            r = await client.get("/api/v1/beaches/portinho-da-arrabida/weather")
        assert r.status_code == 200
        data = r.json()
        assert len(data) == 1
        assert data[0]["min_temp"] == 14.0
        assert data[0]["data_source"] == "live"
        assert data[0]["snapshot_at"] is None

    async def test_falls_back_to_snapshot(self, client: AsyncClient, beach: Beach, db: AsyncSession):
        db.add(ApiSnapshot(source="ipma_weather", beach_id=beach.id, data=FAKE_WEATHER))
        await db.commit()

        with patch("app.api.weather.ipma.fetch_weather_forecast", side_effect=Exception("down")):
            r = await client.get("/api/v1/beaches/portinho-da-arrabida/weather")
        assert r.status_code == 200
        assert r.json()[0]["data_source"] == "snapshot"
        assert r.json()[0]["snapshot_at"] is not None

    async def test_503_when_no_snapshot_and_api_down(self, client: AsyncClient, beach: Beach):
        with patch("app.api.weather.ipma.fetch_weather_forecast", side_effect=Exception("down")):
            r = await client.get("/api/v1/beaches/portinho-da-arrabida/weather")
        assert r.status_code == 503

    async def test_404_when_beach_has_no_ipma_id(
        self, client: AsyncClient, db: AsyncSession
    ):
        b = Beach(slug="praia-sem-ipma", name="Praia sem IPMA", lat=38.0, lon=-9.0,
                  geom="SRID=4326;POINT(-9.0 38.0)", flags_available=True)
        db.add(b)
        await db.commit()

        r = await client.get("/api/v1/beaches/praia-sem-ipma/weather")
        assert r.status_code == 404


class TestSeaEndpoint:
    async def test_returns_live_sea_forecast(self, client: AsyncClient, beach: Beach):
        with patch("app.api.weather.ipma.fetch_sea_forecast", return_value=FAKE_SEA):
            r = await client.get("/api/v1/beaches/portinho-da-arrabida/sea")
        assert r.status_code == 200
        data = r.json()
        assert data[0]["wave_height_max"] == 1.5
        assert data[0]["data_source"] == "live"

    async def test_falls_back_to_snapshot(self, client: AsyncClient, beach: Beach, db: AsyncSession):
        db.add(ApiSnapshot(source="ipma_sea", beach_id=beach.id, data=FAKE_SEA))
        await db.commit()

        with patch("app.api.weather.ipma.fetch_sea_forecast", side_effect=Exception("down")):
            r = await client.get("/api/v1/beaches/portinho-da-arrabida/sea")
        assert r.status_code == 200
        assert r.json()[0]["data_source"] == "snapshot"


class TestTidesEndpoint:
    async def test_returns_live_tides(self, client: AsyncClient, beach: Beach):
        with patch("app.api.tides.hidrografico.fetch_current_tide", return_value=FAKE_TIDES):
            r = await client.get("/api/v1/beaches/portinho-da-arrabida/tides")
        assert r.status_code == 200
        body = r.json()
        assert body["station_id"] == "PT_150505_2"
        assert body["current_height"] == 1.47
        assert body["direction"] == "rising"
        assert body["data_source"] == "live"

    async def test_falls_back_to_snapshot(self, client: AsyncClient, beach: Beach, db: AsyncSession):
        db.add(ApiSnapshot(source="tides", beach_id=beach.id, data=FAKE_TIDES))
        await db.commit()

        with patch("app.api.tides.hidrografico.fetch_current_tide", side_effect=Exception("down")):
            r = await client.get("/api/v1/beaches/portinho-da-arrabida/tides")
        assert r.status_code == 200
        assert r.json()["data_source"] == "snapshot"

    async def test_404_when_no_tide_station(self, client: AsyncClient, db: AsyncSession):
        b = Beach(slug="praia-sem-mares", name="Praia sem Marés", lat=38.0, lon=-9.0,
                  geom="SRID=4326;POINT(-9.0 38.0)", flags_available=True)
        db.add(b)
        await db.commit()

        r = await client.get("/api/v1/beaches/praia-sem-mares/tides")
        assert r.status_code == 404


class TestWaterQualityEndpoint:
    async def test_returns_live_quality(self, client: AsyncClient, beach: Beach):
        with patch("app.api.water_quality.eea.fetch_water_quality", return_value=FAKE_WATER):
            r = await client.get("/api/v1/beaches/portinho-da-arrabida/water-quality")
        assert r.status_code == 200
        body = r.json()
        assert body["classification"] == "Excelente"
        assert body["data_source"] == "live"

    async def test_falls_back_to_snapshot(self, client: AsyncClient, beach: Beach, db: AsyncSession):
        db.add(ApiSnapshot(source="water_quality", beach_id=beach.id, data=FAKE_WATER))
        await db.commit()

        with patch("app.api.water_quality.eea.fetch_water_quality", side_effect=Exception("down")):
            r = await client.get("/api/v1/beaches/portinho-da-arrabida/water-quality")
        assert r.status_code == 200
        assert r.json()["data_source"] == "snapshot"

    async def test_returns_unavailable_when_api_and_cache_both_down(
        self, client: AsyncClient, beach: Beach
    ):
        with patch("app.api.water_quality.eea.fetch_water_quality", return_value=None):
            r = await client.get("/api/v1/beaches/portinho-da-arrabida/water-quality")
        assert r.status_code == 200
        body = r.json()
        assert body["data_source"] == "unavailable"
        assert body["classification"] is None

    async def test_404_when_no_eea_station(self, client: AsyncClient, db: AsyncSession):
        b = Beach(slug="praia-sem-eea", name="Praia sem APA", lat=38.0, lon=-9.0,
                  geom="SRID=4326;POINT(-9.0 38.0)", flags_available=True)
        db.add(b)
        await db.commit()

        r = await client.get("/api/v1/beaches/praia-sem-eea/water-quality")
        assert r.status_code == 404


class TestTransportEndpoint:
    async def test_404_when_no_stops(self, client: AsyncClient, beach: Beach):
        r = await client.get("/api/v1/beaches/portinho-da-arrabida/transport")
        assert r.status_code == 404

    async def test_returns_live_departures(self, client: AsyncClient, db: AsyncSession):
        b = Beach(
            slug="praia-com-paragem", name="Praia com Paragem", lat=38.49, lon=-8.95,
            geom="SRID=4326;POINT(-8.95 38.49)", flags_available=True,
            nearby_stop_ids=["12345"],
        )
        db.add(b)
        await db.commit()

        fake_departures = [
            {"route_id": "4601", "route_short_name": "4601", "trip_headsign": "Setúbal",
             "stop_id": "12345", "departure_time": "14:30"},
        ]
        fake_stop = {"stop_id": "12345", "stop_name": "Praia Stop", "lat": 38.49, "lon": -8.95}

        with patch("app.api.transport.carris.fetch_multiple_stops_departures", return_value=fake_departures), \
             patch("app.api.transport.carris.fetch_stop", return_value=fake_stop):
            r = await client.get("/api/v1/beaches/praia-com-paragem/transport")

        assert r.status_code == 200
        body = r.json()
        assert len(body["directions"]) == 1
        assert body["directions"][0]["headsign"] == "Setúbal"
        assert body["directions"][0]["departures"][0]["route_short_name"] == "4601"
        assert body["data_source"] == "live"
