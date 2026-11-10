import uuid

from sqlalchemy import Boolean, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from core.database import Base
from core.mixins import CompanyOwnedMixin, SoftDeleteMixin, TimestampMixin


class Payee(Base, TimestampMixin, SoftDeleteMixin, CompanyOwnedMixin):
    """Someone we pay by UPI from the app: 'Pump - Kamrej' with their UPI id (from their QR)."""

    __tablename__ = "payees"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    upi_id: Mapped[str] = mapped_column(String(100), nullable=False)  # e.g. kamrejpump@okaxis
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
