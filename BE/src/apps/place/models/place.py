import uuid

from sqlalchemy import Boolean, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from core.database import Base
from core.mixins import SoftDeleteMixin, TimestampMixin


class Place(Base, TimestampMixin, SoftDeleteMixin):
    """
    A city, town or industrial area with English and Gujarati names.
    company_id NULL = shared seed list visible to everyone; otherwise a place the
    company added itself.
    """

    __tablename__ = "places"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    company_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("companies.id"), nullable=True, index=True
    )
    created_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=True
    )
    name_en: Mapped[str] = mapped_column(String(100), nullable=False)
    name_gu: Mapped[str] = mapped_column(String(100), nullable=False)
    is_seed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    # Popularity order for seed places (lower = shown first when nothing is typed)
    rank: Mapped[int | None] = mapped_column(Integer, nullable=True)
