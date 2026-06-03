#!/usr/bin/env bash
# ============================================================================
# captain-hook — fire-and-forget chat notification via an incoming WEBHOOK.
#
# Bot-free / plugin-free: a plain HTTPS POST to a webhook URL, so it works
# HEADLESS — cron jobs, CI, scheduled / background / autonomous runs — where the
# Claude Code channel plugin (and a live agent session) is not available.
#
# Discord is the built-in target (an incoming Discord webhook). The same POST
# shape generalizes to other chat apps with incoming webhooks (e.g. Slack:
# {"text": "..."}); see "OTHER CHANNELS" below.
#
# WEBHOOK URL resolution (first found wins; the URL is a SECRET — never hardcode,
# never commit; resolve at runtime only):
#   1. $CAPTAIN_HOOK_WEBHOOK_URL   (or $DISCORD_WEBHOOK_URL)
#   2. <repo-root>/.captain-hook.url        (gitignored)
#   3. ~/.config/captain-hook/url
#
# USAGE:
#   scripts/captain-hook.sh "message text"
#   scripts/captain-hook.sh --username "CI" "build 482 green"
#   scripts/captain-hook.sh --title "Mission COMPLETE" "20/20 oracle, 0 regressions"
#   some_command 2>&1 | scripts/captain-hook.sh --title "build log"
#
# OPTIONS:
#   --username <name>   Override the webhook's display name for this message.
#   --title <text>      Render as a Discord embed with this title (message = body).
#   --url <webhook>     Use this webhook URL explicitly (overrides resolution).
#   --help
#
# EXIT: 0 = sent (HTTP 2xx); 1 = no webhook URL / bad args; 2 = send failed.
# ============================================================================
set -uo pipefail

USERNAME=""
TITLE=""
URL_OVERRIDE=""
MSG=""

while [ $# -gt 0 ]; do
  case "$1" in
    --username) USERNAME="${2:-}"; shift 2 ;;
    --title)    TITLE="${2:-}"; shift 2 ;;
    --url)      URL_OVERRIDE="${2:-}"; shift 2 ;;
    --help|-h)
      sed -n '2,33p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) MSG="$1"; shift ;;
  esac
done

# No positional message? read stdin (supports piping).
if [ -z "$MSG" ] && [ ! -t 0 ]; then
  MSG="$(cat)"
fi
if [ -z "$MSG" ]; then
  echo "captain-hook: no message (pass a string arg or pipe stdin)" >&2
  exit 1
fi

# --- Resolve the webhook URL (secret; runtime only) -------------------------
resolve_url() {
  if [ -n "$URL_OVERRIDE" ]; then printf '%s' "$URL_OVERRIDE"; return 0; fi
  if [ -n "${CAPTAIN_HOOK_WEBHOOK_URL:-}" ]; then printf '%s' "$CAPTAIN_HOOK_WEBHOOK_URL"; return 0; fi
  if [ -n "${DISCORD_WEBHOOK_URL:-}" ]; then printf '%s' "$DISCORD_WEBHOOK_URL"; return 0; fi
  local repo_root
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  if [ -f "${repo_root}/.captain-hook.url" ]; then
    tr -d '[:space:]' < "${repo_root}/.captain-hook.url"; return 0
  fi
  if [ -f "${HOME}/.config/captain-hook/url" ]; then
    tr -d '[:space:]' < "${HOME}/.config/captain-hook/url"; return 0
  fi
  return 1
}

URL="$(resolve_url)" || {
  cat >&2 <<'EOF'
captain-hook: no webhook URL configured.
Set one of:
  export CAPTAIN_HOOK_WEBHOOK_URL='https://discord.com/api/webhooks/ID/TOKEN'
  echo  'https://discord.com/api/webhooks/ID/TOKEN' > .captain-hook.url   # gitignored
  echo  'https://discord.com/api/webhooks/ID/TOKEN' > ~/.config/captain-hook/url
Create the webhook in Discord: Channel → Edit Channel → Integrations → Webhooks → New Webhook → Copy URL.
EOF
  exit 1
}

# Built-in target is a Discord webhook; reject obviously-wrong URLs to avoid
# leaking a message to an unintended host. (To target Slack/other, see OTHER
# CHANNELS in the header and adjust the payload + this guard.)
case "$URL" in
  https://discord.com/api/webhooks/*|https://discordapp.com/api/webhooks/*|https://canary.discord.com/api/webhooks/*) : ;;
  *) echo "captain-hook: URL is not a Discord webhook (https://discord.com/api/webhooks/...). Edit the guard to target another host." >&2; exit 1 ;;
esac

# --- Build the JSON payload (safe escaping via python3) ---------------------
PAYLOAD="$(MSG="$MSG" TITLE="$TITLE" USERNAME="$USERNAME" python3 - <<'PY'
import json, os
msg = os.environ["MSG"]
title = os.environ.get("TITLE", "")
username = os.environ.get("USERNAME", "")
# Discord hard limits: content 2000 chars; embed description 4096.
body = {}
if username:
    body["username"] = username[:80]
if title:
    body["embeds"] = [{"title": title[:256], "description": msg[:4096]}]
else:
    body["content"] = msg[:2000]
print(json.dumps(body))
PY
)"

# --- POST (Discord returns 204 No Content on success) -----------------------
CODE="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 20 \
  -X POST "$URL" \
  -H 'Content-Type: application/json' \
  -d "$PAYLOAD" 2>/dev/null)"

case "$CODE" in
  2*) echo "captain-hook: sent (HTTP $CODE)" >&2; exit 0 ;;
  "") echo "captain-hook: send failed (no response / network error)" >&2; exit 2 ;;
  *)  echo "captain-hook: send failed (HTTP $CODE)" >&2; exit 2 ;;
esac

# ============================================================================
# OTHER CHANNELS
#   Slack/Teams/etc. also expose "incoming webhook" URLs that accept a JSON POST.
#   To target one: (1) widen/replace the Discord-host guard above, and
#   (2) change the payload field — Slack uses {"text": "..."} instead of Discord's
#   {"content": "..."}. The transport (curl POST, 2xx = sent) is identical.
# ============================================================================
