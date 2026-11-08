from fastapi import APIRouter, Depends, Query, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from apps.place.schemas.place import PlaceCreateRequest, PlaceResponse, TransliterationResponse
from apps.place.services.place_service import PlaceService
from apps.place.services.transliteration import transliterate_gu
from apps.user.models.user import User
from core.dependencies import get_current_user, get_db

router = APIRouter(prefix="/places", tags=["Places"])


@router.get("", response_model=list[PlaceResponse], summary="Search places (English or Gujarati)")
async def search_places(
    q: str | None = Query(default=None, max_length=60),
    limit: int = Query(default=20, ge=1, le=50),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await PlaceService.search(db, user.company_id, q, limit)


@router.get(
    "/transliterate",
    response_model=TransliterationResponse,
    summary="Suggest the Gujarati spelling of an English name",
)
async def transliterate(
    text: str = Query(min_length=1, max_length=60),
    user: User = Depends(get_current_user),
):
    return TransliterationResponse(suggestions=await transliterate_gu(text))


@router.post("", response_model=PlaceResponse, summary="Add a place (returns the existing one if the name exists)")
async def create_place(
    payload: PlaceCreateRequest,
    response: Response,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    place, created = await PlaceService.create(db, user, payload)
    response.status_code = status.HTTP_201_CREATED if created else status.HTTP_200_OK
    return place
