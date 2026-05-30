# The Status Log Pattern

The monitor is only as useful as the file it watches. This is the convention
that makes autonomous coding sessions observable: **one append-only text file,
one terse line per milestone.**

## The rules

1. **One file per mission (i.e. per autonomous run).** e.g. `mission_1/status_log.md`. Durable on disk so the
   monitor survives restarts.
2. **Append, newest at the bottom.** One line per milestone.
   (The monitor's content-diff handles prepend too, but bottom-append is the
   convention and reads naturally.)
3. **Each line is self-contained.** It will appear alone in a Discord/Telegram
   message, so include the phase, the result, and the evidence. No multi-line
   entries that only make sense in context.
4. **Status only — no prose.** No "Let me…", no narration. Phase, gate, scores,
   pass/fail.
5. **Log at gates, not constantly.** A line means "something a human would want
   to know just happened": a phase started, a gate passed/failed, scores landed,
   the run finished. Not every tool call.

## Line shapes

```
Phase <N> started — <agents/steps>
Phase <N> gate passed — <artifact / evidence>
Phase <N> gate FAILED — <what broke, what you're doing>
<Eval/Oracle> — <metric>: <score> (<vs gate/baseline>)
Mission <ID> COMPLETE | NO-SHIP — <summary + evidence>
```

See `examples/status_log.example.md` for a full run.

## Making an autonomous session write it

Add an instruction to your project's `CLAUDE.md` (or mission/orchestration
skill) so the coding session maintains the log as a standing rule. Example:

```markdown
## Status logging (mandatory)

Maintain `docs/status_log.md`. Append a terse one-line snippet at EVERY phase
gate, newest at the bottom. Log eval/oracle scores there as they arrive. This
file is how progress is monitored remotely — advancing a phase without logging
it means the phase is not done. Status only, no prose.
```

## Why this approach

This pattern came out of running autonomous coding missions over long sessions.
The same append-only file serves three purposes at once:

1. **Relay source.** The `/monitor` skill watches it and relays new lines to
   your phone.
2. **Cross-session record.** Long runs lose context — windows get summarized,
   sessions restart. The status log is the durable, on-disk record of where a
   mission stands, so a fresh session can resume from it. Chat history is not
   local, greppable, or guaranteed to persist.
3. **Phase-gate discipline.** Requiring a line at every gate forces the
   orchestrator to state what passed and with what evidence. Advancing a phase
   without a line means the phase is not done; the log doubles as the gate
   record.

**Why a file and not direct chat calls.** Posting to Discord from the coding
session couples the work to a chat SDK: it adds network calls that can fail
mid-run, requires editing the orchestrator to change chat apps, drops the
durable on-disk record, and limits you to one consumer. With a file the
orchestrator only writes lines, and the monitor relays to any channels you
configure — Discord, Telegram, a terminal `tail`, a dashboard — all watching the
same run.

**Why not polling or log-scraping.** Raw build and agent output is high-volume,
and you still have to decide what counts as a milestone. The orchestrator already
knows which events matter and emits only those lines, so the relayed output is
limited to gate results and scores. Because the channel is two-way, you can also
reply to unblock or redirect a run.

## Beyond coding sessions

Anything that appends lines to a file can be monitored: a CI pipeline writing
step results, an eval harness logging scores, a long migration emitting
progress. Point `/monitor` at the file and you get the same phone notifications.
