---
name: rocket-crew
description: Entry point - run the full plan-then-build pipeline across the crew, backend-agnostic
always: true
repo_scope: .kiro/crew/crew.yaml
crew_member: meowth
argument-hint: story id or story description
---

# The crew-rocket pipeline

Nothing sequences the stages below for you automatically - this skill IS the sequencer.
Delegate each stage to the named crew member's skill (KiroCrew's subagent delegation, a
Codex sub-session, or just switching hats yourself if only one backend session is
available), and hard-stop at each `GATE:` check instead of taking the AI's word for it.

```
Plan phase (ends with a human decision):
  rocket-ideate            (meowth)  story id/description -> beads epic, WHY + WHAT
  rocket-plan              (meowth + jessie)  discover, draft, challenge -> OPEN QUESTIONS on the epic

>>> YOU: answer the open questions as a comment on the epic <<<

Build phase (starting it IS the approval; nothing above builds anything):
  rocket-confirm-plan      (meowth)  gate on answers -> persists grape tasks, posts GATE: PASS/FAIL
  rocket-approval-check    (meowth)  gate on your APPROVED comment -> GATE: PASS/FAIL
  rocket-implement (loop)  (james)   one grape per invocation, until ALL_TASKS_COMPLETE
  rocket-verify             (jessie)  proves it, reviews the diff -> FINDINGS
  rocket-fix                (james)   addresses findings
  rocket-confirm             (jessie)  confirms fixes hold -> GATE: PASS/FAIL
  rocket-pr                  (james)   stacked MR per grape + epic roll-up MR

Later, once a human has reviewed the MR:
  rocket-harvest             (james)   review comments -> beads + proposed process changes
```

## Running it

1. Invoke `rocket-ideate` with the story id or description. Note the epic id it reports.
2. Invoke `rocket-plan` with that epic id. It ends with `OPEN QUESTIONS` posted on the epic - stop and get the human's answers as a beads comment.
3. Invoke `rocket-confirm-plan` with the epic id. Before doing anything else it must see the human's answers; check its own output for `GATE: PASS` or `GATE: FAIL`. On FAIL, stop and report why - do not proceed to approval-check.
4. Invoke `rocket-approval-check`. On FAIL (no `APPROVED` comment yet, or the task list changed since), stop and wait for the human's `APPROVED` comment, then re-invoke this step.
5. Invoke `rocket-implement` repeatedly (fresh context each time is fine and preferred - beads is the memory) until it replies `ALL_TASKS_COMPLETE`. Before EACH invocation it re-checks the approval gate itself via `scripts/rocket-gate-check.sh`; never bypass that check by calling the underlying steps directly.
6. Invoke `rocket-verify`, then `rocket-fix` if it found anything, then `rocket-confirm`. If `rocket-confirm` posts `GATE: FAIL`, loop back to `rocket-fix` - do not invoke `rocket-pr`.
7. Invoke `rocket-pr` only once `rocket-confirm` posted `GATE: PASS`; it checks this itself and refuses otherwise.
8. When the human leaves review comments on the opened MR, invoke `rocket-harvest` with the MR URL.

## The two human gates, stated plainly

- **Open questions -> answers.** `rocket-plan` never assumes an answer; `rocket-confirm-plan` refuses to create a single task while one is outstanding.
- **Plan -> approval.** `rocket-approval-check` never treats "the human hasn't objected" as approval. It requires an explicit `APPROVED` comment on the epic, and re-checks it before every implement iteration in case the task list changed underneath it.

Everything else runs unattended, on whatever backend `.kiro/crew/crew.yaml` assigns to
each member. KiroCrew's own config is global, not per-member (verified against a real
install - `agent.acp_backend` and `agent.member_acp_backend` are the only two knobs); before
starting james's session on a different backend than meowth/jessie, run
`scripts/rocket-use-backend.sh james` first.
