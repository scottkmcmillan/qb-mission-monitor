# How It Works

`qb-mission-monitor` lets you walk away from a long-running, autonomous Claude
Code coding session and still follow it from your phone — getting a ping at each
milestone, and able to reply with course corrections.

It has three moving parts, and the key idea is that **they are decoupled**.

```
┌─────────────────────────┐        appends         ┌──────────────────┐
│  Autonomous coding      │ ───────────────────▶   │  status_log.md   │
│  session (Claude Code)  │   one line per gate    │  (plain text)    │
└─────────────────────────┘                        └────────┬─────────┘
                                                            │ fswatch
                                                    watches │ content-diff
                                                            ▼
                                              ┌────────────────────────────┐
                                              │  /monitor skill            │
                                              │  (a 2nd Claude Code session│
                                              │   or the same one)         │
                                              └───────────┬────────────────┘
                                                          │ relay (concise)
                                  ┌───────────────────────┼───────────────────────┐
                                  ▼                       ▼                       ▼
                            ┌──────────┐           ┌──────────┐            ┌──────────┐
                            │ Discord  │           │ Telegram │            │  (other  │
                            │  plugin  │           │  plugin  │            │ channel) │
                            └──────────┘           └──────────┘            └──────────┘
                                  │                       │
                                  └────────── your phone ─┘
```

## 1. The status log 

The autonomous session writes a single plain-text file and appends one terse
line at every meaningful milestone (phase start, gate pass/fail, scores, final
result). See `STATUS-LOG-PATTERN.md`.

Because the interface is "a text file that grows," the producer doesn't need to
know anything about Discord, Telegram, or the monitor. Any process that writes
lines to a file — a Claude Code session, a CI script, a test harness — can be
monitored.

## 2. The monitor 

The `/monitor` skill watches the file with `fswatch` (macOS FSEvents; polling
fallback on Linux). On every change it computes a **content diff** — lines
present now but absent a moment ago — and relays only the new lines.

It uses a snapshot diff (`grep -Fxv`) rather than line-count tailing on purpose:
some orchestrators prepend newest-first, which breaks `tail -n +N`. The snapshot
diff catches new content wherever it lands in the file.

The monitor then does two things with each new line:
- prints it into the conversation, and
- relays a concise summary to the configured chat channel(s).

## 3. The channel 

Delivery rides on Claude Code's official **channel plugins**. A channel plugin
is an MCP server that bridges a chat app to your session: inbound messages
arrive as `<channel source="discord" chat_id="..." ...>` tags, and you reply
with the plugin's `reply` tool.

The monitor is channel-agnostic. It relays to Discord by default, but Telegram —
or any other `--channels` plugin — is a drop-in swap. You choose at session
launch with `claude --channels plugin:<name>@claude-plugins-official`. See
`CHANNELS.md`.

Because chat is bidirectional, this isn't just notifications: you can reply in
Discord/Telegram and the monitoring session sees your message, so you can answer
a question or redirect the autonomous run without returning to the terminal.

## Why decoupled matters

The three parts are independent — see
[`STATUS-LOG-PATTERN.md`](STATUS-LOG-PATTERN.md#why-this-approach) for the full
rationale (decoupled producer, swappable channels, multiple consumers).

One property specific to the monitor: it is **restart-safe**. The status log is
durable on disk, so if the monitor stops, the content diff resumes from the
current file state, with no gap for lines written while it was offline.
