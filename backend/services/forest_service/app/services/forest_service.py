from fastapi import HTTPException,status
from geoalchemy2.shape import from_shape,to_shape
from shapely.geometry import mapping,Point
from sqlalchemy import select,text,func,outerjoin
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.forest import Forest
from app.models.parcelle import Parcelle
from app.schemas.forest_schema import ForestCreate,ForestReponse,ForestUpdate
import json,shapely


def _geojson_to_wkb(geojson:dict):
    #Convert GeoJSON geometry dict → PostGIS WKB. Auto-wraps Polygon in MultiPolygon
    if geojson["type"]=="Polygon":
        geojson = {"type": "MultiPolygon", "coordinates": [geojson["coordinates"]]}
    elif geojson["type"] != "MultiPolygon":
        raise ValueError(f"Expected Polygon or MultiPolygon, got {geojson['type']}")
    geom=shapely.from_geojson(json.dumps(geojson))
    return from_shape(geom,srid=4326)

def _wkb_to_geojson(wkb)-> dict|None:
    if wkb is None:
        return None
    return mapping(to_shape(wkb))

def _to_response(forest: Forest,parcelle_count:int=0)-> ForestReponse:
    center_lat,center_lng=None,None
    if forest.center_point is not None:
        point=to_shape(forest.center_point)
        if isinstance(point,Point):
            center_lng,center_lat= point.x ,point.y
        else:
            raise ValueError(f"Warning: Expected Point geometry, got {type(point).__name__}")
    return ForestReponse(
        id=forest.id,
        name=forest.name,
        region=forest.region,
        description=forest.description,
        area_hectares=forest.area_hectars,
        center_lat=center_lat,
        center_lng=center_lng,
        boundary_geojson=_wkb_to_geojson(forest.boundary),
        parcelle_count=parcelle_count,
        created_at=forest.created_at,
        updated_at=forest.updated_at
    )

async def create_forest(data:ForestCreate,db:AsyncSession)->ForestReponse:
    existing=await db.execute(select(Forest).where(Forest.name==data.name))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT,detail="Forest name already exists")
    forest=Forest(name=data.name,region=data.region,description=data.description)

    if data.boundary_geojson:
        forest.boundary=_geojson_to_wkb(data.boundary_geojson)
        db.add(forest)
        await db.flush()
        area_result=await db.execute(
            text("SELECT ST_Area(boundary::geography) / 10000 FROM forests WHERE id = :id"),{"id":forest.id}
        )
        forest.area_hectars=area_result.scalar()

    if data.center_lat is not None and data.center_lng is not None:
        forest.center_point=from_shape(Point(data.center_lng,data.center_lat),srid=4326)

    db.add(forest)
    await db.commit()
    await db.refresh(forest)
    return _to_response(forest)

async def get_forest(forest_id: int, db: AsyncSession) -> ForestReponse:
    count_subq = (
        select(Parcelle.forest_id, func.count(Parcelle.id).label("cnt"))
        .where(Parcelle.forest_id == forest_id)
        .group_by(Parcelle.forest_id)
        .subquery()
    )
    stmt = (
        select(Forest, func.coalesce(count_subq.c.cnt, 0).label("parcelle_count"))
        .where(Forest.id == forest_id)
        .outerjoin(count_subq, Forest.id == count_subq.c.forest_id)
    )
    row = (await db.execute(stmt)).one_or_none()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Forest Not Found")
    forest, cnt = row
    return _to_response(forest, int(cnt))

async def update_forest(forest_id:int, data:ForestUpdate, db:AsyncSession)->ForestReponse:
    result=await db.execute(select(Forest).where(Forest.id==forest_id))
    forest=result.scalar_one_or_none()
    if not forest:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,detail="Forest Not Found")
    
    if data.name is not None:
        forest.name=data.name
    if data.region is not None:
        forest.region=data.region
    if data.description is not None:
        forest.description=data.description
    if data.boundary_geojson is not None:
        forest.boundary=_geojson_to_wkb(data.boundary_geojson)
        await db.flush()
        area_result=await db.execute(
            text("SELECT ST_Area(boundary::geography) / 10000 FROM forests WHERE id = :id"),{"id":forest.id}
        )
        forest.area_hectars=area_result.scalar()
    if data.center_lat is not None and data.center_lng is not None:
        forest.center_point=from_shape(Point(data.center_lng,data.center_lat),srid=4326)

    await db.commit()
    await db.refresh(forest)
    return _to_response(forest)

async def delete_forest(forest_id:int, db:AsyncSession):
    result=await db.execute(select(Forest).where(Forest.id==forest_id))
    forest=result.scalar_one_or_none()
    if not forest:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,detail="Forest Not Found")
    await db.delete(forest)
    await db.commit()

async def get_forests(db: AsyncSession) -> list[ForestReponse]:
    count_subq = (
        select(Parcelle.forest_id, func.count(Parcelle.id).label("cnt"))
        .group_by(Parcelle.forest_id)
        .subquery()
    )
    stmt = (
        select(Forest, func.coalesce(count_subq.c.cnt, 0).label("parcelle_count"))
        .outerjoin(count_subq, Forest.id == count_subq.c.forest_id)
    )
    rows = (await db.execute(stmt)).all()
    return [_to_response(forest, int(cnt)) for forest, cnt in rows]

async def get_forests_by_ids(
    ids: list[int], db: AsyncSession
    ) -> list[ForestReponse]:
        """Return only the forests whose IDs are in `ids`, with parcelle counts."""
        if not ids:
            return []
        count_subq = (
            select(Parcelle.forest_id, func.count(Parcelle.id).label("cnt"))
            .where(Parcelle.forest_id.in_(ids))
            .group_by(Parcelle.forest_id)
            .subquery()
        )
        stmt = (
            select(Forest, func.coalesce(count_subq.c.cnt, 0).label("parcelle_count"))
            .where(Forest.id.in_(ids))
            .outerjoin(count_subq, Forest.id == count_subq.c.forest_id)
        )
        rows = (await db.execute(stmt)).all()
        return [_to_response(forest, int(cnt)) for forest, cnt in rows]
