import uuid
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


class VehicleReport(BaseModel):
    vehicle_id: uuid.UUID
    name: str
    number: str
    income: Decimal
    expense: Decimal
    profit: Decimal
    trips: int
    diesel_liters: Decimal
    km: int | None  # odometer distance covered by the diesel entries
    mileage: Decimal | None  # km per liter


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
