"""Pydantic Settings（demo 用 in-memory SQLite）。"""

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """应用配置。所有字段可由同名环境变量覆盖。"""

    app_name: str = "demo-fastapi-users"
    db_url: str = "sqlite+aiosqlite:///./demo_users.db"
    jwt_secret: str = "demo-secret-change-me-in-production"  # noqa: S105
    jwt_algorithm: str = "HS256"
    jwt_ttl_seconds: int = 3600
    log_level: str = "INFO"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()
