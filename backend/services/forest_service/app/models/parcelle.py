from datetime import datetime
from typing import Any
from geoalchemy2 import Geometry
from sqlalchemy import String,Text,func,ForeignKey
from sqlalchemy.orm import Mapped,mapped_column,relationship
from app.database import Base

class Parcelle(Base):
    __tablename__="parcelles"

    id:Mapped[int]=mapped_column(primary_key=True)
    forest_id:Mapped[int]=mapped_column(ForeignKey("forests.id",ondelete="CASCADE"),nullable=False)
    name:Mapped[str]=mapped_column(String(200),nullable=False)
    description:Mapped[str | None]=mapped_column(Text,nullable=True)
    boundary: Mapped[Any]=mapped_column(
        Geometry("POLYGON",srid=4326,spatial_index=True),
        nullable=True
    )
    area_hectars:Mapped[float|None]=mapped_column(nullable=True)

    created_at:Mapped[datetime]=mapped_column(default=func.now(),server_default=func.now())
    updated_at:Mapped[datetime]=mapped_column(default=func.now(),server_default=func.now(),onupdate=func.now())
