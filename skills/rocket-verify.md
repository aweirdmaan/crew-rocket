---
description: Prove the change survives production, then review the diff
crew_member: jessie
argument-hint: the beads epic id
---

# Verify (jessie)

```bash
[ -f .kiro/crew/beads-dir ] && export BEADS_DIR=$(cat .kiro/crew/beads-dir)
bd show <epic-id>
bd list --parent <epic-id>
```

Read `.kiro/steering/failure-modes.md` and `.kiro/steering/opinions.md`. You may write test probes under the project's test roots. You never write production code.

## 1. Prove it works

- Run every gate the tasks list. Zero failures.
- Run the change per each task's verification setup. Record what you observed, not what was expected.
- Attack it: adversarial inputs, failure paths (dependency down, missing data, retry), environment variance if the project is multi-env. Run it twice; leftover-state bugs hide from single runs.
- Regression: run the existing suite in full. Anything that worked before must still work.

## 2. Review the diff

- Every acceptance row maps to a test that pins it plus the runtime evidence above. A row without both is a finding.
- Check the diff against `.kiro/steering/failure-modes.md`; name any hit by its entry name.
- Assertions must fail on a plausible regression. Exact values, not "is not null".
- No-touch files (per the plan) untouched. Commit sizes within opinions.md. Blocked tasks in beads are findings. A READY task left open after `rocket-implement` says `ALL_TASKS_COMPLETE` is a finding - never rationalize it as scope.

## 3. Report

Post findings as a beads comment on the epic, headed `FINDINGS`, one per line: `file:line | what is wrong | the failure it allows | suggested fix`. If there are none, post `FINDINGS\nNONE`. End with one paragraph: what you ran, what you observed, your verdict.
