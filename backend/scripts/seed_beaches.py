"""
Seed script — insert the Arrábida beaches into the database.

IPMA global IDs for the Setúbal region:
  Weather (Setúbal): 1151200  — from distrits-islands.json
  Sea (Arrábida coast): 1111026  — lat 38.65 lon -9.31, from hp-daily-sea-forecast-day0.json

EEA station IDs (bathingWaterIdentifier) — verify against
https://www.eea.europa.eu/en/analysis/maps-and-charts/state-of-bathing-waters

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
        "lat": 38.480071,
        "lon": -8.978540,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "eea_station_id": "PTCW2P",
        "tide_station_id": "PT_150505_2",
        "has_capacity_data": False,
        "max_capacity": 800,
        "nearby_stop_ids": ['162842', '160802'],
        "flags_available": True,
        "cover_photo_url": "/static/beaches/portinho_arrabida.jpg",
        "municipality": "Setúbal",
    },
    {
        "slug": "praia-de-galapinhos",
        "name": "Praia de Galapinhos",
        "lat": 38.483833,
        "lon": -8.968473,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "eea_station_id": "PTCW7E",
        "tide_station_id": "PT_150505_2",
        "has_capacity_data": False,
        "max_capacity": None,
        "nearby_stop_ids": ['160817', '160818'],
        "flags_available": True,
        "cover_photo_url": "/static/beaches/galapinhos.jpg",
        "municipality": "Setúbal",
    },
    {
        "slug": "praia-de-galapos",
        "name": "Praia de Galápos",
        "lat": 38.484504,
        "lon": -8.963943,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "eea_station_id": "PTCT8X",
        "tide_station_id": "PT_150505_2",
        "has_capacity_data": False,
        "max_capacity": None,
        "nearby_stop_ids": ['168562', '168137'],
        "flags_available": True,
        "cover_photo_url": "/static/beaches/galapos.jpg",
        "municipality": "Setúbal",
    },
    {
        "slug": "praia-do-creiro",
        "name": "Praia do Creiro",
        "lat": 38.480520,
        "lon": -8.977562,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "eea_station_id": "PTCW2P",
        "tide_station_id": "PT_150505_2",
        "has_capacity_data": False,
        "max_capacity": 600,
        "nearby_stop_ids": ['162842', '160802'],
        "flags_available": True,
        "cover_photo_url": "/static/beaches/creiro.jpg",
        "municipality": "Setúbal",
    },
    {
        "slug": "praia-da-figuerinha",
        "name": "Praia da Figuerinha",
        "lat": 38.484119,
        "lon": -8.944748,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "eea_station_id": "PTCJ7C",
        "tide_station_id": "PT_150505_2",
        "has_capacity_data": False,
        "max_capacity": 1200,
        "nearby_stop_ids": ['160819', '160975', '160976'],
        "flags_available": True,
        "cover_photo_url": "/static/beaches/figueirinha.jpg",
        "municipality": "Setúbal",
    },
    {
        "slug": "praia-do-outao",
        "name": "Praia do Outão",
        "lat": 38.488254,
        "lon": -8.934784,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "eea_station_id": None,
        "tide_station_id": "PT_150505_2",
        "has_capacity_data": False,
        "max_capacity": 2000,
        "nearby_stop_ids": ['160331', '160332', '160334', '160333'],
        "flags_available": True,
        "cover_photo_url": "/static/beaches/outao.jpg",
        "municipality": "Setúbal",
    },
    {
        "slug": "praia-de-sesimbra",
        "name": "Praia de Sesimbra",
        "lat": 38.442783,
        "lon": -9.103129,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "eea_station_id": "PTCT2H",
        "tide_station_id": "PT_151101_1",
        "has_capacity_data": False,
        "max_capacity": 3000,
        "nearby_stop_ids": ['150463', '150477', '150453'],
        "flags_available": True,
        "cover_photo_url": "/static/beaches/sesimbra.jpg",
        "municipality": "Sesimbra",
    },
    {
        "slug": "praia-do-ouro",
        "name": "Praia do Ouro",
        "lat": 38.443022,
        "lon": -9.105478,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "eea_station_id": "PTCT2H",
        "tide_station_id": "PT_151101_1",
        "has_capacity_data": False,
        "max_capacity": 500,
        "nearby_stop_ids": ['150463', '150477'],
        "flags_available": True,
        "cover_photo_url": "/static/beaches/ouro.jpg",
        "municipality": "Sesimbra",
    },
    {
        "slug": "praia-da-california",
        "name": "Praia da Califórnia",
        "lat": 38.441411,
        "lon": -9.095100,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "eea_station_id": "PTCQ7V",
        "tide_station_id": "PT_151101_1",
        "has_capacity_data": False,
        "max_capacity": 300,
        "nearby_stop_ids": ['150463', '150477'],
        "flags_available": True,
        "cover_photo_url": "/static/beaches/california.jpg",
        "municipality": "Sesimbra",
    },
    {
        "slug": "praia-da-ribeira-do-cavalo",
        "name": "Praia da Ribeira do Cavalo",
        "lat": 38.432581,
        "lon": -9.130301,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "eea_station_id": None,
        "tide_station_id": "PT_151101_1",   # 1.9km vs 21km — clearly Sesimbra station
        "has_capacity_data": False,
        "max_capacity": None,               # pandemic value removed — no official limit
        "nearby_stop_ids": ['150415', '150437'],  # Porto Abrigo + Sesimbra Parque Campismo
        "flags_available": True,
        "cover_photo_url": "/static/beaches/ribeira_cavalo.jpg",
        "municipality": "Sesimbra",
    },
    {
        "slug": "praia-de-alpertucho",
        "name": "Praia de Alpertucho",
        "lat": 38.467481,
        "lon": -8.990139,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "eea_station_id": None,
        "tide_station_id": "PT_150505_2",   # new coords in Arrábida: 8.3km vs 10.9km
        "has_capacity_data": False,
        "max_capacity": None,               # pandemic value removed
        "nearby_stop_ids": ['160800', '160799'],  # X Arrábida, 0.36/0.41km
        "flags_available": True,
        "cover_photo_url": "/static/beaches/alpertuche.jpg",
        "municipality": "Setúbal",
    },
    {
        "slug": "praia-da-anixa",
        "name": "Praia da Anixa",
        "lat": 38.480506,
        "lon": -8.970491,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "eea_station_id": None,           # small natural beach, no EEA monitoring station
        "tide_station_id": "PT_150505_2",
        "has_capacity_data": False,
        "max_capacity": None,
        "nearby_stop_ids": ['160802', '160799', '160800'],  # Creiro parking + X Arrábida
        "flags_available": True,
        "cover_photo_url": "/static/beaches/anixa.jpg",
        "municipality": "Setúbal",
    },
    {
        "slug": "praia-dos-coelhos",
        "name": "Praia dos Coelhos",
        "lat": 38.481648,
        "lon": -8.969542,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "eea_station_id": None,
        "tide_station_id": "PT_150505_2",
        "has_capacity_data": False,
        "max_capacity": None,
        "nearby_stop_ids": ['160802', '160819'],  # Creiro parking + Figueirinha
        "flags_available": True,
        "cover_photo_url": "/static/beaches/coelhos.jpg",
        "municipality": "Setúbal",
    },
    {
        "slug": "praia-do-monte-branco",
        "name": "Praia do Monte Branco",
        "lat": 38.480418,
        "lon": -8.972535,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "eea_station_id": None,
        "tide_station_id": "PT_150505_2",
        "has_capacity_data": False,
        "max_capacity": None,
        "nearby_stop_ids": ['160802', '160799', '160800'],
        "flags_available": True,
        "cover_photo_url": "/static/beaches/monte_branco.jpg",
        "municipality": "Setúbal",
    },
    {
        "slug": "praia-dos-pilotos",
        "name": "Praia dos Pilotos",
        "lat": 38.472952,
        "lon": -8.984338,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "eea_station_id": None,
        "tide_station_id": "PT_150505_2",
        "has_capacity_data": False,
        "max_capacity": None,
        "nearby_stop_ids": ['160799', '160800', '160802'],  # X Arrábida 0.64km
        "flags_available": True,
        "cover_photo_url": "/static/beaches/pilotos.jpg",
        "municipality": "Setúbal",
    },
    {
        "slug": "praia-dos-penedos",
        "name": "Praia dos Penedos",
        "lat": 38.446810,
        "lon": -9.043049,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "eea_station_id": None,
        "tide_station_id": "PT_151101_1",  # 5.9km vs 13.5km
        "has_capacity_data": False,
        "max_capacity": None,
        "nearby_stop_ids": ['150359', '150360'],  # Pedreiras ~2.8km (road access)
        "flags_available": True,
        "cover_photo_url": "/static/beaches/penedos.jpg",
        "municipality": "Sesimbra",
    },
    {
        "slug": "praia-da-cova",
        "name": "Praia da Cova",
        "lat": 38.440941,
        "lon": -9.059571,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "eea_station_id": None,
        "tide_station_id": "PT_151101_1",  # 4.4km vs 15.0km
        "has_capacity_data": False,
        "max_capacity": None,
        "nearby_stop_ids": ['150361', '150362'],  # Pedreiras ~2.1km
        "flags_available": True,
        "cover_photo_url": "/static/beaches/cova.jpg",
        "municipality": "Sesimbra",
    },
    {
        "slug": "praia-da-mijona",
        "name": "Praia da Mijona",
        "lat": 38.430615,
        "lon": -9.145722,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "eea_station_id": None,
        "tide_station_id": "PT_151101_1",  # 3.2km vs 22.5km
        "has_capacity_data": False,
        "max_capacity": None,
        "nearby_stop_ids": ['150190', '150189'],  # Facho Azóia ~1.5km
        "flags_available": True,
        "cover_photo_url": "/static/beaches/mijona.jpg",
        "municipality": "Sesimbra",
    },
    {
        "slug": "praia-bico-das-lulas",
        "name": "Praia Bico das Lulas",
        "lat": 38.486292,
        "lon": -8.907746,
        "ipma_global_id": 1151200,     # Setubal IPMA point
        "ipma_sea_global_id": 1111026,  # nearest sea forecast point even measured from Tróia
        "eea_station_id": "PTCN9M",     # official APA/EEA zone "Tróia-Bico das Lulas"
        "tide_station_id": "PT_150505_2",  # IH station "Setúbal - Tróia"
        "has_capacity_data": False,
        "max_capacity": None,
        "nearby_stop_ids": [],  # Carris metropolitana does not serve
        "flags_available": True,
        "cover_photo_url": "/static/beaches/bico_lulas.jpg",
        "municipality": "Grândola",
    },
    {
        "slug": "praia-de-troia",
        "name": "Praia de Tróia",
        "lat": 38.489728,
        "lon": -8.911451,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "eea_station_id": "PTCU9C",     # official APA/EEA zone "Tróia - Mar"
        "tide_station_id": "PT_150505_2",  # ~1km away
        "has_capacity_data": False,
        "max_capacity": None,
        "nearby_stop_ids": [],
        "flags_available": True,
        "cover_photo_url": "/static/beaches/troia.jpg",
        "municipality": "Grândola",
    },
    {
        "slug": "praia-de-troia-rio",
        "name": "Praia de Tróia Rio",
        "lat": 38.493811,
        "lon": -8.898588,
        "ipma_global_id": 1151200,
        "ipma_sea_global_id": 1111026,
        "eea_station_id": None,  # river-facing side (no data)
        "tide_station_id": "PT_150505_2",  # only 0.2km away — closest of the three
        "has_capacity_data": False,
        "max_capacity": None,
        "nearby_stop_ids": [],
        "flags_available": True,
        "cover_photo_url": "/static/beaches/troia_rio.jpg",
        "municipality": "Grândola",
    },
]
"""
    Thats a lot, its added until mijona, if i want more just follow from mijona to left and up (coast)
"""


async def seed():
    async with AsyncSessionLocal() as db:
        for data in BEACHES:
            geom = f"SRID=4326;POINT({data['lon']} {data['lat']})"

            result = await db.execute(select(Beach).where(Beach.slug == data["slug"]))
            beach = result.scalar_one_or_none()

            if beach:
                # Update existing record with latest values from the seed file
                beach.name = data["name"]
                beach.lat = data["lat"]
                beach.lon = data["lon"]
                beach.geom = geom
                beach.ipma_global_id = data.get("ipma_global_id")
                beach.ipma_sea_global_id = data.get("ipma_sea_global_id")
                beach.eea_station_id = data.get("eea_station_id")
                beach.tide_station_id = data.get("tide_station_id")
                beach.has_capacity_data = data.get("has_capacity_data", False)
                beach.max_capacity = data.get("max_capacity")
                beach.nearby_stop_ids = data.get("nearby_stop_ids", [])
                beach.flags_available = data.get("flags_available", True)
                beach.cover_photo_url = data.get("cover_photo_url")
                beach.municipality = data.get("municipality")
                print(f"  update: {data['slug']}")
                continue

            beach = Beach(
                slug=data["slug"],
                name=data["name"],
                lat=data["lat"],
                lon=data["lon"],
                geom=geom,
                ipma_global_id=data.get("ipma_global_id"),
                ipma_sea_global_id=data.get("ipma_sea_global_id"),
                eea_station_id=data.get("eea_station_id"),
                tide_station_id=data.get("tide_station_id"),
                has_capacity_data=data.get("has_capacity_data", False),
                max_capacity=data.get("max_capacity"),
                nearby_stop_ids=data.get("nearby_stop_ids", []),
                flags_available=data.get("flags_available", True),
                cover_photo_url=data.get("cover_photo_url"),
                municipality=data.get("municipality"),
            )
            db.add(beach)
            print(f"  insert: {data['slug']}")

        await db.commit()
        print("Done.")


if __name__ == "__main__":
    asyncio.run(seed())
