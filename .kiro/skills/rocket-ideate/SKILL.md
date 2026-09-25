---
name: rocket-ideate
description: Turn a story idea or tracker id into a beads story with WHY and WHAT
always: true
repo_scope: .kiro/crew/crew.yaml
crew_member: meowth
argument-hint: story id or story description
---

# Ideate (meowth)

Input: the story id or description given to you.

Beads setup (do this first, every rocket skill does):
```bash
[ -f .kiro/crew/beads-dir ] && export BEADS_DIR=$(cat .kiro/crew/beads-dir)
```

1. If the input is a beads id: read the story (`bd show`). If it already has a clear WHY and WHAT, note the epic id and stop here.
2. If the input is an external tracker id (Jira etc.): first search beads for an epic already carrying that id (`bd list --all` / `bd search`) - if one exists, use it, don't mirror twice. Otherwise fetch the story using the access pattern the project documents (CLAUDE.md, AGENTS.md, or this project's own docs) and mirror it: `bd create --type=epic` with the WHY and WHAT. Note the external id in the epic description so `rocket-pr` and `rocket-retro` can sync back.
3. If the input is a description: write the WHY (one paragraph: why this matters, for whom) and the WHAT (acceptance criteria: testable, binary outcomes). Create the beads epic.
4. Report back: the beads epic id, the external id if any, WHY, WHAT. Everything downstream reads this from beads directly - there is no separate handoff file.

Do not design. HOW belongs to `rocket-plan`.
