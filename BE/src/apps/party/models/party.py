import uuid

from sqlalchemy import Boolean, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from core.database import Base
from core.mixins import CompanyOwnedMixin, SoftDeleteMixin, TimestampMixin


class Party(Base, TimestampMixin, SoftDeleteMixin, CompanyOwnedMixin):
    """A customer who gives us trips and pays later."""

    __tablename__ = "parties"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    phone: Mapped[str | None] = mapped_column(String(20), nullable=True)
    # How often this party usually pays: daily / ten_days / monthly (reminder hint only)
    payment_cycle: Mapped[str | None] = mapped_column(String(12), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
