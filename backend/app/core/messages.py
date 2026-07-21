"""
Centralised user-facing error and status messages.

All HTTPException detail strings live here so that:
  - they are easy to find and update
  - adding i18n support in the future only requires changing this file
"""


class Msg:
    # Auth
    EMAIL_TAKEN = "Email já registado"
    EMAIL_IN_USE = "Email já em uso"
    INVALID_CREDENTIALS = "Credenciais inválidas"
    INVALID_GOOGLE_TOKEN = "Token Google inválido"
    INVALID_REFRESH_TOKEN = "Refresh token inválido ou expirado"
    INVALID_RESET_REQUEST = "Pedido de recuperação inválido ou expirado"
    USER_NOT_FOUND = "Utilizador não encontrado"
    USER_ALREADY_REGISTERED = "Utilizador já registado"
    NO_PENDING_VERIFICATION = "Nenhum código de verificação pendente"
    CODE_EXPIRED = "Código expirado. Solicita um novo."
    CODE_INVALID = "Código inválido"
    EMAIL_ALREADY_VERIFIED = "Email já verificado"
    USER_NO_EMAIL = "Utilizador sem email associado"

    # JWT / session
    TOKEN_INVALID = "Token inválido ou expirado"
    AUTH_REQUIRED = "Autenticação necessária"

    # Account state
    ACCOUNT_BANNED = "Conta permanentemente banida."
    ACCOUNT_SUSPENDED = "Conta suspensa temporariamente."
    ACCOUNT_PENDING_DELETION = "Conta agendada para eliminação. Cancela em /users/me/cancel-deletion."
    GUEST_NOT_ALLOWED = "Cria uma conta para realizar esta ação."

    # Profile / password
    GUESTS_CANNOT_EDIT_PROFILE = "Convidados não podem alterar o perfil"
    NO_CHANGES_PROVIDED = "Nenhuma alteração fornecida"
    GOOGLE_CANNOT_CHANGE_EMAIL = "Contas Google não podem alterar o email"
    PASSWORD_REQUIRED_FOR_EMAIL_CHANGE = "A password atual é necessária para alterar o email"
    PASSWORD_INCORRECT = "Password atual incorreta"
    GUESTS_CANNOT_CHANGE_PASSWORD = "Convidados não podem alterar a password"
    GOOGLE_NO_PASSWORD = "Contas Google não têm password para alterar"
    PASSWORD_SAME_AS_CURRENT = "A nova password deve ser diferente da atual"

    # Beach
    BEACH_NOT_FOUND = "Praia não encontrada"
    BEACH_NO_FLAG_SYSTEM = "Esta praia não tem sistema de bandeiras"

    # Presence
    MUST_BE_AT_BEACH_REPORT = "Tens de estar na praia para submeter um aviso"
    MUST_BE_AT_BEACH_VOTE = "Tens de estar na praia para votar neste aviso"
    MUST_BE_AT_BEACH_FLAG = "Tens de estar na praia para propor uma bandeira"
    TOO_FAR_FROM_BEACH = "Estás demasiado longe desta praia para registar presença"
    OCCUPANCY_MUST_BE_AT_BEACH = "Deves estar (ou ter estado) na praia para reportar a ocupação."
    OCCUPANCY_ALREADY_REPORTED = "Já reportaste a ocupação desta praia recentemente."

    # Reports
    REPORT_NOT_FOUND_OR_EXPIRED = "Aviso não encontrado ou expirado"
    REPORT_NOT_FOUND = "Aviso não encontrado"
    REPORT_NOT_YOURS = "Não podes apagar avisos de outros utilizadores"

    # Flags
    NO_FLAG_TO_CONFIRM = "Não há bandeira para confirmar nesta praia"
    FLAG_ALREADY_CONFIRMED = "Já confirmaste a bandeira desta praia na última hora"

    # Favourites
    BEACH_ALREADY_FAVOURITE = "Praia já está nos favoritos"
    BEACH_NOT_FAVOURITE = "Praia não está nos favoritos"

    # Notifications
    TOKEN_NOT_FOUND = "Token não encontrado"

    # Privacy
    DELETE_CONFIRMATION_INVALID = "Confirmação inválida — escreve 'APAGAR' para confirmar"
    ACCOUNT_NOT_PENDING_DELETION = "A conta não está agendada para eliminação."

    @staticmethod
    def beach_slug_not_found(slug: str) -> str:
        return f"Praia '{slug}' não encontrada"

    @staticmethod
    def min_reputation(min_rep: int) -> str:
        return f"Reputação mínima necessária: {min_rep}"
