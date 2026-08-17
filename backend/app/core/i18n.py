"""
Centralised bilingual (en/pt) strings for everything the backend renders
itself: HTTP error messages, push notification text, and email subject/body.

Replaces the old single-language app/core/messages.py. Keys double as the
"code" value returned to the client (see app/core/errors.py::api_error),
so there is one vocabulary for "what the client branches on" and "what
gets translated" instead of two.
"""
from app.core.language import DEFAULT_LANGUAGE, SUPPORTED_LANGUAGES

TRANSLATIONS: dict[str, dict[str, str]] = {
    # Auth
    "email_taken": {"en": "Email already registered", "pt": "Email já registado"},
    "email_in_use": {"en": "Email already in use", "pt": "Email já em uso"},
    "invalid_credentials": {"en": "Invalid credentials", "pt": "Credenciais inválidas"},
    "invalid_google_token": {"en": "Invalid Google token", "pt": "Token Google inválido"},
    "invalid_refresh_token": {"en": "Invalid or expired refresh token", "pt": "Refresh token inválido ou expirado"},
    "invalid_reset_request": {"en": "Invalid or expired reset request", "pt": "Pedido de recuperação inválido ou expirado"},
    "user_not_found": {"en": "User not found", "pt": "Utilizador não encontrado"},
    "user_already_registered": {"en": "User already registered", "pt": "Utilizador já registado"},
    "no_pending_verification": {"en": "No pending verification code", "pt": "Nenhum código de verificação pendente"},
    "code_expired": {"en": "Code expired. Request a new one.", "pt": "Código expirado. Solicita um novo."},
    "code_invalid": {"en": "Invalid code", "pt": "Código inválido"},
    "email_already_verified": {"en": "Email already verified", "pt": "Email já verificado"},
    "user_no_email": {"en": "User has no associated email", "pt": "Utilizador sem email associado"},

    # JWT / session
    "token_invalid": {"en": "Invalid or expired token", "pt": "Token inválido ou expirado"},
    "auth_required": {"en": "Authentication required", "pt": "Autenticação necessária"},

    # Account state
    "account_banned": {"en": "Account permanently banned.", "pt": "Conta permanentemente banida."},
    "account_suspended": {"en": "Account temporarily suspended.", "pt": "Conta suspensa temporariamente."},
    "account_pending_deletion": {
        "en": "Account scheduled for deletion. Cancel at /users/me/cancel-deletion.",
        "pt": "Conta agendada para eliminação. Cancela em /users/me/cancel-deletion.",
    },
    "guest_not_allowed": {"en": "Create an account to do this.", "pt": "Cria uma conta para realizar esta ação."},
    "reputation_below_threshold": {
        "en": "Reputation below {threshold}",
        "pt": "Reputação abaixo de {threshold}",
    },

    # Profile / password
    "guest_cannot_edit_profile": {"en": "Guests cannot edit their profile", "pt": "Convidados não podem alterar o perfil"},
    "no_changes_provided": {"en": "No changes provided", "pt": "Nenhuma alteração fornecida"},
    "google_cannot_change_email": {"en": "Google accounts cannot change email", "pt": "Contas Google não podem alterar o email"},
    "password_required_for_email_change": {
        "en": "Current password is required to change email",
        "pt": "A password atual é necessária para alterar o email",
    },
    "password_incorrect": {"en": "Incorrect current password", "pt": "Password atual incorreta"},
    "guest_cannot_change_password": {"en": "Guests cannot change their password", "pt": "Convidados não podem alterar a password"},
    "google_no_password": {"en": "Google accounts have no password to change", "pt": "Contas Google não têm password para alterar"},
    "password_same_as_current": {
        "en": "New password must be different from the current one",
        "pt": "A nova password deve ser diferente da atual",
    },

    # Beach
    "beach_not_found": {"en": "Beach not found", "pt": "Praia não encontrada"},
    "beach_slug_not_found": {"en": "Beach '{slug}' not found", "pt": "Praia '{slug}' não encontrada"},
    "beach_no_flag_system": {"en": "This beach has no flag system", "pt": "Esta praia não tem sistema de bandeiras"},

    # Presence
    "must_be_at_beach_report": {
        "en": "You must be at the beach to submit a report",
        "pt": "Tens de estar na praia para submeter um aviso",
    },
    "must_be_at_beach_vote": {
        "en": "You must be at the beach to vote on this report",
        "pt": "Tens de estar na praia para votar neste aviso",
    },
    "must_be_at_beach_flag": {
        "en": "You must be at the beach to propose a flag",
        "pt": "Tens de estar na praia para propor uma bandeira",
    },
    "too_far_from_beach": {
        "en": "You are too far from this beach to register presence",
        "pt": "Estás demasiado longe desta praia para registar presença",
    },
    "occupancy_must_be_at_beach": {
        "en": "You must be (or have been) at the beach to report occupancy.",
        "pt": "Deves estar (ou ter estado) na praia para reportar a ocupação.",
    },
    "occupancy_already_reported": {
        "en": "You already reported this beach's occupancy recently.",
        "pt": "Já reportaste a ocupação desta praia recentemente.",
    },

    # Reports
    "report_rate_limited": {
        "en": "You already reported this event at this beach recently, please wait before submitting again.",
        "pt": "Já reportaste este evento nesta praia recentemente, por favor espera antes de submeter de novo.",
    },
    "report_not_found_or_expired": {"en": "Report not found or expired", "pt": "Aviso não encontrado ou expirado"},
    "report_not_found": {"en": "Report not found", "pt": "Aviso não encontrado"},
    "report_not_yours": {"en": "You cannot delete other users' reports", "pt": "Não podes apagar avisos de outros utilizadores"},

    # Flags
    "no_flag_to_confirm": {"en": "There is no flag to confirm at this beach", "pt": "Não há bandeira para confirmar nesta praia"},
    "flag_already_set": {
        "en": "This beach already has a flag set. Confirm or contest it instead of proposing a new one.",
        "pt": "Esta praia já tem uma bandeira definida. Confirma ou contesta-a em vez de propor uma nova.",
    },
    "flag_already_confirmed": {
        "en": "You already confirmed this beach's flag in the last hour",
        "pt": "Já confirmaste a bandeira desta praia na última hora",
    },
    "flag_applied": {
        "en": "Flag automatically updated based on your reputation",
        "pt": "Bandeira atualizada automaticamente com base na tua reputação",
    },
    "flag_pending": {
        "en": "Proposal submitted. Awaiting community confirmation.",
        "pt": "Proposta submetida. Aguarda confirmação da comunidade.",
    },

    # Favourites
    "beach_already_favourite": {"en": "Beach is already a favourite", "pt": "Praia já está nos favoritos"},
    "beach_not_favourite": {"en": "Beach is not a favourite", "pt": "Praia não está nos favoritos"},

    # Notifications
    "token_not_found": {"en": "Token not found", "pt": "Token não encontrado"},

    # Privacy
    "delete_confirmation_invalid": {
        "en": "Invalid confirmation — type 'APAGAR' to confirm",
        "pt": "Confirmação inválida — escreve 'APAGAR' para confirmar",
    },
    "account_not_pending_deletion": {
        "en": "Account is not scheduled for deletion.",
        "pt": "A conta não está agendada para eliminação.",
    },
    "account_deletion_already_scheduled": {
        "en": "Account is already scheduled for deletion.",
        "pt": "A conta já está agendada para eliminação.",
    },
    "account_deletion_scheduled": {
        "en": "Account scheduled for deletion in {days} days. You can cancel before that date.",
        "pt": "Conta agendada para eliminação em {days} dias. Podes cancelar antes dessa data.",
    },
    "account_deletion_cancelled": {
        "en": "Deletion cancelled. The account was restored.",
        "pt": "Eliminação cancelada. A conta foi restaurada.",
    },

    # Generic data-not-available 404s
    "no_bus_stops": {"en": "No bus stops for this beach", "pt": "Sem paragens de autocarro para esta praia"},
    "no_water_quality_data": {"en": "No water quality data for this beach", "pt": "Sem dados de qualidade da água para esta praia"},
    "no_tide_data": {"en": "No tide data for this beach", "pt": "Sem dados de marés para esta praia"},
    "no_weather_data": {"en": "No weather data for this beach", "pt": "Sem dados meteorológicos para esta praia"},
    "no_sea_data": {"en": "No sea state data for this beach", "pt": "Sem dados do estado do mar para esta praia"},

    # Reputation / access
    "insufficient_reputation": {
        "en": "Minimum reputation required: {min_rep}",
        "pt": "Reputação mínima necessária: {min_rep}",
    },
    "not_present": {"en": "You are not currently present at this beach", "pt": "Não estás presentemente na praia"},

    # Validation (Pydantic)
    "password_too_short": {"en": "Password must be at least 8 characters", "pt": "A password deve ter pelo menos 8 caracteres"},
    "name_length_invalid": {"en": "Name must be between 1 and 50 characters", "pt": "Nome deve ter entre 1 e 50 caracteres"},
    "invalid_avatar_id": {"en": "Invalid avatar: {avatar_id}", "pt": "Avatar inválido: {avatar_id}"},
    "invalid_report_type": {"en": "Invalid report type. Must be one of: {valid_types}", "pt": "Tipo de aviso inválido. Tem de ser um de: {valid_types}"},
    "invalid_severity": {"en": "Severity must be between 1 and 3", "pt": "A severidade deve estar entre 1 e 3"},
    "level_out_of_range": {"en": "Level must be between 1 and 5", "pt": "O nível deve estar entre 1 e 5"},

    # Push notifications — alert types
    "alert_type_jellyfish": {"en": "Jellyfish", "pt": "Alforrecas"},
    "alert_type_strong_current": {"en": "Strong Current", "pt": "Corrente Forte"},
    "alert_type_pollution": {"en": "Pollution", "pt": "Poluição"},
    "alert_type_rough_sea": {"en": "Rough Sea", "pt": "Mar Agitado"},
    "alert_type_other_alert": {"en": "Alert", "pt": "Aviso"},

    # Push notifications — severity
    "severity_1": {"en": "Low", "pt": "Baixa"},
    "severity_2": {"en": "Medium", "pt": "Média"},
    "severity_3": {"en": "High", "pt": "Alta"},

    # Push notifications — flag colors
    "flag_color_green": {"en": "green", "pt": "verde"},
    "flag_color_yellow": {"en": "yellow", "pt": "amarela"},
    "flag_color_red": {"en": "red", "pt": "vermelha"},
    "flag_color_purple": {"en": "purple", "pt": "roxa"},
    "flag_color_unknown": {"en": "unknown", "pt": "desconhecida"},

    # Push notifications — templates
    "push_report_body": {"en": "Report submitted. Severity: {severity}.", "pt": "Aviso reportado. Severidade: {severity}."},
    "push_flag_title": {"en": "Flag changed · {beach_name}", "pt": "Bandeira alterada · {beach_name}"},
    "push_flag_body": {
        "en": "The flag changed from {old_color} to {new_color}.",
        "pt": "A bandeira mudou de {old_color} para {new_color}.",
    },

    # Emails
    "email_verify_subject": {"en": "OndaCerta — verify your email", "pt": "OndaCerta — verifica o teu email"},
    "email_verify_body": {
        "en": "Your verification code is: {code}\n\nIt expires in {minutes} minutes.",
        "pt": "O teu código de verificação é: {code}\n\nExpira em {minutes} minutos.",
    },
    "email_reset_subject": {"en": "OndaCerta — password recovery", "pt": "OndaCerta — recuperação de password"},
    "email_reset_body": {
        "en": "Your password reset code is: {code}\n\nIt expires in {minutes} minutes. If you didn't request this, ignore this email.",
        "pt": "O teu código de recuperação de password é: {code}\n\nExpira em {minutes} minutos. Se não pediste isto, ignora este email.",
    },
}


def t(key: str, lang: str = DEFAULT_LANGUAGE, **params) -> str:
    lang = lang if lang in SUPPORTED_LANGUAGES else DEFAULT_LANGUAGE
    entry = TRANSLATIONS.get(key) or {}
    text = entry.get(lang) or entry.get(DEFAULT_LANGUAGE) or key
    try:
        return text.format(**params) if params else text
    except (KeyError, IndexError):
        return text
