---
name: rocket-harvest
description: Record human MR/PR review comments in beads; file proposals for recurring themes
always: true
repo_scope: .kiro/crew/crew.yaml
crew_member: james
argument-hint: MR/PR URL, optionally the beads story id
---

# Harvest

Input: the MR/PR URL, optionally the beads story id.

```bash
[ -f .kiro/crew/beads-dir ] && export BEADS_DIR=$(cat .kiro/crew/beads-dir)
```

1. Read every human comment on the MR/PR (`glab mr note list` / `gh pr view --comments`, plus inline discussion threads).
2. Find the beads epic (from the input, or the story id in the MR title).
3. Post each comment to the epic as a beads comment: the quoted feedback, the file/line it targets, and what change it asks for.
4. Group the comments. A theme that appears more than once, or that generalises beyond this story, becomes a beads issue proposing a change to `.kiro/steering/opinions.md`, `failure-modes.md`, or a skill file. Quote the source comments in the proposal.
5. Reply with the count recorded and the proposals filed.

This is how the team learns from its reviewer. Do not summarise away the why; quote it.
