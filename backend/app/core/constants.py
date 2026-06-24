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
