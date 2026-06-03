---
name: captain-hook
description: Send a status update to your chat channel via a bot-free incoming webhook — a plain HTTPS POST that needs nothing but a webhook URL (no bot, plugin, or pairing). Works from anywhere a shell runs — an interactive session, a one-off script, or a headless job — to push a self-contained status snippet (headline/verdict, the numbers that matter, status, blockers/decisions, what's next). One-way (post only). It's the only one of the three notifiers that works headless (cron/CI/background); for two-way updates that can read your replies in a live session, use qb-radio.
version: 1.0.0
triggers:
  - /captain-hook
---

# captain-hook — status updates via a bot-free webhook

captain-hook sends a **status update** to your chat channel via a **webhook** — a
plain HTTPS POST that needs nothing but a URL: no bot, no plugin, no pairing, no
live agent session. Use it for any status ping you want to fire from a shell.

Same job as [`qb-radio`](../qb-radio/SKILL.md) (notify your phone with a
self-contained snippet); the difference is **transport**, not purpose: qb-radio
goes through the channel **plugin** (two-way, needs a live `--channels` session),
captain-hook goes through a **webhook** (one-way, needs only a URL). Because a
webhook needs nothing else, captain-hook is the **only** option that works
**headless** — so it's the choice for cron, CI, and background runs — but it's
equally a zero-setup way to ping yourself from an interactive session or a one-off
script. ([`/monitor`](../monitor/SKILL.md) is the third sibling: passive
file-watch.)

<default_to_action>
Send via `scripts/captain-hook.sh` any time you want a status update out with no
setup beyond a webhook URL. (For two-way updates that read your replies in a live
session, use qb-radio.)
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
honestly.

**When to fire** — same checkpoint definition as [qb-radio](../qb-radio/SKILL.md#when-to-fire--what-a-meaningful-checkpoint-is-and-is-not):
fire at a **gate, a test/eval verdict, a blocker or decision needed, a
destructive/irreversible op (before & after), and final success/failure** — never
per-step (per-file, per-tool, "still running"). **Cadence depends on where it runs:**
from an agent/interactive context, fire it at each checkpoint yourself (the same
recurring discipline as qb-radio's [Durable cadence](../qb-radio/SKILL.md#durable-cadence--one-invocation--one-message));
from a script or scheduled job, place the `captain-hook.sh` call at each checkpoint
in the script (e.g. end of a CI stage or cron run) — there the runtime is the
trigger, so there's no in-context cadence to maintain.

## captain-hook vs qb-radio vs monitor
| | transport | needs | use when |
|---|---|---|---|
| **captain-hook** | chat **webhook** (HTTPS POST) | only a webhook URL | any status ping with zero setup — from a session, a script, or **headless** (cron/CI/background, where it's the only option); one-way |
| **qb-radio** | channel plugin `reply` | a live `--channels` session | interactive; can thread/attach; reads replies back |
| **monitor** | file-watch → relay | `fswatch` + a status-log file | long run appending a status log you tail remotely |

One-way by design: a webhook posts; it cannot read replies. For two-way
(answering a question, redirecting a run) use qb-radio or monitor.
