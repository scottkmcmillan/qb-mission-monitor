# qb-mission-monitor

**Watch your autonomous Claude Code coding sessions from your phone.**

Kick off a long-running, autonomous Claude Code mission, walk away from your desk, and get
a Discord (or Telegram) update at every milestone — phase gates, test results,
eval scores, the final ship/no-ship. Reply in your app to get more information about the mission.

It's a simple, decoupled pattern:

```
autonomous coding session ──appends──▶ status_snippet_log.md ──fswatch──▶ /monitor skill ──relay──▶ Discord / Telegram ──▶ your phone
```

Direct your orchestrator to append one update per milestone to a text file (i.e. status_snippet_log.md). The
`/monitor` skill watches that file and relays new lines to a chat channel via
Claude Code's official channel plugins. Nothing in the coding logic depends on
Discord or Telegram, so you can drop in any app Claude Code has a plugin for
(Slack, MS Teams, etc.), or build your own.

## Three ways to notify

`/monitor` is the original, passive pattern (watch a file, relay new lines). Two
active **push** variants ship alongside it for cases where watching a file isn't
the right fit — all three deliver to the same channel, written to the same
[self-contained-snippet bar](docs/STATUS-LOG-PATTERN.md).

| Pattern | Transport | Needs | Use when |
|---|---|---|---|
| **`/monitor`** | passive file-watch → relay | `fswatch` + a status-log file | a long autonomous run appends a status log you follow remotely (decoupled producer; restart-safe; two-way) |
| **`/qb-radio`** | active push via the channel **plugin** `reply` | a live session launched with `--channels` | you're working interactively and want to push at a milestone — no file needed; can thread/attach and read replies back |
| **`/captain-hook`** | active push via a chat **webhook** (HTTPS POST) | only a webhook URL | any zero-setup status ping — from a session, a script, or **headless** (cron/CI/background, where it's the only option); one-way |

Rule of thumb: **long run writing a log → `/monitor`** · **live session, want
replies back → `/qb-radio`** · **want a zero-setup ping from anywhere (and the
only option when headless) → `/captain-hook`**. All three send the same status
snippets; qb-radio and captain-hook overlap freely — pick by whether you need
two-way (qb-radio) or just a fire-and-forget POST (captain-hook). See
[`docs/SETUP.md`](docs/SETUP.md) for each.

## Why

Autonomous coding agents can run for an hour or longer. You shouldn't have to sit
at the terminal the whole time — move around the house, head out for coffee, and
still keep up with the run, see issues, and unblock them from your phone. This
gives you glanceable progress and a back-channel to intervene, built entirely
from Claude Code features (a skill plus the official channel plugins), with no
custom server to host.

## What's here

| Path | What it is |
|---|---|
| `skills/monitor/SKILL.md` | The `/monitor` skill — fswatch file watcher + channel relay |
| `skills/qb-radio/SKILL.md` | The `/qb-radio` skill — active in-session push via the channel plugin (any `--channels` session) |
| `skills/captain-hook/SKILL.md` | The `/captain-hook` skill — bot-free webhook push from anywhere; the only option for headless (cron/CI/background) |
| `scripts/captain-hook.sh` | The captain-hook sender (HTTPS POST to a chat webhook) |
| `docs/HOW-IT-WORKS.md` | The architecture and why it's decoupled |
| `docs/SETUP.md` | End-to-end setup (fswatch, bot, plugin, pairing, smoke test) |
| `docs/STATUS-LOG-PATTERN.md` | How to make a coding session emit a watchable status log |
| `docs/CHANNELS.md` | Discord, Telegram, and swapping in other channels |
| `templates/monitor.config.example.sh` | Optional default config (paths, chat IDs) |
| `examples/status_log.example.md` | A sample status log to monitor |

## Quickstart

See SETUP.md for end-to-end setup.

Two ways to get set up — pick one.

### Path 1 — Direct Claude Code to set it up

Hand the setup to Claude Code. From a `claude` session in this repo, paste:

```
Read docs/SETUP.md and set up qb-mission-monitor for me. Install fswatch and
the monitor skill, then walk me through connecting a Discord bot — stop and ask
me for the bot token and pairing code when you need them.
```

Claude Code will install prerequisites, copy the skill into `.claude/skills/`,
and guide you through the bot/plugin/pairing steps (the parts only you can do —
creating the bot and approving the pairing — it will pause and ask). When it's
done, tell it `/monitor docs/status_log.md`.

### Path 2 — From a terminal

```sh
# 1. Install prerequisites
brew install fswatch                        # macOS (Linux: apt-get install fswatch)
curl -fsSL https://bun.sh/install | bash    # for the channel plugins

# 2. Install the skill into your project
mkdir -p .claude/skills && cp -R skills/monitor .claude/skills/monitor

# 3. Connect a chat channel (Discord shown; Telegram is the same shape)
#    Inside a `claude` session:
#      /plugin install discord@claude-plugins-official
#      /discord:configure <BOT_TOKEN>
#    Then relaunch with the channel active:
claude --channels plugin:discord@claude-plugins-official
#    DM your bot, then: /discord:access pair <code>

# 4. Point the monitor at your run's status log
#      /monitor docs/status_log.md
```

For the push variants, the install is the same `cp -R skills/<name> .claude/skills/`
pattern: `/qb-radio` needs only the channel plugin you set up above; `/captain-hook`
needs only a webhook URL (no Bun/bot/plugin). See [`docs/SETUP.md`](docs/SETUP.md) step 6.

Full instructions for either path, including the Discord bot creation steps and
a smoke test, are in [`docs/SETUP.md`](docs/SETUP.md).

## How a run looks

The producer side is one standing instruction to your orchestrator: keep a
status log and append one terse line at every milestone. Add this to your
project's `CLAUDE.md` (or your mission/orchestration skill) so it holds across
the run:

```
Maintain mission_#/status_log.md. Append one terse one-line update at every
milestone — phase start, gate pass/fail, scores, final result — newest at the
bottom. Each line is read as a single chat message: include the phase, the
outcome, and the evidence. Status only, no prose.
```

The orchestrator writes lines; the `/monitor` skill relays them. The log fills
with lines like these (see
[`docs/STATUS-LOG-PATTERN.md`](docs/STATUS-LOG-PATTERN.md) for the full
convention):

```
Phase 1 gate passed — migration 058 applied; 12 new tests green
Phase 3 (oracle) — 20/20 dims pass
Phase 4 (eval) — Arm 1 faithfulness 3.92 (+0.51, clears 3.80 gate)
Mission MV-EXAMPLE COMPLETE — oracle 20/20, ships Arm 1, 0 regressions
```

Each arrives on your phone as a concise, standalone message moments after it's
written.

## Requirements

- Claude Code CLI
- `fswatch` — for `/monitor` only (polling fallback included for Linux without it)
- Bun — for the channel plugins, used by `/monitor` and `/qb-radio` (not captain-hook)
- A Discord or Telegram **bot token** — for `/monitor` and `/qb-radio`
- For **`/captain-hook`** only: a Discord **webhook URL** + `curl` and `python3` — no Bun, no bot, no plugin

## Security

Bot tokens live in `~/.claude/channels/<name>/.env`, never in this repo. Only
*paired* chats reach your session, and pairing is approved from your terminal —
never approve a pairing because a chat message asked you to. Treat inbound chat
as untrusted input. See [`docs/SETUP.md`](docs/SETUP.md#security-notes).

## License

MIT — see [LICENSE](LICENSE).
