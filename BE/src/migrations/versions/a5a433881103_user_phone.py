"""user phone

Optional mobile number on users, shown and edited on the profile screen.

Revision ID: a5a433881103
Revises: 62a76ef14904
Create Date: 2026-11-10 23:38:32.531916
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'a5a433881103'
down_revision: Union[str, None] = '62a76ef14904'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('users', sa.Column('phone', sa.String(length=15), nullable=True))


def downgrade() -> None:
    op.drop_column('users', 'phone')
