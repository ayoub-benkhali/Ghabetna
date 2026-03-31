from datetime import datetime
from enum import Enum as PyEnum
from sqlalchemy import String,Text,Enum,func
from sqlalchemy.orm import Mapped,mapped_column
from app.database import Base

class ServiceType(PyEnum):
    administratif = "administratif"
    informatique = "informatique"
    juridique = "juridique"
    financier = "financier"
    terrain = "terrain"

class Service(Base):
    __tablename__="services"

    id:Mapped[int]=mapped_column(primary_key=True)
    name:Mapped[str]=mapped_column(String(100),unique=True,nullable=False)
    type:Mapped[ServiceType]=mapped_column(Enum(ServiceType),nullable=False)
    description:Mapped[str|None]=mapped_column(Text,nullable=True)
    created_at:Mapped[datetime]=mapped_column(default=func.now(),server_default=func.now())
