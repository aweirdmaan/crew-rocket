---
name: rocket-pr
description: Push the branch and open the MR/PR with the story and evidence
always: true
repo_scope: .kiro/crew/crew.yaml
crew_member: james
argument-hint: the beads epic id
---

# PR

```bash
[ -f .kiro/crew/beads-dir ] && export BEADS_DIR=$(cat .kiro/crew/beads-dir)
bash scripts/rocket-gate-check.sh <epic-id> "GATE: PASS" || exit 1
bd show <epic-id>
```

Delivery shape (human decision): one stacked MR per grape, plus one epic roll-up MR.

1. Identify each grape's commits on the current branch (commit messages carry the task ids; `bd show` each task for its close evidence). Never push to a default branch.
2. For each grape, in dependency order, create a branch at that grape's last commit: `<story>-b0`, `<story>-b1`, ... Push them all.
3. Open the stack (`glab` for GitLab, `gh` for GitHub), reusing any MR that already exists for a branch instead of duplicating:
   - first grape's MR targets the default branch;
   - every later grape's MR targets the previous grape's branch (grape-sized diffs; the host retargets as the stack merges).
   - Each title: the grape's beads title, verbatim - no upgrades. Body: what the grape does, its spec coverage, and the verification evidence pulled from the grape's beads close reason and comments (`bd show <task>`). Only name files that exist on the branch; check before writing.
4. Never write "complete" or claim an AC proven without checking: diff the confirmed task list against the closed beads tasks, and claim only what is closed and evidenced. Open the epic roll-up MR from the full branch to the default branch. Title: story id + "epic roll-up". Body: the WHY, the acceptance criteria, the verification evidence from the beads sign-off, and an index of the grape MRs in merge order. Note in it that code lands through the stack; the roll-up is the epic-level review view.
5. Comment all MR URLs on the beads epic, stack order stated.
6. If the epic carries an external tracker id, post the roll-up URL and status there, using the access pattern the project documents. If you skip or fail any step, say so in your final message - never announce a step and silently drop it.
