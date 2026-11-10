"""upi payees

People we pay by UPI from the app, and the payee + UPI reference on an expense.

Revision ID: e9e89ede5e86
Revises: a5a433881103
Create Date: 2026-11-11 00:05:53.516074
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'e9e89ede5e86'
down_revision: Union[str, None] = 'a5a433881103'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table('payees',
    sa.Column('id', sa.UUID(), nullable=False),
    sa.Column('name', sa.String(length=100), nullable=False),
    sa.Column('upi_id', sa.String(length=100), nullable=False),
    sa.Column('is_active', sa.Boolean(), nullable=False),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    sa.Column('deleted_at', sa.DateTime(timezone=True), nullable=True),
    sa.Column('company_id', sa.UUID(), nullable=False),
    sa.Column('created_by', sa.UUID(), nullable=True),
    sa.ForeignKeyConstraint(['company_id'], ['companies.id'], ),
    sa.ForeignKeyConstraint(['created_by'], ['users.id'], use_alter=True),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_payees_company_id'), 'payees', ['company_id'], unique=False)
    op.create_index(op.f('ix_payees_deleted_at'), 'payees', ['deleted_at'], unique=False)
    op.add_column('expenses', sa.Column('payee_id', sa.UUID(), nullable=True))
    op.add_column('expenses', sa.Column('upi_ref', sa.String(length=40), nullable=True))
    op.create_foreign_key('fk_expenses_payee_id_payees', 'expenses', 'payees', ['payee_id'], ['id'])


def downgrade() -> None:
    op.drop_constraint('fk_expenses_payee_id_payees', 'expenses', type_='foreignkey')
    op.drop_column('expenses', 'upi_ref')
    op.drop_column('expenses', 'payee_id')
    op.drop_index(op.f('ix_payees_deleted_at'), table_name='payees')
    op.drop_index(op.f('ix_payees_company_id'), table_name='payees')
    op.drop_table('payees')
