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
.kiro/
├── steering/
│   ├── philosophy.md          # the lens the rules fall out of
│   ├── opinions.md            # how code gets written here (commits, spec-driven, style)
│   └── failure-modes.md       # named smells, one line + minimal bad/good pair each
├── crew/
│   ├── crew.yaml               # the three members, their skills, their intended backend
│   └── beads-dir.example       # points bd at your workspace database
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

## Run

After `setup.sh`, on the `claude` backend (verified, see above — the agent
mechanism doesn't reach the session yet), start a session bound to your
project (CLI: run from inside it; dashboard: pick it in the project switcher)
and tell it directly which skill to read: *"read
`.kiro/skills/rocket-crew/SKILL.md` and follow it for PROJ-123."* That works
identically whether or not KiroCrew is even involved — a bare `claude` or
`codex` session with no KiroCrew reads the same file the same way.

On `kiro` or `kas` (untested here, but that's where the docs say custom-agent
`prompt`/`resources` are natively loaded rather than field-by-field projected):

```bash
scripts/rocket-use-backend.sh meowth   # picks meowth's backend from crew.yaml
kirocrew chat --agent rocket-meowth    # -m "use rocket-ideate for PROJ-123" for one shot
```

Switch to `rocket-jessie` or `rocket-james` (running `rocket-use-backend.sh`
first if that role's backend differs) as the pipeline reaches their skills.

Either path
walks the pipeline above, stopping cold at both human gates.

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
