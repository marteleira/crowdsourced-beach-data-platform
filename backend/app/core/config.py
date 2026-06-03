from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import List


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/arrabida"
    JWT_SECRET: str = "dev-secret-change-in-production"
    JWT_ACCESS_EXPIRE_MINUTES: int = 15
    JWT_REFRESH_EXPIRE_DAYS: int = 30
    GOOGLE_CLIENT_ID: str = ""
    CORS_ORIGINS: List[str] = ["http://localhost:3000", "http://localhost:8080"]
    ENVIRONMENT: str = "development"
    FIREBASE_CREDENTIALS_PATH: str = ""  # path to serviceAccountKey.json, (the .env should overlap this...)


settings = Settings()
