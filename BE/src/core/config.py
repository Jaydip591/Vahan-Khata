from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

_INSECURE_SECRET = "change-me-to-a-long-random-secret"


class Settings(BaseSettings):
    """Application-wide settings loaded from environment variables / .env file."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # Application
    APP_ENV: str = "development"
    APP_HOST: str = "0.0.0.0"
    APP_PORT: int = 8000

    # Database
    DATABASE_URL: str = (
        "postgresql+asyncpg://transport:transport@localhost:5432/transport"
    )

    # JWT / sessions
    SECRET_KEY: str = _INSECURE_SECRET
    ALGORITHM: str = "HS256"
    # Access token is short; the refresh token keeps the user logged in
    # until they log out explicitly.
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 365

    # First-start bootstrap (only used when the users table is empty)
    COMPANY_NAME: str = "My Transport"
    ADMIN_USERNAME: str | None = None
    ADMIN_PASSWORD: str | None = None
    ADMIN_NAME: str = "Admin"

    @property
    def async_database_url(self) -> str:
        """DATABASE_URL in the form SQLAlchemy + asyncpg wants.

        Hosted Postgres (Neon, Render) hands out `postgres://` or `postgresql://` URLs with
        `?sslmode=require&channel_binding=require`. asyncpg does not understand those query
        options, so the driver is added and SSL is passed through `database_connect_args`."""
        parts = urlsplit(self.DATABASE_URL)
        scheme = "postgresql+asyncpg" if parts.scheme in ("postgres", "postgresql") else parts.scheme
        query = [(k, v) for k, v in parse_qsl(parts.query) if k not in ("sslmode", "channel_binding", "ssl")]
        return urlunsplit((scheme, parts.netloc, parts.path, urlencode(query), parts.fragment))

    @property
    def database_connect_args(self) -> dict:
        parts = urlsplit(self.DATABASE_URL)
        query = dict(parse_qsl(parts.query))
        args: dict = {}
        if query.get("sslmode") in ("require", "verify-ca", "verify-full") or query.get("ssl") == "require":
            args["ssl"] = "require"
        if "-pooler." in (parts.hostname or ""):
            # Neon's pooled endpoint (PgBouncer) cannot keep prepared statements.
            args["statement_cache_size"] = 0
        return args

    @property
    def is_development(self) -> bool:
        return self.APP_ENV == "development"

    @model_validator(mode="after")
    def _require_real_secret_outside_dev(self) -> "Settings":
        if not self.is_development and (
            self.SECRET_KEY == _INSECURE_SECRET or len(self.SECRET_KEY) < 32
        ):
            raise ValueError("SECRET_KEY must be set to a random value of 32+ chars")
        return self


# Singleton instance – import this everywhere
settings = Settings()
