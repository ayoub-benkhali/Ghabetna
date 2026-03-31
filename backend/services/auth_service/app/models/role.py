from datetime import datetime
from typing import List
from sqlalchemy import String, Text, func
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped,mapped_column
from app.database import Base

class Role(Base):
    __tablename__="roles"

    id:Mapped[int]=mapped_column(primary_key=True)
    name:Mapped[str]=mapped_column(String(50),unique=True,nullable=False)
    permissions:Mapped[List[str]]=mapped_column(JSONB,default=list,nullable=False)
    description: Mapped[str|None]=mapped_column(Text,nullable=True)
    created_at:Mapped[datetime]=mapped_column(default=func.now(),server_default=func.now())
    updated_at:Mapped[datetime]=mapped_column(default=func.now(),server_default=func.now(),onupdate=func.now())

    def has_permission(self,permission:str)->bool:
        return permission in self.permissions
