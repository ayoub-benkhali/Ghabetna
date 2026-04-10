"""baseline

Revision ID: ef752849c265
Revises: 
Create Date: 2026-04-08 23:33:30.879470

"""
from typing import Sequence, Union

from alembic import op
import geoalchemy2
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = 'ef752849c265'
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass # tables already created by create_all


def downgrade() -> None:
    pass
