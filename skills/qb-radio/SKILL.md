---
name: qb-radio
description: Push a status update to your chat channel from the CURRENT Claude Code session using the active channel plugin's reply tool. Invokable in any session launched with --channels — no file watcher, no separate monitor session. Each message is a self-contained, well-written status snippet (headline/verdict, the numbers that matter, status, blockers/decisions, what's next), concise by default and thorough when the moment earns it. For headless runs with no plugin (cron/CI/background), use captain-hook instead.
version: 1.0.0
triggers:
  - /qb-radio
---

# qb-radio — active in-session status push

Where [`/monitor`](../monitor/SKILL.md) *passively watches a file* and relays new
lines, **qb-radio is the active push**: the agent doing the work sends an update
straight to your chat channel at a milestone — no status-log file required. Use
it when you're running interactively (a session launched with `--channels`) and
want to ping yourself at a gate, a result, or a blocker.

<default_to_action>
Send the update now: call the active channel plugin's `reply` tool with the
configured `chat_id` and a well-framed status snippet (below).
</default_to_action>

## How to send

1. The channel plugin's `reply` tool is provided by the `--channels` plugin
   (load via your tool-search mechanism if deferred). For Discord it is
   `mcp__plugin_discord_discord__reply`; for Telegram,
   `mcp__plugin_telegram_telegram__reply`; any channel plugin follows the same
   `reply(chat_id, text)` shape (see [`docs/CHANNELS.md`](../../docs/CHANNELS.md)).

2. Call it with the destination `chat_id`:
   ```
   reply({ chat_id: "<YOUR_CHAT_ID>", text: "<status snippet>" })
   ```
   - **`chat_id`** resolution, in order: the most recent inbound
     `<channel source="..." chat_id="...">` message in the conversation → else
     `MONITOR_DISCORD_CHAT_ID` / `MONITOR_TELEGRAM_CHAT_ID` from `monitor.config.sh`.
     Never hardcode a chat ID in the skill.
   - `reply_to`: set to a `message_id` only when quote-replying to a specific
     earlier message; omit for a normal push (so the notification fires).
   - Most plugins also accept `files: ["/abs/path.png"]` to attach a screenshot
     or log.

3. Your plain text output is **not** seen in the chat app — only what goes
   through the `reply` tool reaches the user's phone.

## What to send & how to write it

Same bar as the [status-log pattern](../../docs/STATUS-LOG-PATTERN.md): every
message is a **self-contained status snippet** — assume it's read on a phone with
no other context. Include, as applicable:

- **Headline / verdict first** — ✅/⚠️/❌ + what happened, in one line.
- **The numbers that matter** — results/metrics/counts that decide the outcome
  (curated, not raw logs).
- **Status** — done · in-progress (with progress, e.g. step 17/52) · blocked.
- **Anything actionable or surprising** — blockers, a decision the user must
  make, risks, regressions, incidents, or an explicit "no action needed."
- **What's next / ETA.**

Write it concise by default, thorough when the moment earns it (a result, an
incident, a go/no-go). Lead with the headline; quantify; name the run/job/metric;
surface bad news first and honestly. Push at **meaningful checkpoints only** — a
gate, a result, a blocker, a final outcome — never per-step chatter.

Example:
```
reply({ chat_id: "<YOUR_CHAT_ID>", text:
"✅ Build+test green — ready to ship.
• 142/142 tests pass, coverage 87% (+2)
• migration 058 applied, 0 data loss
Next: opening the PR. No action needed." })
```

## qb-radio vs monitor vs captain-hook

| | transport | needs | use when |
|---|---|---|---|
| **qb-radio** | active push via channel plugin `reply` | a live session launched with `--channels` | you're working interactively and want to ping at a milestone; can thread/attach |
| **monitor** | passive file-watch → relay | `fswatch` + a status-log file | a long autonomous run that appends a status log you tail remotely |
| **captain-hook** | active push via chat **webhook** (HTTPS POST) | only a webhook URL | headless — cron, CI, background/scheduled runs with no plugin or live agent |

Same channel, same snippet framing — pick the transport that fits the runtime.
If no channel plugin is connected in this session, fall back to
[`captain-hook`](../captain-hook/SKILL.md).
