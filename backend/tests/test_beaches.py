"""Beach list and detail endpoint tests."""
from unittest.mock import patch, AsyncMock

import pytest
from httpx import AsyncClient

from app.models.beach import Beach
from app.models.beach_status import BeachStatus
from app.models.user import User


class TestBeachList:
    async def test_list_returns_all_beaches(self, client: AsyncClient, beach: Beach):
        r = await client.get("/api/v1/beaches")
        assert r.status_code == 200
        data = r.json()
        assert len(data) == 1
        assert data[0]["slug"] == "portinho-da-arrabida"

    async def test_list_beach_has_required_fields(self, client: AsyncClient, beach: Beach, beach_status: BeachStatus):
        r = await client.get("/api/v1/beaches")
        assert r.status_code == 200
        item = r.json()[0]
        for field in ("id", "slug", "name", "lat", "lon", "flag_color", "occupancy_level", "active_alerts_count", "activity_level"):
            assert field in item, f"missing field: {field}"

    async def test_list_empty_when_no_beaches(self, client: AsyncClient):
        r = await client.get("/api/v1/beaches")
        assert r.status_code == 200
        assert r.json() == []

    async def test_list_with_location_returns_distance_and_score(self, client: AsyncClient, beach: Beach):
        r = await client.get("/api/v1/beaches?lat=38.484&lon=-8.982")
        assert r.status_code == 200
        item = r.json()[0]
        assert item["distance_km"] is not None
        assert item["recommendation_score"] is not None
        assert item["distance_km"] < 1.0  # very close to the beach coordinates

    async def test_list_without_location_has_no_score(self, client: AsyncClient, beach: Beach):
        r = await client.get("/api/v1/beaches")
        assert r.status_code == 200
        item = r.json()[0]
        assert item["distance_km"] is None
        assert item["recommendation_score"] is None

    async def test_list_sorted_by_proximity_when_location_given(
        self, client: AsyncClient, db, beach: Beach
    ):
        # Add a second beach far away
        far = Beach(
            slug="praia-far", name="Praia Far", lat=41.0, lon=-8.0,
            geom="SRID=4326;POINT(-8.0 41.0)", flags_available=True,
        )
        db.add(far)
        await db.commit()

        # Query from a point near portinho-da-arrabida
        r = await client.get("/api/v1/beaches?lat=38.484&lon=-8.982")
        assert r.status_code == 200
        slugs = [b["slug"] for b in r.json()]
        assert slugs[0] == "portinho-da-arrabida"  # nearest comes first


class TestBeachDetail:
    async def test_get_existing_beach(self, client: AsyncClient, beach: Beach):
        r = await client.get("/api/v1/beaches/portinho-da-arrabida")
        assert r.status_code == 200
        body = r.json()
        assert body["beach"]["slug"] == "portinho-da-arrabida"
        assert "status" in body
        assert "active_alerts" in body

    async def test_get_nonexistent_beach_returns_404(self, client: AsyncClient):
        r = await client.get("/api/v1/beaches/praia-inexistente")
        assert r.status_code == 404

    async def test_detail_includes_live_weather(self, client: AsyncClient, beach: Beach):
        fake_weather = {"forecasts": [{"date": "2026-04-27", "min_temp": 15.0, "max_temp": 25.0,
                                        "precipitation_prob": 5.0, "wind_speed": 2.0,
                                        "wind_direction": "Norte", "weather_type_id": 2,
                                        "weather_type_desc": "Poucas nuvens"}],
                         "global_id_local": 1151200}
        with (
            patch("app.api.beaches.ipma.fetch_weather_forecast", return_value=fake_weather),
            patch("app.api.beaches.open_meteo.fetch_weather", return_value=None),
        ):
            r = await client.get("/api/v1/beaches/portinho-da-arrabida")
        assert r.status_code == 200
        weather = r.json()["weather"]
        assert weather is not None
        assert weather[0]["data_source"] == "live"
        assert weather[0]["min_temp"] == 15.0

    async def test_detail_weather_falls_back_to_snapshot(self, client: AsyncClient, beach: Beach, db):
        from app.models.snapshot import ApiSnapshot
        snap = ApiSnapshot(
            source="ipma_weather",
            beach_id=beach.id,
            data={"forecasts": [{"date": "2026-04-26", "min_temp": 12.0, "max_temp": 20.0,
                                  "precipitation_prob": 10.0, "wind_speed": 1.0,
                                  "wind_direction": "Sul", "weather_type_id": 1,
                                  "weather_type_desc": "Céu limpo"}],
                  "global_id_local": 1151200},
        )
        db.add(snap)
        await db.commit()

        with patch("app.api.beaches.ipma.fetch_weather_forecast", side_effect=Exception("API down")):
            r = await client.get("/api/v1/beaches/portinho-da-arrabida")
        assert r.status_code == 200
        weather = r.json()["weather"]
        assert weather[0]["data_source"] == "snapshot"

    async def test_detail_status_reflects_beach_status(self, client: AsyncClient, beach: Beach, beach_status: BeachStatus):
        r = await client.get("/api/v1/beaches/portinho-da-arrabida")
        assert r.status_code == 200
        status = r.json()["status"]
        assert status["flag_color"] == "green"
        assert status["flag_confidence"] == pytest.approx(0.8)
