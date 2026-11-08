from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from apps.ledger.schemas.ledger import PartyBalances, PartyLedger
from apps.ledger.services.ledger_service import LedgerService
from apps.user.models.user import User
from core.dependencies import get_current_user, get_db

router = APIRouter(prefix="/ledger", tags=["Ledger"])


@router.get("/parties", response_model=PartyBalances, summary="What every party owes")
async def party_balances(user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    return await LedgerService.balances(db, user.company_id)


@router.get("/parties/{party_id}", response_model=PartyLedger, summary="One party's khata")
async def party_ledger(
    party_id: UUID, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    return await LedgerService.party_ledger(db, user.company_id, party_id)
