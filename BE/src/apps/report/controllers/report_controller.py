from datetime import date
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from apps.report.schemas.report import (
    AccountBalances,
    ExpenseReport,
    MonthSummary,
    PartyReports,
    Trend,
    VehicleReports,
    WeekSummary,
    YearReport,
)
from apps.report.services.report_service import ReportService
from apps.user.models.user import User
from core.dependencies import get_current_user, get_db

router = APIRouter(prefix="/reports", tags=["Reports"])

MonthQ = Query(default=None, description="YYYY-MM; defaults to this month")


def _month(month: str | None) -> str:
    return month or date.today().strftime("%Y-%m")


@router.get("/summary", response_model=MonthSummary, summary="Income, expense and profit of a month")
async def summary(month: str | None = MonthQ, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    return await ReportService.summary(db, user.company_id, _month(month))


@router.get("/vehicles", response_model=VehicleReports, summary="Profit and mileage per vehicle")
async def vehicles(month: str | None = MonthQ, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    return await ReportService.vehicles(db, user.company_id, _month(month))


@router.get("/parties", response_model=PartyReports, summary="Bhada and payments per party")
async def parties(month: str | None = MonthQ, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    return await ReportService.parties(db, user.company_id, _month(month))


@router.get("/trend", response_model=Trend, summary="Month by month income, expense and profit")
async def trend(
    month: str | None = MonthQ,
    months: int = Query(default=6, ge=1, le=24),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await ReportService.trend(db, user.company_id, _month(month), months)


@router.get("/expenses", response_model=ExpenseReport, summary="Expense per category")
async def expenses(
    month: str | None = MonthQ,
    vehicle_id: UUID | None = None,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await ReportService.expenses(db, user.company_id, _month(month), vehicle_id)


@router.get("/accounts", response_model=AccountBalances, summary="Money in each account (all time)")
async def accounts(user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    return await ReportService.accounts(db, user.company_id)


@router.get("/week", response_model=WeekSummary, summary="This week (Monday-Sunday) day by day")
async def week(
    day: date | None = Query(default=None, description="Any day of the week; defaults to today"),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await ReportService.week(db, user.company_id, day or date.today())


def _current_fy() -> int:
    today = date.today()
    return today.year if today.month >= 4 else today.year - 1


@router.get("/year", response_model=YearReport, summary="Financial year (April-March) report")
async def year(
    fy: int | None = Query(default=None, ge=2000, le=2100, description="Start year; 2026 = Apr 2026-Mar 2027"),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await ReportService.year(db, user.company_id, fy or _current_fy())
