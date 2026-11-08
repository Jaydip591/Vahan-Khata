from uuid import UUID

from fastapi import APIRouter, Depends, Query, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from apps.expense.schemas.expense import (
    ExpenseCategory,
    ExpenseCreateRequest,
    ExpenseResponse,
    ExpenseUpdateRequest,
)
from apps.expense.services.expense_service import ExpenseService
from apps.user.models.user import User
from core.dependencies import get_current_user, get_db

router = APIRouter(prefix="/expenses", tags=["Expenses"])


@router.get("", response_model=list[ExpenseResponse])
async def list_expenses(
    vehicle_id: UUID | None = None,
    trip_id: UUID | None = None,
    category: ExpenseCategory | None = None,
    month: str | None = Query(default=None, description="YYYY-MM"),
    limit: int = Query(default=100, ge=1, le=300),
    offset: int = Query(default=0, ge=0),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await ExpenseService.list(
        db,
        user.company_id,
        vehicle_id=vehicle_id,
        trip_id=trip_id,
        category=category,
        month=month,
        limit=limit,
        offset=offset,
    )


@router.post("", response_model=ExpenseResponse, status_code=status.HTTP_201_CREATED)
async def create_expense(
    payload: ExpenseCreateRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await ExpenseService.create(db, user, payload)


@router.get("/{expense_id}", response_model=ExpenseResponse)
async def get_expense(
    expense_id: UUID, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    return await ExpenseService.get(db, user.company_id, expense_id)


@router.patch("/{expense_id}", response_model=ExpenseResponse)
async def update_expense(
    expense_id: UUID,
    payload: ExpenseUpdateRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await ExpenseService.update(db, user, expense_id, payload)


@router.delete("/{expense_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_expense(
    expense_id: UUID, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    await ExpenseService.delete(db, user.company_id, expense_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
