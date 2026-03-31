import json,shapely
from fastapi import HTTPException,status
from geoalchemy2.shape import from_shape,to_shape
from shapely.geometry import mapping
from sqlalchemy import select,text
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.parcelle import Parcelle
from app.models.forest import Forest
from app.schemas.parcelle_schema import ParcelleCreate,ParcelleResponse,ParcelleUpdate

def _geojson_to_wkb_polygon(geojson:dict):
    if geojson["type"]!="Polygon":
        raise ValueError(f"Expected Polygon, got {geojson['type']}")
    geom=shapely.from_geojson(json.dumps(geojson))
    return from_shape(geom,srid=4326)

def _to_response(p:Parcelle)-> ParcelleResponse:
    return ParcelleResponse(
        id=p.id,
        forest_id=p.forest_id,
        name=p.name,
        description=p.description,
        area_hectares=p.area_hectars,
        boundary_geojson=mapping(to_shape(p.boundary)),
        created_at=p.created_at,
        updated_at=p.updated_at
    )

async def create_parcelle(forest_id:int,data:ParcelleCreate,db:AsyncSession)->ParcelleResponse:
    forest_cherck=await db.execute(select(Forest).where(Forest.id==forest_id))
    if not forest_cherck.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,detail="Forest Not Found")

    containement=await db.execute(
        text("""
            SELECT ST_Contains(
                (SELECT boundary FROM forests WHERE id = :fid),
                ST_GeomFromGeoJSON(:pgeojson)
            )
        """),{"fid":forest_id,"pgeojson":json.dumps(data.boundary_geojson)}
    )
    if not containement.scalar():
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Parcelle Boundary must be contained within the forest boundaries"
        )

    p=Parcelle(forest_id=forest_id,name=data.name,description=data.description,boundary=_geojson_to_wkb_polygon(data.boundary_geojson))
    db.add(p)
    await db.flush()
    area=await db.execute(
        text("SELECT ST_Area(boundary::geography)/10000 FROM parcelles WHERE id=:id"), {"id": p.id}
    )
    p.area_hectars=area.scalar()
    await db.commit()
    await db.refresh(p)
    return _to_response(p)

async def get_parcelles(forest_id:int,db:AsyncSession)->list[ParcelleResponse]:
    result=await db.execute(select(Parcelle).where(Parcelle.forest_id==forest_id))
    return[_to_response(p) for p in result.scalars().all()]


async def update_parcelle(parcelle_id:int,data:ParcelleUpdate,db:AsyncSession)->ParcelleResponse:
    result=await db.execute(select(Parcelle).where(Parcelle.id==parcelle_id))
    p=result.scalar_one_or_none()
    if not p:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,detail="Parcelle Not Found")
    if data.name:p.name=data.name
    if data.description:p.description=data.description
    if data.boundary_geojson:
        p.boundary=_geojson_to_wkb_polygon(data.boundary_geojson)
        await db.flush()
        area=await db.execute(
            text("SELECT ST_Area(boundary::geography)/10000 FROM parcelles WHERE id=:id"), {"id": p.id}
        )
        p.area_hectars=area.scalar()
        containement=await db.execute(
            text("""
                SELECT ST_Contains(
                    (SELECT boundary FROM forests WHERE id = :fid),
                    ST_GeomFromGeoJSON(:pgeojson)
                )
            """),{"fid":p.forest_id,"pgeojson":json.dumps(data.boundary_geojson)}
        )
        if not containement.scalar():
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Parcelle Boundary must be contained within the forest boundaries"
            )

    await db.commit()
    await db.refresh(p)
    return _to_response(p)


async def get_parcelle(parcelle_id:int,db:AsyncSession)->ParcelleResponse:
    result=await db.execute(select(Parcelle).where(Parcelle.id==parcelle_id))
    p=result.scalar_one_or_none()
    if not p:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,detail="Parcelle Not Found")
    return _to_response(p)

async def delete_parcelle(parcelle_id:int,db:AsyncSession):
    result=await db.execute(select(Parcelle).where(Parcelle.id==parcelle_id))
    p=result.scalar_one_or_none()
    if not p:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,detail="Parcelle Not Found")
    await db.delete(p)
    await db.commit()
