# monitor.config.sh — copy to your project root and edit.
# The /monitor skill reads these defaults. All keys are optional.

# Path used when /monitor is called with no argument.
# Point this at the status log your autonomous coding session appends to.
MONITOR_DEFAULT_FILE="docs/status_log.md"

# Base directory for resolving relative paths (defaults to CWD if unset).
MONITOR_PROJECT_ROOT="/absolute/path/to/your/project"

# Default Discord channel/DM to relay updates to.
# Get this from a <channel source="discord" chat_id="..."> message after pairing.
MONITOR_DISCORD_CHAT_ID=""

# Default Telegram chat to relay updates to (if using Telegram instead of/also).
MONITOR_TELEGRAM_CHAT_ID=""
