import uuid
from datetime import date

from sqlalchemy import Boolean, Date, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from core.database import Base
from core.mixins import CompanyOwnedMixin, SoftDeleteMixin, TimestampMixin


class Vehicle(Base, TimestampMixin, SoftDeleteMixin, CompanyOwnedMixin):
    __tablename__ = "vehicles"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    vehicle_type: Mapped[str] = mapped_column(String(20), nullable=False)
    name: Mapped[str] = mapped_column(String(60), nullable=False)
    number: Mapped[str] = mapped_column(String(20), nullable=False)
    # diesel / petrol / cng / cng_petrol (runs on both). Chooses the default in the fuel entry.
    fuel_type: Mapped[str] = mapped_column(String(12), default="diesel", server_default="diesel", nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    # Document expiry dates (all optional; used for reminders in Phase 4)
    insurance_exp: Mapped[date | None] = mapped_column(Date, nullable=True)
    puc_exp: Mapped[date | None] = mapped_column(Date, nullable=True)
    fitness_exp: Mapped[date | None] = mapped_column(Date, nullable=True)
    permit_exp: Mapped[date | None] = mapped_column(Date, nullable=True)
    tax_exp: Mapped[date | None] = mapped_column(Date, nullable=True)
