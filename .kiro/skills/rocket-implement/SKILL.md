---
name: rocket-implement
description: Execute the next grape task exactly as written
always: true
repo_scope: .kiro/crew/crew.yaml
crew_member: james
argument-hint: the beads epic id (or story) to work through
---

# Implement (james)

```bash
[ -f .kiro/crew/beads-dir ] && export BEADS_DIR=$(cat .kiro/crew/beads-dir)
bash scripts/rocket-gate-check.sh <epic-id> "GATE: PASS" || exit 1
bd ready
```

The gate check above is mandatory, not decoration - if it fails, stop and report why instead of implementing anything.

Read `.kiro/steering/opinions.md` once per iteration. Then:

1. Claim the next ready task for this story (`bd update <id> --claim`). Read it fully.
2. Do exactly what the task says. The task tells you what and how; design decisions are already made. Code and tests together, to the task's spec.
3. Commits: one logical change each. Aim for 50 to 150 changed lines; above 300, stop and split (see 6). Message carries the story id.
4. Run the gates the task lists. Smoke-run the change if it is runnable.
5. Close the task with evidence: `bd close <id> --reason="..."` and a comment with what you ran and saw.
6. If reality does not match the task (a file is not where the task says, the approach cannot work as written, the diff wants to grow past 300 lines): do not improvise. Comment what you found on the task, mark it blocked, and move to the next ready task.

Repeat for every ready task in one invocation if your session allows it; otherwise this skill is meant to be re-invoked - each call claims and finishes one grape, fresh context is fine because beads is the memory, not the session.

When no ready tasks remain for this story, reply exactly: `ALL_TASKS_COMPLETE` and stop delegating to this skill; move to `rocket-verify`.
