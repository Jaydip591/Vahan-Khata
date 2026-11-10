import uuid
from datetime import date
from decimal import Decimal

from pydantic import BaseModel


class MonthSummary(BaseModel):
    month: str
    income: Decimal  # bhada of trips in the month
    expense: Decimal
    profit: Decimal
    trips: int
    collected: Decimal  # payments received in the month
    total_due: Decimal  # what parties owe, all time
    prev_profit: Decimal  # last month's profit, for the comparison


class FuelTotal(BaseModel):
    category: str  # diesel / petrol / cng
    amount: Decimal
    quantity: Decimal  # liters (kg for CNG)
    entries: int


class VehicleReport(BaseModel):
    vehicle_id: uuid.UUID
    name: str
    number: str
    income: Decimal
    expense: Decimal
    profit: Decimal
    trips: int
    fuels: list[FuelTotal]
    km: int | None  # odometer distance covered by the fuel entries
    mileage: Decimal | None  # km per liter (per kg for CNG); only when one fuel was used


class VehicleReports(BaseModel):
    month: str
    vehicles: list[VehicleReport]


class PartyReport(BaseModel):
    party_id: uuid.UUID
    name: str
    bhada: Decimal  # trips in the month
    received: Decimal  # payments in the month
    balance: Decimal  # owed, all time
    trips: int


class PartyReports(BaseModel):
    month: str
    parties: list[PartyReport]


class TrendPoint(BaseModel):
    month: str
    income: Decimal
    expense: Decimal
    profit: Decimal


class Trend(BaseModel):
    points: list[TrendPoint]


class CategoryTotal(BaseModel):
    category: str
    amount: Decimal
    count: int


class ExpenseReport(BaseModel):
    month: str
    total: Decimal
    categories: list[CategoryTotal]


class AccountBalance(BaseModel):
    account_id: uuid.UUID
    name: str
    kind: str  # cash / bank / upi
    is_active: bool
    opening: Decimal
    received: Decimal  # payments into this account, all time
    spent: Decimal  # expenses paid from this account, all time
    balance: Decimal  # opening + received - spent


class AccountBalances(BaseModel):
    total: Decimal
    accounts: list[AccountBalance]
    unassigned_spent: Decimal  # expenses saved without an account (not in any balance)


class WeekDay(BaseModel):
    day: date
    income: Decimal
    expense: Decimal
    trips: int


class WeekSummary(BaseModel):
    start: date  # Monday
    end: date  # Sunday (inclusive)
    income: Decimal
    expense: Decimal
    profit: Decimal
    trips: int
    days: list[WeekDay]  # always 7, Monday first
