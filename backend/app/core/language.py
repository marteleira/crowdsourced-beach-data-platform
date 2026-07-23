SUPPORTED_LANGUAGES = ("en", "pt")
DEFAULT_LANGUAGE = "en"


def resolve_language(accept_language: str | None) -> str:
    """English by default; Portuguese only for a pt/pt-PT/pt-BR/... primary subtag."""
    if not accept_language:
        return DEFAULT_LANGUAGE
    primary = accept_language.split(",")[0].split(";")[0].strip().lower()
    primary = primary.split("-")[0].split("_")[0]
    return "pt" if primary == "pt" else DEFAULT_LANGUAGE
