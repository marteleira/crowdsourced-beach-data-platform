"""
General constants for the OndaCerta backend

All magic numbers and repeated literal values live here!
Import from this module instead of hard-coding values across routers/services
"""

# Presence / occupancy 
OCCUPANCY_WINDOW_MINUTES = 20        # heartbeat window for occupancy count
MAP_PRESENCE_WINDOW_MINUTES = 20     # heartbeat window shown on map overlay
CHECKIN_WINDOW_MINUTES = 180         # "you are at the beach" window for notifications

#  Gating windows 
REPORT_PRESENCE_WINDOW_HOURS = 1     # must have heartbeat within 1h to submit report
VOTE_PRESENCE_WINDOW_HOURS = 2       # must have heartbeat within 2h to vote
FLAG_PROPOSAL_WINDOW_MINUTES = 10    # must have heartbeat within 10min to propose flag

# Occupancy thresholds 
OCCUPANCY_LOW_RATIO = 0.40           # < this -> "low" (capacity-aware path)
OCCUPANCY_MEDIUM_RATIO = 0.75        # < this -> "medium" (capacity-aware path)
OCCUPANCY_LOW_THRESHOLD = 10         # < this -> "low" (headcount-only path)
OCCUPANCY_MEDIUM_THRESHOLD = 40      # < this -> "medium" (headcount-only path)

#  Reputation 
MIN_REPUTATION_TO_PROPOSE = 25       # minimum rep to propose a flag
REPORT_VERIFIED_NET_VOTES = 3        # upvotes - downvotes >= this -> verified

# Map privacy 
JITTER_DEGREES = 0.003               # ~300m latitude

# Reputation thresholds (all in one place)
AUTO_BAN_REPUTATION_THRESHOLD = -50
SUSPENSION_REPUTATION_THRESHOLD = -30
SUSPENSION_DURATION_HOURS = 48

# Flag confirmation cooldown
FLAG_CONFIRM_WINDOW_HOURS = 1        # one confirmation vote per user per beach per hour

# Heartbeat retention
HEARTBEAT_CLEANUP_HOURS = 2          # keep only the last N hours of heartbeats

# Beach recommendation scoring weights
RECOMMENDATION_WEIGHT_PROXIMITY  = 0.40
RECOMMENDATION_WEIGHT_FLAG       = 0.30
RECOMMENDATION_WEIGHT_OCCUPANCY  = 0.20
RECOMMENDATION_WEIGHT_ALERTS     = 0.10
RECOMMENDATION_PROXIMITY_RANGE_KM = 50.0   # distance at which proximity score reaches 0
RECOMMENDATION_ALERT_PENALTY_DIV  = 5.0    # alerts / this = penalty (capped at 1.0)

FLAG_RECOMMENDATION_SCORES: dict[str, float] = {
    "green": 1.0, "yellow": 0.6, "unknown": 0.4, "red": 0.1, "purple": 0.1,
}
OCCUPANCY_RECOMMENDATION_SCORES: dict[str, float] = {
    "low": 1.0, "medium": 0.6, "high": 0.2, "unknown": 0.5,
}

# Push notification labels / emojis
REPORT_TYPE_EMOJIS: dict[str, str] = {
    "jellyfish": "🪼",
    "strong_current": "⚡",
    "pollution": "🗑️",
    "rough_sea": "🌊",
    "other_alert": "⚠️",
}

FLAG_COLOR_EMOJIS: dict[str, str] = {
    "green": "🟢",
    "yellow": "🟡",
    "red": "🔴",
    "purple": "🟣",
    "unknown": "⚪",
}

SEVERITY_LABELS: dict[int, str] = {
    1: "Ligeiro",
    2: "Moderado",
    3: "Grave",
}
