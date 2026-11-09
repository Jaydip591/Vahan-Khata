"""vehicle fuel type

Revision ID: 62a76ef14904
Revises: 75ef92fee392
Create Date: 2026-11-09 12:41:30.335372
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = '62a76ef14904'
down_revision: Union[str, None] = '75ef92fee392'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        'vehicles',
        sa.Column('fuel_type', sa.String(length=12), server_default='diesel', nullable=False),
    )


def downgrade() -> None:
    op.drop_column('vehicles', 'fuel_type')
