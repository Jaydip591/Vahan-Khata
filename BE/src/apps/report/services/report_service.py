from collections import defaultdict
from datetime import date
from decimal import Decimal
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from apps.expense.models.expense import Expense
from apps.party.models.party import Party
from apps.payment.models.payment import Payment
from apps.report.schemas.report import (
    CategoryTotal,
    ExpenseReport,
    MonthSummary,
    PartyReport,
    PartyReports,
    Trend,
    TrendPoint,
    VehicleReport,
    VehicleReports,
)
from apps.trip.models.trip import Trip
from apps.vehicle.models.vehicle import Vehicle
from core.dates import month_range

ZERO = Decimal("0")


def shift_month(month: str, delta: int) -> str:
    start, _ = month_range(month)
    idx = start.year * 12 + start.month - 1 + delta
    return f"{idx // 12:04d}-{idx % 12 + 1:02d}"


def _live(model, company_id):
    return (model.company_id == company_id, model.deleted_at.is_(None))


class ReportService:
    @staticmethod
    async def _income_expense(db: AsyncSession, company_id: UUID, start: date, end: date):
        income = await db.scalar(
            select(func.coalesce(func.sum(Trip.bhada), 0)).where(
                *_live(Trip, company_id), Trip.trip_date >= start, Trip.trip_date < end
            )
        )
        expense = await db.scalar(
            select(func.coalesce(func.sum(Expense.amount), 0)).where(
                *_live(Expense, company_id), Expense.expense_date >= start, Expense.expense_date < end
            )
        )
        return Decimal(income), Decimal(expense)

    @staticmethod
    async def summary(db: AsyncSession, company_id: UUID, month: str) -> MonthSummary:
        start, end = month_range(month)
        income, expense = await ReportService._income_expense(db, company_id, start, end)
        trips = await db.scalar(
            select(func.count()).select_from(Trip).where(
                *_live(Trip, company_id), Trip.trip_date >= start, Trip.trip_date < end
            )
        )
        collected = await db.scalar(
            select(func.coalesce(func.sum(Payment.amount), 0)).where(
                *_live(Payment, company_id), Payment.paid_on >= start, Payment.paid_on < end
            )
        )
        p_income, p_expense = await ReportService._income_expense(
            db, company_id, *month_range(shift_month(month, -1))
        )
        # Same rule as the khata: only parties that owe count; credits do not cancel other debts.
        total_due = (await _party_balances(db, company_id))[1]
        return MonthSummary(
            month=month,
            income=income,
            expense=expense,
            profit=income - expense,
            trips=trips or 0,
            collected=Decimal(collected),
            total_due=total_due,
            prev_profit=p_income - p_expense,
        )

    @staticmethod
    async def vehicles(db: AsyncSession, company_id: UUID, month: str) -> VehicleReports:
        start, end = month_range(month)
        vehicles = (
            (await db.execute(select(Vehicle).where(*_live(Vehicle, company_id))))
            .scalars()
            .all()
        )
        inc = {
            r[0]: (Decimal(r[1]), r[2])
            for r in await db.execute(
                select(Trip.vehicle_id, func.sum(Trip.bhada), func.count())
                .where(*_live(Trip, company_id), Trip.trip_date >= start, Trip.trip_date < end)
                .group_by(Trip.vehicle_id)
            )
        }
        exp = {
            r[0]: Decimal(r[1])
            for r in await db.execute(
                select(Expense.vehicle_id, func.sum(Expense.amount))
                .where(*_live(Expense, company_id), Expense.expense_date >= start, Expense.expense_date < end)
                .group_by(Expense.vehicle_id)
            )
        }
        diesel = defaultdict(list)
        for e in (
            await db.execute(
                select(Expense).where(
                    *_live(Expense, company_id),
                    Expense.category == "diesel",
                    Expense.expense_date >= start,
                    Expense.expense_date < end,
                )
            )
        ).scalars():
            diesel[e.vehicle_id].append(e)
        rows = []
        for v in vehicles:
            income, trips = inc.get(v.id, (ZERO, 0))
            expense = exp.get(v.id, ZERO)
            liters, km, mileage = _mileage(diesel[v.id])
            rows.append(
                VehicleReport(
                    vehicle_id=v.id,
                    name=v.name,
                    number=v.number,
                    income=income,
                    expense=expense,
                    profit=income - expense,
                    trips=trips,
                    diesel_liters=liters,
                    km=km,
                    mileage=mileage,
                )
            )
        rows.sort(key=lambda r: (-r.profit, r.name.lower()))
        return VehicleReports(month=month, vehicles=rows)

    @staticmethod
    async def parties(db: AsyncSession, company_id: UUID, month: str) -> PartyReports:
        start, end = month_range(month)
        names = {
            p.id: p.name
            for p in (await db.execute(select(Party).where(*_live(Party, company_id)))).scalars()
        }
        bhada = {
            r[0]: (Decimal(r[1]), r[2])
            for r in await db.execute(
                select(Trip.party_id, func.sum(Trip.bhada), func.count())
                .where(*_live(Trip, company_id), Trip.trip_date >= start, Trip.trip_date < end)
                .group_by(Trip.party_id)
            )
        }
        received = {
            r[0]: Decimal(r[1])
            for r in await db.execute(
                select(Payment.party_id, func.sum(Payment.amount))
                .where(*_live(Payment, company_id), Payment.paid_on >= start, Payment.paid_on < end)
                .group_by(Payment.party_id)
            )
        }
        balances = (await _party_balances(db, company_id))[0]
        rows = []
        for pid, name in names.items():
            b, n = bhada.get(pid, (ZERO, 0))
            got, bal = received.get(pid, ZERO), balances.get(pid, ZERO)
            if n == 0 and got == 0 and bal == 0:
                continue
            rows.append(PartyReport(party_id=pid, name=name, bhada=b, received=got, balance=bal, trips=n))
        rows.sort(key=lambda r: (-r.bhada, r.name.lower()))
        return PartyReports(month=month, parties=rows)

    @staticmethod
    async def trend(db: AsyncSession, company_id: UUID, month: str, months: int) -> Trend:
        points = []
        for i in range(months - 1, -1, -1):
            m = shift_month(month, -i)
            income, expense = await ReportService._income_expense(db, company_id, *month_range(m))
            points.append(TrendPoint(month=m, income=income, expense=expense, profit=income - expense))
        return Trend(points=points)

    @staticmethod
    async def expenses(
        db: AsyncSession, company_id: UUID, month: str, vehicle_id: UUID | None
    ) -> ExpenseReport:
        start, end = month_range(month)
        q = select(Expense.category, func.sum(Expense.amount), func.count()).where(
            *_live(Expense, company_id), Expense.expense_date >= start, Expense.expense_date < end
        )
        if vehicle_id:
            q = q.where(Expense.vehicle_id == vehicle_id)
        rows = [
            CategoryTotal(category=c, amount=Decimal(a), count=n)
            for c, a, n in await db.execute(q.group_by(Expense.category))
        ]
        rows.sort(key=lambda r: -r.amount)
        return ExpenseReport(month=month, total=sum((r.amount for r in rows), ZERO), categories=rows)


async def _party_balances(db: AsyncSession, company_id: UUID) -> tuple[dict, Decimal]:
    """Per-party balance (bhada - payments) and the sum of the positive ones."""
    bal: dict = defaultdict(lambda: ZERO)
    for pid, total in await db.execute(
        select(Trip.party_id, func.sum(Trip.bhada)).where(*_live(Trip, company_id)).group_by(Trip.party_id)
    ):
        bal[pid] += Decimal(total)
    for pid, total in await db.execute(
        select(Payment.party_id, func.sum(Payment.amount))
        .where(*_live(Payment, company_id))
        .group_by(Payment.party_id)
    ):
        bal[pid] -= Decimal(total)
    return bal, sum((b for b in bal.values() if b > ZERO), ZERO)


def _mileage(entries: list) -> tuple[Decimal, int | None, Decimal | None]:
    """Km per liter from diesel fills with an odometer reading.

    Distance is last odometer minus first; the first fill's liters only filled the
    tank before the measured stretch, so they are left out of the divisor."""
    liters = sum((e.liters for e in entries if e.liters), ZERO)
    marked = sorted((e for e in entries if e.odometer is not None), key=lambda e: e.odometer)
    if len(marked) < 2:
        return liters, None, None
    km = marked[-1].odometer - marked[0].odometer
    used = sum((e.liters for e in marked[1:] if e.liters), ZERO)
    if km <= 0 or used <= 0:
        return liters, None, None
    return liters, km, (Decimal(km) / used).quantize(Decimal("0.1"))
