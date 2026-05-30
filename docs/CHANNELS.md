# Channels — Discord, Telegram, and Beyond

The monitor relays through Claude Code's **channel plugins**. A channel plugin
is an MCP server that bridges a chat app to your session. The monitor calls the
active channel's `reply` tool and is otherwise channel-agnostic, so the delivery
layer is swappable.

## The common contract

Every channel plugin follows the same shape:

- **Inbound:** messages arrive in the session as
  `<channel source="<name>" chat_id="..." message_id="..." user="..." ts="...">`.
- **Outbound:** you reply with `mcp__plugin_<name>_<name>__reply`, passing the
  `chat_id` back.
- **Activation:** the plugin only connects when the session is launched with
  `--channels plugin:<name>@<marketplace>`.
- **Access:** only *paired* chats reach the session; pairing is approved from
  your terminal, never from a chat message.

Because the monitor relays to "whatever channel is active / configured," you
switch chat apps by switching the `--channels` flag — no skill edits.

## Discord (default)

```sh
claude --channels plugin:discord@claude-plugins-official
```

Relay tool: `mcp__plugin_discord_discord__reply`. Full bot setup in `SETUP.md`.

## Telegram (drop-in swap)

```sh
claude --channels plugin:telegram@claude-plugins-official
```

Relay tool: `mcp__plugin_telegram_telegram__reply`. Full bot setup in `SETUP.md`.

Telegram has no message history/search API — the session only sees messages as
they arrive. Discord exposes limited history via `fetch_messages`. Neither
difference affects monitoring (the monitor pushes; it doesn't read history).

## Run several at once

```sh
claude --channels plugin:discord@claude-plugins-official,plugin:telegram@claude-plugins-official
```

The monitor relays to each active channel. Useful for sending the same run to
both your Discord and a teammate's Telegram.

## Adding a different channel (Slack, SMS, custom)

Any MCP server that follows the inbound `<channel ...>` / outbound `reply`
contract works. To target a new one:

1. Install/point to the channel plugin and launch with its `--channels` ref.
2. In `skills/monitor/SKILL.md`, add the new relay tool under
   **Behavior on events** (e.g. `mcp__plugin_slack_slack__reply`), or simply let
   the skill relay to "whatever channel last messaged me," which already
   generalizes.

No other code changes. The status-log → fswatch → relay pipeline is identical;
only the final `reply` call differs.

## Choosing

| | Discord | Telegram |
|---|---|---|
| Setup friction | Higher (app + bot + server invite + intents) | Lower (BotFather, one token) |
| DM a bot | Must share a server | Direct |
| Threads / rich formatting | Strong | Basic |
| History/search to the bot | Limited (`fetch_messages`) | None |
| Good default for | Team servers, richer channels | Fast solo phone notifications |

Both support the full monitoring flow. Use whichever you already run on your
phone.
