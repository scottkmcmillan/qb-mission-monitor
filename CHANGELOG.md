# Changelog

All notable changes to **qb-mission-monitor**. Date-based entries; newest first.

## 2026-06-03

### Added
- **`/qb-radio` skill** — active, in-session status push via the channel plugin's
  `reply` tool. Works in any session launched with `--channels`; no status-log
  file or separate watcher needed; two-way (it can read replies).
- **`/captain-hook` skill + `scripts/captain-hook.sh`** — bot-free webhook
  notifier (plain HTTPS POST to a chat webhook). Headless-safe for cron, CI, and
  background/scheduled runs where no channel plugin or live agent exists. One-way.
  Discord-native, with a documented path to other incoming-webhook chat apps.
- **"Three ways to notify"** guidance — a comparison of `/monitor` (passive
  file-watch), `/qb-radio` (plugin push), and `/captain-hook` (webhook push)
  across README, `docs/HOW-IT-WORKS.md`, and `docs/SETUP.md` (new step 6). All
  three share one channel and the same self-contained status-snippet bar.

### Changed
- README Requirements clarified per pattern (`/captain-hook` needs only a webhook
  URL + `curl`/`python3` — no Bun, bot, or plugin).
- `LICENSE` — corrected the copyright holder spelling to **Quarterback AI Inc.**

### Security
- `.gitignore` now covers `.captain-hook.url` / `*.captain-hook.url`. The webhook
  URL is a bearer secret, resolved at runtime from an env var or a gitignored
  file — never hardcoded or committed. Added a webhook-secret note to
  `docs/SETUP.md`.
- Pre-publish secrets/PII audit + `gitleaks` history scan: clean.

## 2026-05 — initial

- **`/monitor` skill** — `fswatch` file-watch → channel relay, the original
  pattern for following a long autonomous Claude Code run from your phone.
- Docs (HOW-IT-WORKS, SETUP, STATUS-LOG-PATTERN, CHANNELS), config template, and
  example status log.
