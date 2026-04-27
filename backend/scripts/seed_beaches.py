"""
Seed script — insert the Arrábida beaches into the database.

IPMA global IDs for the Setúbal region:
  Weather (Setúbal): 1151200  — from distrits-islands.json
  Sea (Arrábida coast): 1111026  — lat 38.65 lon -9.31, from hp-daily-sea-forecast-day0.json

APA station IDs are provisional — verify against
https://sniamb.apambiente.pt/infobathing

Instituto Hidrográfico station IDs — verify against
https://api-features.hidrografico.pt/collections/PortosEstacoes/items

Carris stop IDs — verify against https://api.carrismetropolitana.pt/stops
"""
import asyncio
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from app.core.database import AsyncSessionLocal
from app.models.beach import Beach
from sqlalchemy import select

BEACHES = [
    {
        "slug": "portinho-da-arrabida",
        "name": "Portinho da Arrábida",
        "lat": 38.4839,
        "lon": -8.9821,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "apa_station_id": "PT06ART0002",
        "tide_station_id": "setubal",
        "has_capacity_data": False,
        "max_capacity": 800,
        "nearby_stop_ids": [],
        "flags_available": True,
    },
    {
        "slug": "praia-de-galapinhos",
        "name": "Praia de Galapinhos",
        "lat": 38.4812,
        "lon": -8.9653,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "apa_station_id": "PT06ART0003",
        "tide_station_id": "setubal",
        "has_capacity_data": False,
        "max_capacity": 400,
        "nearby_stop_ids": [],
        "flags_available": True,
    },
    {
        "slug": "praia-de-galapinhos-norte",
        "name": "Praia de Galapinhos Norte",
        "lat": 38.4830,
        "lon": -8.9640,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "apa_station_id": None,
        "tide_station_id": "setubal",
        "has_capacity_data": False,
        "max_capacity": None,
        "nearby_stop_ids": [],
        "flags_available": True,
    },
    {
        "slug": "praia-do-creiro",
        "name": "Praia do Creiro",
        "lat": 38.4724,
        "lon": -8.9456,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "apa_station_id": "PT06ART0004",
        "tide_station_id": "setubal",
        "has_capacity_data": False,
        "max_capacity": 600,
        "nearby_stop_ids": [],
        "flags_available": True,
    },
    {
        "slug": "praia-da-figuerinha",
        "name": "Praia da Figuerinha",
        "lat": 38.4900,
        "lon": -8.9550,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "apa_station_id": "PT06ART0005",
        "tide_station_id": "setubal",
        "has_capacity_data": False,
        "max_capacity": 1200,
        "nearby_stop_ids": [],
        "flags_available": True,
    },
    {
        "slug": "praia-do-outao",
        "name": "Praia do Outão",
        "lat": 38.4983,
        "lon": -8.9256,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "apa_station_id": "PT06ART0006",
        "tide_station_id": "setubal",
        "has_capacity_data": False,
        "max_capacity": 2000,
        "nearby_stop_ids": [],
        "flags_available": True,
    },
    {
        "slug": "praia-de-sesimbra",
        "name": "Praia de Sesimbra",
        "lat": 38.4432,
        "lon": -9.0991,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "apa_station_id": "PT06SES0001",
        "tide_station_id": "cascais",
        "has_capacity_data": False,
        "max_capacity": 3000,
        "nearby_stop_ids": [],
        "flags_available": True,
    },
    {
        "slug": "praia-do-ouro",
        "name": "Praia do Ouro",
        "lat": 38.4389,
        "lon": -9.0916,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "apa_station_id": None,
        "tide_station_id": "cascais",
        "has_capacity_data": False,
        "max_capacity": 500,
        "nearby_stop_ids": [],
        "flags_available": True,
    },
    {
        "slug": "praia-da-california",
        "name": "Praia da Califórnia",
        "lat": 38.4350,
        "lon": -9.0847,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "apa_station_id": None,
        "tide_station_id": "cascais",
        "has_capacity_data": False,
        "max_capacity": 300,
        "nearby_stop_ids": [],
        "flags_available": True,
    },
    {
        "slug": "praia-da-ribeira-do-cavalo",
        "name": "Praia da Ribeira do Cavalo",
        "lat": 38.4680,
        "lon": -9.0280,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "apa_station_id": None,
        "tide_station_id": "setubal",
        "has_capacity_data": False,
        "max_capacity": 200,
        "nearby_stop_ids": [],
        "flags_available": True,
    },
    {
        "slug": "praia-da-figueirinha-norte",
        "name": "Praia da Figueirinha Norte",
        "lat": 38.4930,
        "lon": -8.9490,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "apa_station_id": None,
        "tide_station_id": "setubal",
        "has_capacity_data": False,
        "max_capacity": None,
        "nearby_stop_ids": [],
        "flags_available": True,
    },
    {
        "slug": "praia-de-alpertuche",
        "name": "Praia de Alpertuche",
        "lat": 38.4510,
        "lon": -9.0650,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "apa_station_id": None,
        "tide_station_id": "cascais",
        "has_capacity_data": False,
        "max_capacity": 400,
        "nearby_stop_ids": [],
        "flags_available": True,
    },
    {
        "slug": "praia-grande-do-portinho",
        "name": "Praia Grande do Portinho",
        "lat": 38.4855,
        "lon": -8.9782,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "apa_station_id": None,
        "tide_station_id": "setubal",
        "has_capacity_data": False,
        "max_capacity": None,
        "nearby_stop_ids": [],
        "flags_available": True,
    },
]


async def seed():
    async with AsyncSessionLocal() as db:
        for data in BEACHES:
            existing = await db.execute(select(Beach).where(Beach.slug == data["slug"]))
            if existing.scalar_one_or_none():
                print(f"  skip (exists): {data['slug']}")
                continue

            geom = f"SRID=4326;POINT({data['lon']} {data['lat']})"
            beach = Beach(
                slug=data["slug"],
                name=data["name"],
                lat=data["lat"],
                lon=data["lon"],
                geom=geom,
                ipma_global_id=data.get("ipma_global_id"),
                ipma_sea_global_id=data.get("ipma_sea_global_id"),
                apa_station_id=data.get("apa_station_id"),
                tide_station_id=data.get("tide_station_id"),
                has_capacity_data=data.get("has_capacity_data", False),
                max_capacity=data.get("max_capacity"),
                nearby_stop_ids=data.get("nearby_stop_ids", []),
                flags_available=data.get("flags_available", True),
            )
            db.add(beach)
            print(f"  insert: {data['slug']}")

        await db.commit()
        print("Done.")


if __name__ == "__main__":
    asyncio.run(seed())
