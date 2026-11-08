from uuid import UUID

from fastapi import APIRouter, Depends, Query, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from apps.payment.schemas.payment import PaymentCreateRequest, PaymentResponse
from apps.payment.services.payment_service import PaymentService
from apps.user.models.user import User
from core.dependencies import get_current_user, get_db

router = APIRouter(prefix="/payments", tags=["Payments"])


@router.get("", response_model=list[PaymentResponse])
async def list_payments(
    party_id: UUID | None = None,
    month: str | None = Query(default=None, description="YYYY-MM"),
    limit: int = Query(default=100, ge=1, le=300),
    offset: int = Query(default=0, ge=0),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await PaymentService.list(
        db, user.company_id, party_id=party_id, month=month, limit=limit, offset=offset
    )


@router.post("", response_model=PaymentResponse, status_code=status.HTTP_201_CREATED)
async def create_payment(
    payload: PaymentCreateRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await PaymentService.create(db, user, payload)


@router.delete("/{payment_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_payment(
    payment_id: UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await PaymentService.delete(db, user.company_id, payment_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
