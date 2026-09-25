# Crew Rocket

> *Prepare for trouble — on whatever CLI you've got.*

[team-rocket](https://github.com/) packaged its development process as [Archon](https://github.com/coleam00/Archon)
workflows — powerful, but wired to Claude Code as the only agent. Crew Rocket
is the same process (plan with citations, build in grape-sized tasks, prove
the result survives production, beads holds every decision) rebuilt on
[KiroCrew](https://kiro.dev/crew/), whose orchestration layer is agent-agnostic:
Claude Code, Codex, opencode (and through it, OpenRouter or an internal LLM
gateway like devpass), kas, goose, pi.

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

`skills/rocket-crew.md` is the entry point and states this sequence and its two
human gates in full; invoke it and it delegates to the rest.

A **grape** is a task one `rocket-implement` invocation finishes: one logical
change, 1 to 3 small commits. Planning splits work until everything is a grape.

## Why KiroCrew and not Archon

Archon's workflow YAML is a real declarative DAG with deterministic bash gate
nodes — a guarantee crew-rocket cannot fully replicate, because KiroCrew has
no equivalent engine (confirmed against a real 0.7.1 install; see below). The
trade crew-rocket makes:

- **Durable handoff** replaces Archon's per-run `$ARTIFACTS_DIR`: every skill
  reads and writes beads directly (`bd comment`, `bd show`, `bd list`).
  Nothing lives only in a session that might not survive to the next one.
- **`GATE: PASS` / `GATE: FAIL`** beads comments replace Archon's verdict
  files. `scripts/rocket-gate-check.sh <epic-id> "GATE: PASS"` is the
  mechanical check — run it, don't trust the agent's word for it. It's a
  plain bash script; it works identically regardless of which backend wrote
  the comment.
- **`skills/rocket-crew.md`** replaces the YAML DAG. There is no engine
  sequencing nodes for you; that skill *is* the sequence, and it names
  exactly where the mechanical gate checks belong so an agent can't reason
  its way past them.

This is honestly weaker than Archon's structural guarantee in one place: an
AI backend *can* choose not to follow `rocket-crew.md`'s instruction to run
the gate check. If you're on Claude Code with Archon available, team-rocket's
original guarantee is stronger for that backend specifically. Crew Rocket
trades some of that rigor for running the same process on Codex, opencode,
OpenRouter, or an internal gateway too.

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
4. If you picked OpenRouter or an internal gateway (devpass) for any role, writes an opencode OpenAI-compatible provider config pointing at it (opencode is the backend that actually reaches those — see `.kiro/crew/crew.yaml`'s header comment for why there's no direct "openrouter" backend).
5. Copies `.kiro/steering/`, `skills/`, and `.kiro/crew/` into `--target`.
6. Initializes beads (`bd init`) and writes `.kiro/crew/beads-dir`.
7. Applies what it can to KiroCrew's config (`agent.acp_backend`, `agent.member_acp_backend` — see the next section for why not more) and tells you exactly what it couldn't apply and why.

Single-command, no prompts: `./setup.sh --target DIR --meowth claude --jessie claude --james codex --yes`.

`--dry-run` prints every command without running it.

## Backends: what's real vs. what's per-role

Verified against a real KiroCrew 0.7.1 install, not assumed from docs: its
config is **global**, not per-named-crew-member.

- `kirocrew config set agent.acp_backend <backend>` — the backend *this
  session* runs on. Works.
- `kirocrew config set agent.member_acp_backend <backend>` — the backend a
  session delegates spawned/subagent work to. Works.
- `kirocrew config set member_acp_backend.meowth <backend>` (a key per named
  crew member) — does not exist. Errors `Unknown key`.
- `agent.role_models` / `agent.role_efforts` accept a JSON object and report
  success, but do not persist (read back as `{}` immediately after). Don't
  rely on them.

So meowth, jessie, and james cannot all be pinned to different backends at
once through config alone. `setup.sh` applies meowth's choice to
`agent.acp_backend` and jessie's to `agent.member_acp_backend` (she's the one
meowth spawns as a challenger during `rocket-plan`). Before starting james's
session on a different backend, run:

```bash
scripts/rocket-use-backend.sh james
```

which reads james's `backend:` straight out of `.kiro/crew/crew.yaml` and
applies it. Selectable backends as of writing: `kiro`, `claude`, `kas`,
`codex`, `opencode`, `pi`, `goose`.

## What's inside

```
setup.sh                       # the one-command installer/configurer
Makefile, scripts/validate.sh  # self-checks: frontmatter, YAML, shellcheck, dry-run
scripts/rocket-gate-check.sh   # GATE: PASS/FAIL check — the deterministic gate
scripts/rocket-use-backend.sh  # switch agent.acp_backend to a crew member's assigned backend
.kiro/
├── steering/
│   ├── philosophy.md          # the lens the rules fall out of
│   ├── opinions.md            # how code gets written here (commits, spec-driven, style)
│   └── failure-modes.md       # named smells, one line + minimal bad/good pair each
└── crew/
    ├── crew.yaml               # the three members, their skills, their intended backend
    └── beads-dir.example       # points bd at your workspace database
skills/
├── rocket-crew.md              # entry point: the full pipeline and its two human gates
├── rocket-ideate.md            # meowth
├── rocket-plan.md              # meowth + jessie
├── rocket-confirm-plan.md      # meowth
├── rocket-approval-check.md    # meowth
├── rocket-implement.md         # james
├── rocket-verify.md            # jessie
├── rocket-fix.md               # james
├── rocket-confirm.md           # jessie
├── rocket-pr.md                # james
├── rocket-retro.md             # meowth
└── rocket-harvest.md           # james
```

## Run

After `setup.sh`, from your project:

*"Invoke the rocket-crew skill with PROJ-123."* (or whatever your backend's
invocation syntax is — a KiroCrew session, `claude` with the skill loaded,
`codex exec`, etc.) It walks the pipeline above, stopping cold at both human
gates.

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
