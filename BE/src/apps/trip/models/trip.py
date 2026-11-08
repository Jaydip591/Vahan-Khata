import uuid
from datetime import date
from decimal import Decimal

from sqlalchemy import Date, ForeignKey, Index, Numeric, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from core.database import Base
from core.mixins import CompanyOwnedMixin, SoftDeleteMixin, TimestampMixin

STATUS_RUNNING = "running"
STATUS_CLOSED = "closed"


class Trip(Base, TimestampMixin, SoftDeleteMixin, CompanyOwnedMixin):
    """
    One fera: a vehicle carries a party's load from one place to another for a bhada.
    What has been paid is NOT stored here: it comes from the payments table
    (see apps/ledger). An advance given with the trip is a payment linked to it.
    """

    __tablename__ = "trips"
    __table_args__ = (Index("ix_trips_company_date", "company_id", "trip_date"),)

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    vehicle_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("vehicles.id"), nullable=False, index=True
    )
    driver_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("drivers.id"), nullable=True
    )
    party_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("parties.id"), nullable=False, index=True
    )
    from_place_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("places.id"), nullable=False
    )
    to_place_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("places.id"), nullable=False
    )
    trip_date: Mapped[date] = mapped_column(Date, nullable=False)
    bhada: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    status: Mapped[str] = mapped_column(String(10), default=STATUS_RUNNING, nullable=False)
    note: Mapped[str | None] = mapped_column(String(500), nullable=True)
