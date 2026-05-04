from sqlalchemy import Table, Column, Integer, ForeignKey
from app.database import Base

supervisor_forest = Table(
    "supervisor_forest_assignments",
    Base.metadata,
    Column("user_id",   Integer, ForeignKey("users.id",  ondelete="CASCADE"), primary_key=True),
    Column("forest_id", Integer, nullable=False,primary_key=True),
)