# Crew Rocket

> *Prepare for trouble — and make it double-tested.*

A development process for AI coding, packaged as [KiroCrew](https://kiro.dev/crew/)
skills. Plan with citations, build in grape-sized tasks, prove the result
survives production. Beads holds every decision. Runs on Claude Code, Codex,
opencode (and through it, OpenRouter or an internal LLM gateway), kas, pi, or
goose.

## The team

| Role | Job |
|---|---|
| **Meowth** | Plans and discovers. Given WHY and WHAT, digs through the code, drafts the HOW, cites every source, logs every decision in beads. |
| **Jessie** | Challenges the plan, then proves the built thing works: runs it, attacks it, checks nothing regressed. Test probes only, never production code. |
| **James** | Executes. The task tells him what and how. If reality disagrees with the task, he stops and returns it. |

The human is in two places: answering the one consolidated question batch during planning, and approving the plan. Everything else runs unattended.

## The workflow

```
rocket-ideate            story id/description -> beads epic, WHY + WHAT
rocket-plan              discover, draft, challenge -> OPEN QUESTIONS on the epic

>>> you: answer them as a comment on the epic <<<

rocket-confirm-plan      gate on answers -> persists grape tasks
rocket-approval-check    gate on your APPROVED comment

>>> starting rocket-implement IS the approval; nothing above builds anything <<<

rocket-implement (loop)  one grape per invocation, until ALL_TASKS_COMPLETE
rocket-verify            proves it, reviews the diff
rocket-fix               addresses findings
rocket-confirm           confirms fixes hold
rocket-pr                stacked MR per grape + epic roll-up MR

rocket-harvest           (later) human review comments -> beads + process proposals
```

`.kiro/skills/rocket-crew/SKILL.md` is the entry point and states this sequence
and its two human gates in full; invoke it and it delegates to the rest.

A **grape** is a task one `rocket-implement` invocation finishes: one logical
change, 1 to 3 small commits. Planning splits work until everything is a grape.

Every skill hands off through beads: `bd comment`, `bd show`, `bd list`.
Nothing lives only in a session that might not survive to the next one.
`GATE: PASS` / `GATE: FAIL` beads comments are the checkpoints between
stages; `scripts/rocket-gate-check.sh <epic-id> "GATE: PASS"` is the
mechanical check that runs before anything downstream proceeds - a plain
bash script, so it works identically no matter which backend wrote the
comment.

## Install

```bash
git clone <this repo> crew-rocket
cd crew-rocket
./setup.sh --target /path/to/your/project
```

Interactively, `setup.sh`:

1. Installs [KiroCrew](https://kiro.dev/crew/) if it isn't already (asks first — it's a real install, ~1GB with its bundled Python runtime).
2. Detects what's on your machine: `claude`, `codex`, `opencode`, `OPENROUTER_API_KEY`, `DEVPASS_BASE_URL`/`DEVPASS_API_KEY`.
3. Proposes a backend per crew member and lets you confirm or override.
4. If you picked OpenRouter or an internal gateway for any role, writes an opencode OpenAI-compatible provider config pointing at it (opencode is the backend that actually reaches those).
5. Copies `.kiro/steering/`, `.kiro/skills/`, and `.kiro/crew/` into
   `--target`, and installs the same skills globally under
   `~/.kiro/crew/skills/` (repo-scoped, so no dashboard trust grant is
   needed to activate them).
6. Initializes beads (`bd init`) and writes `.kiro/crew/beads-dir`.
7. Applies what it can to KiroCrew's config (`agent.acp_backend`, `agent.member_acp_backend`) and tells you exactly what it couldn't apply and why.

Single-command, no prompts: `./setup.sh --target DIR --meowth claude --jessie claude --james codex --yes`.

`--dry-run` prints every command without running it.

## Backends: what's global vs. what's per-role

KiroCrew's config is **global**, not per-named-crew-member:

- `kirocrew config set agent.acp_backend <backend>` — the backend *this
  session* runs on.
- `kirocrew config set agent.member_acp_backend <backend>` — the backend a
  session delegates spawned/subagent work to.

There is no key per named crew member. So meowth, jessie, and james cannot
all be pinned to different backends at once through config alone.
`setup.sh` applies meowth's choice to `agent.acp_backend` and jessie's to
`agent.member_acp_backend` (she's the one meowth spawns as a challenger
during `rocket-plan`). Before starting james's session on a different
backend, run:

```bash
scripts/rocket-use-backend.sh james
```

which reads james's `backend:` straight out of `.kiro/crew/crew.yaml` and
applies it. Selectable backends as of writing: `kiro`, `claude`, `kas`,
`codex`, `opencode`, `pi`, `goose`.

## Beads vs. KiroCrew's own memory/knowledge

Beads is the task/decision layer: epics, dependency edges, a ready-queue,
claim/close-with-reason, the `GATE:` comment trail. KiroCrew's own memory
(per-member preferences, project context, conversation history, taught
"lessons") and Knowledge Library (semantic search over documents you add)
solve a different problem — assistant recall and document retrieval, not
task state — and nothing here uses either as a replacement for beads.
Two additive integrations, both optional and both skipped cleanly when
KiroCrew isn't the backend in use:

- `rocket-plan` adds the three steering docs to the Knowledge Library via
  the `knowledge_add_document` tool (gated by `knowledge.auto_add_documents`,
  which `setup.sh` turns on), then also queries `local_knowledge_search`
  during discovery — a second way to find a relevant passage by meaning,
  never a replacement for the direct read it always does first.
- `rocket-retro` also runs `kirocrew learn add "<lesson>" --category
  knowledge` for each cross-cutting insight, alongside `bd remember`, so the
  same lesson is recallable by KiroCrew's own memory in a session that never
  reads the epic.

See `docs/dark-factory-roadmap.md` for what a fully unattended setup (work
triggers itself, only a genuine blocker reaches a human) needs that isn't
built yet.

## What's inside

```
setup.sh                       # the one-command installer/configurer
Makefile, scripts/validate.sh  # self-checks: frontmatter, YAML, shellcheck, dry-run
scripts/rocket-gate-check.sh   # GATE: PASS/FAIL check — the deterministic gate
scripts/rocket-use-backend.sh  # switch agent.acp_backend to a crew member's assigned backend
scripts/rocket-dag.sh          # orchestrates .kiro/workflows/*.yaml via KiroCrew's Task Runner API
scripts/rocket-watch.sh        # live SSE progress for a run (needs the forked KiroCrew build, see below)
.kiro/
├── steering/
│   ├── philosophy.md          # the lens the rules fall out of
│   ├── opinions.md            # how code gets written here (commits, spec-driven, style)
│   └── failure-modes.md       # named smells, one line + minimal bad/good pair each
├── crew/
│   ├── crew.yaml               # the three members, their skills, their intended backend
│   └── beads-dir.example       # points bd at your workspace database
├── workflows/                   # native Task Runner DAGs, migrated from .archon/workflows/
│   ├── rocket-plan.yaml             # ideate -> plan, real 2-node DAG (team-rocket-plan.yaml)
│   ├── rocket-confirm-plan.yaml     # \
│   ├── rocket-approval-check.yaml   #  \ one phase each, orchestrated by rocket-dag.sh
│   ├── rocket-implement.yaml        #  / with real gates between them
│   ├── rocket-verify.yaml           # /  (team-rocket-implement.yaml)
│   ├── rocket-fix.yaml              #
│   ├── rocket-confirm.yaml          #
│   ├── rocket-pr.yaml               #
│   ├── rocket-retro.yaml            #
│   └── rocket-harvest.yaml          # single-node DAG (team-rocket-harvest.yaml)
└── skills/                     # one directory per skill, KiroCrew's native SKILL.md format
    ├── rocket-crew/SKILL.md         # entry point: the full pipeline and its two human gates
    ├── rocket-ideate/SKILL.md       # meowth
    ├── rocket-plan/SKILL.md         # meowth + jessie
    ├── rocket-confirm-plan/SKILL.md # meowth
    ├── rocket-approval-check/SKILL.md # meowth
    ├── rocket-implement/SKILL.md    # james
    ├── rocket-verify/SKILL.md       # jessie
    ├── rocket-fix/SKILL.md          # james
    ├── rocket-confirm/SKILL.md      # jessie
    ├── rocket-pr/SKILL.md           # james
    ├── rocket-retro/SKILL.md        # meowth
    └── rocket-harvest/SKILL.md      # james
```

Each `SKILL.md` carries `repo_scope: .kiro/crew/crew.yaml`, so it only
activates in a session whose project contains that file. `setup.sh` installs
every skill both into `<project>/.kiro/skills/` (KiroCrew's project-scoped
location — browsable once you grant that project dashboard trust) and into
`~/.kiro/crew/skills/` (global — active immediately, no trust grant needed,
and harmless everywhere else because of `repo_scope`).

## Agents, not just skill text

Meowth, Jessie, and James are real KiroCrew agents (`.kiro/agents/rocket-*.json`),
not one generic session asked to switch hats. Each has its own system prompt and
its own skills mapped as always-on `skill://` resources — KiroCrew's own rule is
that a custom agent with no mapping "brings its own" and sees nothing from the
global catalog, so this mapping is what makes the role's skills load in full,
every time, rather than depending on keyword-trigger matching (off by default)
or the agent deciding on its own to go search for them. `setup.sh` installs all
three both globally (`~/.kiro/agents/`) and into the project
(`<project>/.kiro/agents/`).

What an agent spec cannot do: KiroCrew has no path-scoped write permission, so
"Jessie never touches production code" is not a tool-level guarantee — nothing
stops her `fs_write` grant from reaching `src/`. It stays a prompt-level
discipline, the same as before; the agent split changes how reliably her two
skills load, not what her tools can structurally forbid.

**Verified status, `claude` backend, KiroCrew 0.7.1 + claude-agent-acp 0.81.2:**
tested live — created the agent spec, enrolled it (`kirocrew agent create --name
rocket-meowth --kiro-agent rocket-meowth`), started a session with `chat --agent
rocket-meowth`, and asked it directly whether its system prompt mentioned beads,
grapes, or meowth. It answered "no such content" — the custom prompt and mapped
skills are not reaching the session on this backend, in this version. This
matches a class of open KiroCrew issues on custom/crew agents under the `claude`
backend specifically (kirodotdev/KiroCrew#8152 documents `claude` as an
acknowledged "second-class member backend" with real dispatch gaps;
kirodotdev/KiroCrew#9602 is an unresolved custom-agent bug of a similar shape).
It is not something this setup got wrong; it is not something this setup can
currently fix either. Until that's resolved upstream, the agent specs are the
structurally-correct artifact (and may already work on the `kiro` or `kas`
backends — untested here, no `kiro-cli` installed) but the reliable path on
`claude` today is still the direct one: tell the session which skill to read.

## Native kiro workflows (migrated from Archon)

team-rocket's three Archon workflows (`team-rocket-plan.yaml`,
`team-rocket-implement.yaml`, `team-rocket-harvest.yaml`) are migrated into
`.kiro/workflows/*.yaml` — real KiroCrew Task Runner DAGs (`agents:` +
`depends_on:`, the same `.yaml`-suffix format that skips the LLM decomposer
and gets a hard, acyclic-checked dependency graph instead), not just prose.

They are **not** a 1:1 port, because Task Runner only runs one agent per
run (a node's own `agent:` field is cosmetic, not an execution switch —
verified against KiroCrew's source, not assumed) and Archon's bash gate
nodes have no native equivalent here. The honest mapping:

| Archon workflow | Kiro migration |
|---|---|
| `team-rocket-plan.yaml` (ideate → plan, one model, no gate) | `.kiro/workflows/rocket-plan.yaml` — a real 2-node DAG, both meowth. The one case where a native multi-node DAG is actually correct. |
| `team-rocket-implement.yaml` (confirm-plan → **gate** → approval-check → **gate** → implement **loop** → verify → fix → confirm → **gate** → pr → retro) | `.kiro/workflows/rocket-{confirm-plan,approval-check,implement,verify,fix,confirm,pr,retro}.yaml` — one single-node template per phase (each phase switches persona and/or sits behind a real gate), orchestrated by `scripts/rocket-dag.sh implement <epic>`, which runs `scripts/rocket-gate-check.sh` as a real hard check between phases — Archon's own reason for making those bash nodes, not AI-prose checks, now reproduced the same way instead of trusted to a single unattended DAG. |
| `team-rocket-harvest.yaml` (single node) | `.kiro/workflows/rocket-harvest.yaml` — a single-node DAG, 1:1. |

Run them:

```bash
scripts/rocket-dag.sh plan '<story id or description>'     # ideate -> plan, ends at OPEN QUESTIONS
# ... you answer the questions, then approve the plan on the epic ...
scripts/rocket-dag.sh implement <epic-id>                  # confirm-plan -> ... -> pr -> retro
scripts/rocket-dag.sh harvest '<mr-url>'                    # after a human review lands comments
```

**Verified working, on `claude`, against a real KiroCrew install** (not just
unit-tested): a 5-node DAG with a genuine parallel branch ran end to end,
scheduled into real execution groups by Task Runner itself, each node's
output checked directly against beads (`bd show`/`bd comments`), not just
trusted from the agent's own report. This path sidesteps the custom-agent
injection bug entirely, because the skill content travels as the task
prompt, never through the agent spec's `prompt`/`resources` fields — so it
works today even though `kirocrew chat --agent rocket-meowth` still doesn't.
`scripts/rocket-dag.sh` passes `"auto_approve": true` on each submission (the
same provenance-gated flag the dashboard's own Approve button grants, not a
bypass of it), so it runs unattended rather than stalling on a tool-approval
prompt per command.

**Watching a run live:** Task Runner has no push/WebSocket channel in
mainline KiroCrew — even the dashboard's own Projects page just polls
`GET /api/taskrunner` every 3 seconds (verified in its source, not assumed).
`scripts/rocket-watch.sh <task_id>` streams one instead, over a new
`GET /api/taskrunner/{task_id}/stream` Server-Sent-Events endpoint built and
tested for this (`kirodotdev/KiroCrew` PR from this project's
`aweirdmaan/KiroCrew` fork, branch `fix/claude-backend-and-devpass` —
**mainline KiroCrew does not have this endpoint yet**, so `rocket-watch.sh`
only works against that build). It prints run/step status changes and each
step's result as they happen, polling the gateway's own in-memory state at
0.3s server-side rather than the client re-requesting every 3s.

## Run

Two ways to drive the pipeline. The native workflows above are the verified,
automatable path on `claude` today. The direct, backend-agnostic fallback
works identically with or without KiroCrew: start a session bound to your
project (CLI: run from inside it; dashboard: pick it in the project switcher)
and tell it directly which skill to read — *"read
`.kiro/skills/rocket-crew/SKILL.md` and follow it for PROJ-123."* A bare
`claude` or `codex` session with no KiroCrew reads the same file the same way.

On `kiro` or `kas` (untested here, but that's where the docs say custom-agent
`prompt`/`resources` are natively loaded rather than field-by-field projected),
a third option is a live chat session per role:

```bash
scripts/rocket-use-backend.sh meowth   # picks meowth's backend from crew.yaml
kirocrew chat --agent rocket-meowth    # -m "use rocket-ideate for PROJ-123" for one shot
```

Switch to `rocket-jessie` or `rocket-james` (running `rocket-use-backend.sh`
first if that role's backend differs) as the pipeline reaches their skills.

Any path walks the pipeline above, stopping cold at both human gates.

`make validate` runs this repo's own self-checks before you commit changes to
the process itself.

## Requirements

- [KiroCrew](https://kiro.dev/crew/) — or run the skills directly against a
  single backend's own session if you don't want the orchestration layer at
  all; every skill is a self-contained markdown file that only assumes `bd`
  and a shell.
- [beads](https://github.com/steveyegge/beads) (`bd`) — the decision and task memory
- `glab` or `gh` for the PR skill
- Whichever agent backend(s) you assign: `claude`, `codex`, `opencode` (for OpenRouter/devpass), `kas`, `pi`, or `goose`
- A git remote with a default branch the workflow stays off
