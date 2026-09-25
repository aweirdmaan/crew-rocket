---
name: rocket-approval-check
description: Check the epic for human approval of the current task list; never pause
always: true
repo_scope: .kiro/crew/crew.yaml
crew_member: meowth
argument-hint: the beads epic id
---

# Approval check

```bash
[ -f .kiro/crew/beads-dir ] && export BEADS_DIR=$(cat .kiro/crew/beads-dir)
bd list --parent <epic-id>
bd comments <epic-id>
```

The human approves plans as comments on the epic. Your job is one comparison:

1. Find the latest `APPROVAL` comment on the epic.
2. Compare what it approves against the current task list (`bd list --parent <epic-id>`).

**Match** (same tasks, no material change since the approval): your last action is
`bd comment <epic-id> "GATE: PASS approved task list matches"`.

**No approval, or the task list changed after it**: post one comment on the epic - the plan
summary (one line per task, in order, plus any decision that changed since the last approval)
ending with: *"To approve, comment: APPROVED - B0-B9 as listed. Then rerun rocket-implement (or the rocket-crew flow)."*
Then your last action is `bd comment <epic-id> "GATE: FAIL awaiting human approval on the epic"`.

If `bd` errors (e.g. "no beads database found"): that is a SETUP failure, not a missing
approval. Post `GATE: FAIL bd unreachable from this worktree` and stop - never conclude "no
approval exists" from a failed read, and never claim to have posted a comment unless `bd
comment` returned success.

Never assume approval. Never pause silently waiting for one. A missing or stale `GATE:`
comment fails closed - `scripts/rocket-gate-check.sh <epic-id> "GATE: PASS"` is what
`rocket-implement` runs before doing anything.
