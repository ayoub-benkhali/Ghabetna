from datetime import datetime
from typing import Any
import enum
from geoalchemy2 import Geometry
from sqlalchemy import String,Text,Enum as SAEnum,Integer,func,Float
from sqlalchemy.orm import Mapped,mapped_column
from app.database import Base

class IncidentCategory(str,enum.Enum):
    FEU = "feu"
    COUPE_ILLEGALE = "coupe_illegale"
    REFUGE_SUSPECT = "refuge_suspect"
    TRAFIC = "trafic"
    DECHET = "dechet"
    MALADIE = "maladie"
    AUTRE = "autre"

class IncidentStatus(str, enum.Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    RESOLVED = "resolved"
    REJECTED = "rejected"

class Incident(Base):
    __tablename__ = "incidents"

    id: Mapped[int] = mapped_column(primary_key=True)

    # Who reported it
    agent_id: Mapped[int] = mapped_column(Integer, nullable=False, index=True)
    agent_name: Mapped[str] = mapped_column(String(200), nullable=False)

    # What it is
    category: Mapped[IncidentCategory] = mapped_column(
        SAEnum(IncidentCategory, name="incidentcategory", values_callable=lambda x: [e.value for e in x]),
        nullable=False
    )
    description: Mapped[str] = mapped_column(Text, nullable=False)
    image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)

    # Where it is (PostGIS point + human-readable copies)
    location: Mapped[Any] = mapped_column(
        Geometry("POINT", srid=4326, spatial_index=True),
        nullable=True
    )
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)

    # Organisational context (plain ints — no cross-service FK)
    parcelle_id: Mapped[int | None] = mapped_column(Integer, nullable=True, index=True)
    forest_id: Mapped[int | None] = mapped_column(Integer, nullable=True, index=True)

    # Lifecycle
    status: Mapped[IncidentStatus] = mapped_column(
        SAEnum(IncidentStatus, name="incidentstatus", values_callable=lambda x: [e.value for e in x]),
        default=IncidentStatus.PENDING,
        server_default="pending"
    )
    is_critical: Mapped[bool] = mapped_column(default=False)

    created_at: Mapped[datetime] = mapped_column(
        default=func.now(), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        default=func.now(), server_default=func.now(), onupdate=func.now()
    )