import uuid
from datetime import datetime
from sqlalchemy import String, Boolean, ForeignKey, func,DateTime
from sqlalchemy.orm import Mapped,mapped_column,relationship
from app.database import Base
from typing import Optional,TYPE_CHECKING

if TYPE_CHECKING:
    from app.models.role import Role

class User(Base):
    __tablename__="users"

    id:Mapped[int]=mapped_column(primary_key=True)
    email:Mapped[str]=mapped_column(String(255),unique=True,nullable=False,index=True)
    full_name:Mapped[str]=mapped_column(String(200),nullable=False)
    hashed_password:Mapped[Optional[str]]=mapped_column(String(255),nullable=True)

    role_id:Mapped[int]=mapped_column(ForeignKey("roles.id"),nullable=False)
    role: Mapped[Optional["Role"]] = relationship("Role", lazy="joined")

    service_id:Mapped[int|None]=mapped_column(ForeignKey("services.id",ondelete="SET NULL"),nullable=True)
    parcelle_id:Mapped[int|None]=mapped_column(nullable=True)

    is_active: Mapped[bool]=mapped_column(Boolean,default=False)
    activation_token:Mapped[Optional[str]]=mapped_column(String(255),nullable=True)
    activation_token_expires:Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)

    created_at:Mapped[datetime]=mapped_column(default=func.now(),server_default=func.now())
    updated_at:Mapped[datetime]=mapped_column(default=func.now(),server_default=func.now(),onupdate=func.now())

    def generate_activation_token(self)->str:
        token=str(uuid.uuid4())
        self.activation_token=token
        return token
