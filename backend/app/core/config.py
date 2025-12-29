from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field
from typing import Literal


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Environment
    environment: Literal["development", "staging", "production"] = Field(
        "development", validation_alias="ENVIRONMENT"
    )
    debug: bool = Field(False, validation_alias="DEBUG")
    
    # Server
    port: int = Field(8000, validation_alias="PORT")
    host: str = Field("0.0.0.0", validation_alias="HOST")
    
    # Database
    database_url: str = Field("sqlite:///./dev.db", validation_alias="DATABASE_URL")
    
    # Authentication
    firebase_credentials_path: str | None = Field(None, validation_alias="FIREBASE_CREDENTIALS_PATH")
    
    # OpenAI / AI settings
    openai_api_key: str | None = Field(None, validation_alias="OPENAI_API_KEY")
    whisper_model: str = Field("whisper-1", validation_alias="WHISPER_MODEL")
    gpt_model: str = Field("gpt-4o-mini", validation_alias="GPT_MODEL")
    target_language: str = Field("en", validation_alias="TARGET_LANGUAGE")
    
    # Security
    cors_origins: str = Field("*", validation_alias="CORS_ORIGINS")  # Comma-separated
    rate_limit: str = Field("100/minute", validation_alias="RATE_LIMIT")
    
    # Monitoring
    sentry_dsn: str | None = Field(None, validation_alias="SENTRY_DSN")
    log_level: str = Field("INFO", validation_alias="LOG_LEVEL")
    
    @property
    def is_production(self) -> bool:
        return self.environment == "production"
    
    @property
    def cors_origins_list(self) -> list[str]:
        if self.cors_origins == "*":
            return ["*"]
        return [origin.strip() for origin in self.cors_origins.split(",")]


settings = Settings()
