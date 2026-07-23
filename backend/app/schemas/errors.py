class CodedValueError(ValueError):
    """Raise from a Pydantic validator to carry a stable i18n code + params
    instead of a hardcoded message. Caught by the RequestValidationError
    handler in app/main.py, which resolves it via app.core.i18n.t()."""

    def __init__(self, code: str, **params):
        self.code = code
        self.params = params
        super().__init__(code)
