---
name: captain-hook
description: Send a chat notification via a bot-free incoming webhook (HTTPS POST) — headless-safe, so it works in scripts, cron, CI, and background/scheduled/autonomous runs where the Claude Code channel plugin and a live agent session are not available. Each message is a self-contained, well-written status snippet (headline/verdict, the numbers that matter, status, blockers/decisions, what's next). For interactive sessions with a channel plugin connected, prefer qb-radio.
version: 1.0.0
triggers:
  - /captain-hook
---

# captain-hook — bot-free webhook notifier

The headless sibling of [`qb-radio`](../qb-radio/SKILL.md). Where qb-radio pushes
through the channel **plugin** (needs a live `--channels` session) and
[`/monitor`](../monitor/SKILL.md) watches a file, **captain-hook is a plain HTTPS
POST to a chat webhook** — no bot, no plugin, no agent session. That makes it the
notifier for **cron, CI, and background/scheduled runs**.

<default_to_action>
Send via `scripts/captain-hook.sh`. Use this (not the plugin/bot) whenever the
run is headless or no channel plugin is connected.
</default_to_action>

## Usage
```bash
scripts/captain-hook.sh "Nightly eval clean: 12/12, faithfulness 3.90/5"
scripts/captain-hook.sh --username "CI" "build 482 green"
scripts/captain-hook.sh --title "Mission COMPLETE" "20/20 oracle, ships Arm 1, 0 regressions"
some_command 2>&1 | scripts/captain-hook.sh --title "build log"
```
Exit codes: `0` sent (HTTP 2xx) · `1` no webhook URL / bad args · `2` send failed.

## One-time setup (the webhook URL is a SECRET — never hardcode/commit)
1. In Discord: **Channel → Edit Channel → Integrations → Webhooks → New Webhook →
   Copy URL** (`https://discord.com/api/webhooks/<id>/<token>`). (No bot, no
   pairing needed — a webhook posts to one channel, one-way.)
2. Make it available to the script (first found wins):
   - `export CAPTAIN_HOOK_WEBHOOK_URL='https://discord.com/api/webhooks/...'`  (best for CI/cron)
   - `echo 'https://discord.com/api/webhooks/...' > .captain-hook.url`  (gitignored; per-repo)
   - `echo 'https://discord.com/api/webhooks/...' > ~/.config/captain-hook/url`  (per-machine)

The script validates the URL is a real Discord webhook and refuses anything else;
`.captain-hook.url` is gitignored so a stored URL never lands in git. Other chat
apps (Slack, Teams) expose analogous incoming webhooks — see the **OTHER
CHANNELS** note at the bottom of `scripts/captain-hook.sh`.

## What to send & how to write it
Same bar as the [status-log pattern](../../docs/STATUS-LOG-PATTERN.md): a
**self-contained status snippet**, read on a phone with no other context —
**headline/verdict first**, then **the numbers that matter**, **status**, any
**blocker/decision/risk** (or explicit "no action needed"), and **what's next**.
Concise by default, thorough when the moment earns it. Surface bad news first and
honestly. Notify at meaningful checkpoints only — not per-step.

## captain-hook vs qb-radio vs monitor
| | transport | needs | use when |
|---|---|---|---|
| **captain-hook** | chat **webhook** (HTTPS POST) | only a webhook URL | headless — cron, CI, background/scheduled/autonomous runs, no plugin |
| **qb-radio** | channel plugin `reply` | a live `--channels` session | interactive; can thread/attach; reads replies back |
| **monitor** | file-watch → relay | `fswatch` + a status-log file | long run appending a status log you tail remotely |

One-way by design: a webhook posts; it cannot read replies. For two-way
(answering a question, redirecting a run) use qb-radio or monitor.
