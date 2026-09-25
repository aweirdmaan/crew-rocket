# Dark factory roadmap

Notes from a scouting pass over KiroCrew's docs (v0.7.1, September 2026) for
what a fully unattended crew-rocket setup — work triggers itself, runs to
completion, and only a genuine blocker ever reaches a human — needs that it
does not have yet. Nothing here is built. This is a prioritized list to build
from, not a design.

## The escalation gap

KiroCrew has no "page a human" tool. It has two separate halves that need
wiring together:

- `ask_question` (agent-questions.md) posts a dashboard question card and
  waits — but only reaches someone who already has that session's tab open.
  It is "ask if anyone's watching," not "notify someone."
- The actual push channel (dashboard notification + a Slack DM to the owner,
  when Slack is configured) lives on the *unattended-trigger* side instead:
  cron jobs and inbound webhooks deliver their result that way when a run
  finishes.

So the dark-factory pattern is: an agent that hits a genuine blocker writes
`GATE: FAIL <question>` to the beads epic (crew-rocket already does this)
and stops. Something else — a cron job or a monitor loop — has to notice the
stuck gate and turn it into an actual notification. That glue does not exist
yet.

## Worth building, in order

1. **`kirocrew cron add`** — a real, scriptable CLI that fails closed on
   refusal. Nothing today starts `rocket-ideate` / `rocket-plan` on its own;
   a human always types the first command. A `--script` cron (bypasses the
   LLM, zero token cost) polling beads for new ready epics is the missing
   trigger.
2. **Inbound webhooks** (`POST /api/hooks/agent`) — lets a GitHub/Jira event
   fire a run directly instead of polling, with the same
   notification-on-completion behavior as cron.
3. **Monitor loops** — wakes a session only on a real state change (a new PR
   revision, CI going green) instead of burning a turn every N minutes. This
   is the natural glue between `rocket-pr` finishing and `rocket-harvest`
   picking up review comments, and it is also the mechanism that could watch
   a `GATE: FAIL` epic and turn it into a notification.
4. **Secrets vault** — once cron/webhook-triggered runs handle real repo/CI
   credentials with nobody watching, plaintext env vars are the wrong shape.
5. **`blocked-commands.md`** — worth understanding as the safety net's actual
   limits (command-pattern matching, not a sandbox) before trusting it
   unattended.

## Ruled out

- **Session control** — overlaps the Work Ledger, already rejected as a
  beads substitute for the reasons in the git history (session/run-scoped,
  no dependency edges).
- **Remote crew** — an infrastructure convenience (running this off a
  laptop), not a dark-factory primitive by itself.
- **Followup suggestions** — explicitly requires a human click; the
  opposite of what unattended operation needs.
- **Snapshot and restore** — a backup tool, not run-recovery.
- **Jev (decisions.md), OTLP telemetry, enterprise MCP governance** — not
  relevant at this scale.
