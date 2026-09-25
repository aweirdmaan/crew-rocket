---
name: rocket-confirm
description: Confirm the fixes hold; final verdict before the PR
always: true
repo_scope: .kiro/crew/crew.yaml
crew_member: jessie
argument-hint: the beads epic id
---

# Confirm (jessie)

```bash
[ -f .kiro/crew/beads-dir ] && export BEADS_DIR=$(cat .kiro/crew/beads-dir)
bd comments <epic-id> | grep -A 999 '^FINDINGS'
```

If the latest `FINDINGS` post says `NONE`: re-run the gates once to confirm green, post a sign-off comment on the beads epic, then `bd comment <epic-id> "GATE: PASS all findings clear, gates green"`, and stop.

Otherwise: check each finding against the fix commits (`rocket-fix`'s comment listing what changed per finding). Re-run the gates and the verification steps the findings touched. Every finding is either fixed or has a recorded reason it stays. Post the sign-off (or the failure) as a beads comment on the epic.

Your LAST action is one of:

```
bd comment <epic-id> "GATE: PASS <one line summary>"     # every finding fixed or recorded; gates green
bd comment <epic-id> "GATE: FAIL <what is still broken>"
```

A broken change must not reach `rocket-pr` - it hard-checks for `GATE: PASS` via `scripts/rocket-gate-check.sh`. When in doubt, FAIL; a missing or stale comment fails closed.
