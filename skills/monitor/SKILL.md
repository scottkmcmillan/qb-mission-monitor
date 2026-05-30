---
name: monitor
description: Real-time file monitoring — watches a file for changes and relays new content into the conversation and out to a chat channel (Discord/Telegram)
version: 1.0.0
triggers:
  - /monitor
---

# File Monitor Skill

Watch a file for changes in real time and relay new or changed content into the
conversation **and** out to a chat channel (Discord, Telegram, or any other
configured `--channels` plugin). This is the mechanism that lets a developer
follow a long-running autonomous Claude Code session from their phone.

The canonical target is a **status log** that an autonomous coding session
appends to at each milestone (see `docs/STATUS-LOG-PATTERN.md`), but it works on
any text file that changes over time.

## Usage

```
/monitor path/to/status_log.md
```

Stop monitoring:

```
/monitor stop
```

## Configuration

The skill reads optional defaults from `monitor.config.sh` if present in the
project root (copy from `templates/monitor.config.example.sh`). Recognized keys:

- `MONITOR_DEFAULT_FILE` — path used when `/monitor` is called with no argument.
- `MONITOR_PROJECT_ROOT` — base for resolving relative paths (defaults to the
  current working directory).
- `MONITOR_DISCORD_CHAT_ID` — default Discord channel to relay to.
- `MONITOR_TELEGRAM_CHAT_ID` — default Telegram channel to relay to.

If no config file exists, resolve relative paths from the current working
directory and relay to whatever channel the most recent inbound
`<channel ...>` message came from.

## Instructions

When the user invokes `/monitor <path>`:

1. **Resolve the path.** If relative, resolve against `MONITOR_PROJECT_ROOT`
   (or the current working directory). If no path is given, use
   `MONITOR_DEFAULT_FILE`. Verify the file exists; if not, say so and stop.

2. **Check for `fswatch`.** Run `which fswatch`. If missing, install it
   (macOS: `brew install fswatch`; Linux: `apt-get install fswatch` or
   distro equivalent). On Linux without fswatch, fall back to the polling
   loop in the note below.

3. **Start the monitor.** Use the Monitor tool (or a background Bash task) with
   this command. Set `persistent: true` and `timeout_ms: 3600000`.

```sh
FILE='<resolved-path>'
SNAP=$(mktemp)
cp "$FILE" "$SNAP" 2>/dev/null || : > "$SNAP"
fswatch -o "$FILE" | while read -r _; do
  # Emit lines present now but absent in the snapshot, in file order.
  # Position-agnostic: handles append (new at bottom), prepend (new at top),
  # and mid-file inserts. Writers are inconsistent about ordering.
  NEW=$(grep -Fxv -f "$SNAP" "$FILE" | grep -E '.')
  if [ -n "$NEW" ]; then
    printf '%s\n' "$NEW"
  fi
  cp "$FILE" "$SNAP"
done
```

4. **Confirm** with one line: "Monitoring `<path>` — I'll relay changes as they
   happen."

When the user invokes `/monitor stop`:

1. Find the active monitor task ID and call `TaskStop` on it.
2. Confirm: "Monitor stopped."

## Behavior on events

When the monitor fires a notification:

- **Always** relay the new content directly in the conversation.
- **Always** relay to the configured chat channel:
  - **Discord:** `mcp__plugin_discord_discord__reply` with the configured
    `chat_id` (`MONITOR_DISCORD_CHAT_ID`). If a more recent
    `<channel source="discord" ...>` message appears in the conversation, use
    that `chat_id` instead.
  - **Telegram:** if a `<channel source="telegram" ...>` message is present (or
    `MONITOR_TELEGRAM_CHAT_ID` is set), relay there with
    `mcp__plugin_telegram_telegram__reply`.
  - Any other configured channel plugin works the same way — reply with its
    `chat_id`.
- Keep relay messages **concise**. Summarize the key data points (phase, status,
  pass/fail, scores) rather than dumping raw lines. Include enough context that
  the message stands alone in the chat app.

## Why content-diff, not line-count

Earlier versions used `tail -n +N` keyed on line count, which assumes new
entries are appended at the end. Some orchestrators *prepend* newest-first, so a
tail-based diff re-reads the same stale bottom line forever and silently drops
real updates. The `grep -Fxv` snapshot diff emits whatever is genuinely new
regardless of where it lands.

**Caveat:** a newly-added line that is byte-for-byte identical to an existing
line is suppressed (rare for status logs, which carry unique phase/timestamp
detail). If your writer can emit exact duplicates and you need every one,
include a timestamp or sequence number on each line.

## Linux fallback (no fswatch)

If `fswatch` can't be installed, poll the file instead:

```sh
FILE='<resolved-path>'
SNAP=$(mktemp)
cp "$FILE" "$SNAP" 2>/dev/null || : > "$SNAP"
while true; do
  if ! cmp -s "$FILE" "$SNAP"; then
    NEW=$(grep -Fxv -f "$SNAP" "$FILE" | grep -E '.')
    [ -n "$NEW" ] && printf '%s\n' "$NEW"
    cp "$FILE" "$SNAP"
  fi
  sleep 2
done
```
