# Import all models so Alembic autogenerate picks them up
from app.models.beach import Beach  # noqa: F401
from app.models.user import User, RefreshToken, ReputationEvent  # noqa: F401
from app.models.report import Report, ReportVote  # noqa: F401
from app.models.beach_status import (  # noqa: F401
    BeachStatus, FlagProposal, FlagConfirmation, OccupancyHeartbeat, OccupancyReport,
)
from app.models.snapshot import ApiSnapshot  # noqa: F401
from app.models.user_extended import UserFavourite, PushToken, UserAchievement  # noqa: F401
from app.models.tide_model import TideObservation, TideModelCoef  # noqa: F401
