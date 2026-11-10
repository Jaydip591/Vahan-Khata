from collections import defaultdict
from datetime import date, timedelta
from decimal import Decimal
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from apps.account.models.account import Account
from apps.expense.models.expense import Expense
from apps.party.models.party import Party
from apps.payment.models.payment import Payment
from apps.expense.schemas.expense import FUEL_CATEGORIES
from apps.report.schemas.report import (
    YearMonth,
    YearReport,
    WeekDay,
    WeekSummary,
    AccountBalance,
    AccountBalances,
    CategoryTotal,
    FuelTotal,
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
        return VehicleReports(month=month, vehicles=await _vehicle_rows(db, company_id, start, end))

    @staticmethod
    async def year(db: AsyncSession, company_id: UUID, fy: int) -> YearReport:
        """Financial year April-March: totals, month by month, and each vehicle."""
        start, end = date(fy, 4, 1), date(fy + 1, 4, 1)
        months = [f"{fy + (m < 4):04d}-{m:02d}" for m in (4, 5, 6, 7, 8, 9, 10, 11, 12, 1, 2, 3)]
        inc: dict = defaultdict(lambda: ZERO)
        trips: dict = defaultdict(int)
        exp: dict = defaultdict(lambda: ZERO)
        got: dict = defaultdict(lambda: ZERO)
        for d, total, n in await db.execute(
            select(Trip.trip_date, func.sum(Trip.bhada), func.count())
            .where(*_live(Trip, company_id), Trip.trip_date >= start, Trip.trip_date < end)
            .group_by(Trip.trip_date)
        ):
            inc[d.strftime("%Y-%m")] += Decimal(total)
            trips[d.strftime("%Y-%m")] += n
        for d, total in await db.execute(
            select(Expense.expense_date, func.sum(Expense.amount))
            .where(*_live(Expense, company_id), Expense.expense_date >= start, Expense.expense_date < end)
            .group_by(Expense.expense_date)
        ):
            exp[d.strftime("%Y-%m")] += Decimal(total)
        for d, total in await db.execute(
            select(Payment.paid_on, func.sum(Payment.amount))
            .where(*_live(Payment, company_id), Payment.paid_on >= start, Payment.paid_on < end)
            .group_by(Payment.paid_on)
        ):
            got[d.strftime("%Y-%m")] += Decimal(total)
        rows = [
            YearMonth(
                month=m, income=inc[m], expense=exp[m], profit=inc[m] - exp[m], collected=got[m], trips=trips[m]
            )
            for m in months
        ]
        income = sum((r.income for r in rows), ZERO)
        expense = sum((r.expense for r in rows), ZERO)
        return YearReport(
            fy=fy,
            label=f"{fy}-{(fy + 1) % 100:02d}",
            start=start,
            end=end - timedelta(days=1),
            income=income,
            expense=expense,
            profit=income - expense,
            collected=sum((r.collected for r in rows), ZERO),
            trips=sum(r.trips for r in rows),
            total_due=(await _party_balances(db, company_id))[1],
            months=rows,
            vehicles=await _vehicle_rows(db, company_id, start, end),
        )

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

    @staticmethod
    async def week(db: AsyncSession, company_id: UUID, day: date) -> WeekSummary:
        """Monday-Sunday week that holds `day`, with income, expense and trips per day."""
        start = day - timedelta(days=day.weekday())
        end = start + timedelta(days=7)
        inc = {
            r[0]: (Decimal(r[1]), r[2])
            for r in await db.execute(
                select(Trip.trip_date, func.sum(Trip.bhada), func.count())
                .where(*_live(Trip, company_id), Trip.trip_date >= start, Trip.trip_date < end)
                .group_by(Trip.trip_date)
            )
        }
        exp = {
            r[0]: Decimal(r[1])
            for r in await db.execute(
                select(Expense.expense_date, func.sum(Expense.amount))
                .where(*_live(Expense, company_id), Expense.expense_date >= start, Expense.expense_date < end)
                .group_by(Expense.expense_date)
            )
        }
        days = []
        for i in range(7):
            d = start + timedelta(days=i)
            income, trips = inc.get(d, (ZERO, 0))
            days.append(WeekDay(day=d, income=income, expense=exp.get(d, ZERO), trips=trips))
        income = sum((x.income for x in days), ZERO)
        expense = sum((x.expense for x in days), ZERO)
        return WeekSummary(
            start=start,
            end=end - timedelta(days=1),
            income=income,
            expense=expense,
            profit=income - expense,
            trips=sum(x.trips for x in days),
            days=days,
        )

    @staticmethod
    async def accounts(db: AsyncSession, company_id: UUID) -> AccountBalances:
        """Money in each account: opening balance + payments received into it - expenses paid from it."""
        accounts = (
            (await db.execute(select(Account).where(*_live(Account, company_id)))).scalars().all()
        )
        received = {
            r[0]: Decimal(r[1])
            for r in await db.execute(
                select(Payment.account_id, func.sum(Payment.amount))
                .where(*_live(Payment, company_id))
                .group_by(Payment.account_id)
            )
        }
        spent = {
            r[0]: Decimal(r[1])
            for r in await db.execute(
                select(Expense.account_id, func.sum(Expense.amount))
                .where(*_live(Expense, company_id))
                .group_by(Expense.account_id)
            )
        }
        rows = []
        for a in accounts:
            got, out = received.get(a.id, ZERO), spent.get(a.id, ZERO)
            if not a.is_active and got == 0 and out == 0 and a.opening_balance == 0:
                continue
            rows.append(
                AccountBalance(
                    account_id=a.id,
                    name=a.name,
                    kind=a.kind,
                    is_active=a.is_active,
                    opening=a.opening_balance,
                    received=got,
                    spent=out,
                    balance=a.opening_balance + got - out,
                )
            )
        rows.sort(key=lambda r: (not r.is_active, -r.balance, r.name.lower()))
        return AccountBalances(
            total=sum((r.balance for r in rows), ZERO),
            accounts=rows,
            unassigned_spent=spent.get(None, ZERO),
        )


async def _vehicle_rows(db: AsyncSession, company_id: UUID, start: date, end: date) -> list[VehicleReport]:
    """Income, expense, profit, trips and fuel per vehicle between start and end (exclusive)."""
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
                Expense.category.in_(FUEL_CATEGORIES),
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
        fuels, km, mileage = _fuel_summary(diesel[v.id])
        rows.append(
            VehicleReport(
                vehicle_id=v.id,
                name=v.name,
                number=v.number,
                income=income,
                expense=expense,
                profit=income - expense,
                trips=trips,
                fuels=fuels,
                km=km,
                mileage=mileage,
            )
        )
    rows.sort(key=lambda r: (-r.profit, r.name.lower()))
    return rows


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


def _fuel_summary(entries: list) -> tuple[list[FuelTotal], int | None, Decimal | None]:
    """Fuel used per kind, plus km and mileage from odometer readings.

    Distance is last odometer minus first; the first fill's liters only filled the tank before
    the measured stretch, so they are left out of the divisor. Mileage is only given when a
    single fuel was used: with two fuels mixed the distance cannot be split between them."""
    by_cat: dict[str, list] = defaultdict(list)
    for e in entries:
        by_cat[e.category].append(e)
    fuels = [
        FuelTotal(
            category=cat,
            amount=sum((e.amount for e in rows), ZERO),
            quantity=sum((e.liters for e in rows if e.liters), ZERO),
            entries=len(rows),
        )
        for cat, rows in sorted(by_cat.items())
    ]
    marked = sorted((e for e in entries if e.odometer is not None), key=lambda e: e.odometer)
    if len(marked) < 2:
        return fuels, None, None
    km = marked[-1].odometer - marked[0].odometer
    if km <= 0:
        return fuels, None, None
    if len(by_cat) != 1:
        return fuels, km, None
    used = sum((e.liters for e in marked[1:] if e.liters), ZERO)
    if used <= 0:
        return fuels, km, None
    return fuels, km, (Decimal(km) / used).quantize(Decimal("0.1"))
