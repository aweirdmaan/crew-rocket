---
description: Judge the plan against the outcome; record what the team learned
crew_member: meowth
argument-hint: the beads epic id
---

# Retro (meowth)

```bash
[ -f .kiro/crew/beads-dir ] && export BEADS_DIR=$(cat .kiro/crew/beads-dir)
bd show <epic-id>
bd list --parent <epic-id>
bd comments <epic-id> | grep -A 999 '^FINDINGS'
```

Answer honestly. Your output is worthless unless it is durable: post the retro as a beads comment on the epic (verify the command succeeded), run `bd remember` for cross-cutting insights, and file proposals as beads issues. If `bd` fails, say so loudly in your final message - do not pretend. Cover:

1. Did the plan hold? Was every task actually a grape? Did any task come back blocked because reality disagreed with it? Was the verification setup sufficient, or did jessie have to improvise?
2. What did verification catch that planning should have? Each such finding is a planning lesson; write it down.
3. What is worth keeping? Discoveries, gotchas, decisions future stories on this code need. `bd remember` the cross-cutting ones. If `kirocrew` is on PATH, also run `kirocrew learn add "<the lesson, one sentence>" --category knowledge` for each one - beads is still the record of truth, but this makes the same lesson recallable by KiroCrew's own memory in a session that never reads this epic.
4. If the same failure mode appeared more than once, file a beads issue proposing an addition to `.kiro/steering/failure-modes.md` or `opinions.md`.

A wrong prediction is the most useful line in the retro. For a trivial story, "plan held; nothing learned" is complete. Human review comments on the MR arrive later; `rocket-harvest` handles those.
