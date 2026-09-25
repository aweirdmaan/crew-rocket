---
name: rocket-fix
description: Address verification findings
always: true
repo_scope: .kiro/crew/crew.yaml
crew_member: james
argument-hint: the beads epic id
---

# Fix (james)

```bash
[ -f .kiro/crew/beads-dir ] && export BEADS_DIR=$(cat .kiro/crew/beads-dir)
bd comments <epic-id> | grep -A 999 '^FINDINGS'
```

If the latest findings post says `NONE`, reply "nothing to fix" and stop.

Otherwise, for each finding: fix it, or state in a beads comment why it should not be fixed. Same commit rules as `rocket-implement` (one logical change, story id in the message). Re-run the gates after the last fix. List what you changed per finding, then post that list as a comment on the epic so `rocket-confirm` can check it without re-deriving it.
