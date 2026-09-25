---
description: Check every open question is answered, then persist the approved plan as grape tasks
crew_member: meowth
argument-hint: the beads epic id
---

# Confirm the plan (meowth)

Input: the beads epic id.

```bash
[ -f .kiro/crew/beads-dir ] && export BEADS_DIR=$(cat .kiro/crew/beads-dir)
bd show <epic-id>
bd comments <epic-id>
```

## 1. Gate

Read the epic's comments: the plan draft, every `OPEN QUESTIONS` batch (from `rocket-plan` or from earlier confirm attempts), and the human's answers. Match every question to an answer.

**If any question has no answer: the gate fails. Create nothing. Modify nothing.** No tasks, no code, no "unblocked slice" - a task is unblocked by an answer, never by your judgment that it doesn't depend on one. Partial builds against an unconfirmed plan are forbidden; the human approves plans, not fragments.

You cannot skip past your own failure by continuing anyway - the next skill in the chain (`rocket-approval-check`, then `rocket-implement`) will not run until it sees a `GATE: PASS` comment, checked mechanically by `scripts/rocket-gate-check.sh`. So on gate failure your LAST action is:

```bash
bd comment <epic-id> "GATE: FAIL <one line per unanswered question>"
```

Post `GATE: PASS` **only** at the very end of step 3, after tasks are persisted and audited. Never post it earlier; a missing or FAIL comment fails closed, which is correct.

The gate also fails when the answers **re-scope the story** (the plan-of-record no longer describes the work). Do not author and self-approve a replacement plan. Post what changed and the best draft you can as epic comments, post `GATE: FAIL`, and direct the human to rerun `rocket-plan` - scope changes re-enter planning, where the draft gets challenged before anyone approves it.

The failure comment must contain, verbatim:
- the unanswered questions, and
- a list of the human comments you DID find on the epic (timestamp + first line each). If the human believes they answered and their comment is not in that list, it never registered - that must be visible at a glance, not discovered later.

The human's comments may contain follow-up questions of their own. **Reply to every one of them as a comment on the epic** - answered from the code, the tracker, or the decision log, with the evidence cited. If a follow-up needs the human's judgment rather than evidence, put it in a fresh `OPEN QUESTIONS` batch and fail this step. A follow-up is never skipped and never silently absorbed: the human must be able to read its answer on the epic.

## 2. Finalize

Fold the answers into the HOW. If an answer invalidates part of the draft, rework that part and log the decision (DECISION / REASON / EVIDENCE / REJECTED) as a comment. If an answer raises a new question that the repo, tracker, and docs cannot settle: post a fresh `OPEN QUESTIONS` batch on the epic and **fail this step**, same as the gate. The human answers and reruns `rocket-confirm-plan`. As many rounds as it takes; nothing is built in between.

## 3. Persist

This step is rerun-safe: check `bd list --parent <epic>` first. Tasks that already exist and match the final HOW stay untouched; create only what is missing; close-with-reason any task the answers made obsolete. Never create a duplicate of an existing task.

Create the missing tasks in beads: `bd create --type=task --parent=<epic>`, real dependency edges, each task carrying its spec, file pointers, verification setup, and gates (see the plan draft). Re-read the full task list and diff it against the draft plus answers: no duplicated entities, no ordering that lives only in prose, no hedged pointer where an answer exists.

Verify the task list actually persisted: `bd list --parent <epic>` returns every task you just created. If it doesn't, post `GATE: FAIL` and stop - the next skill trusts beads as the only handoff; a task that silently didn't save strands it.

Everything green? Then, as your final action: `bd comment <epic-id> "GATE: PASS plan confirmed, N tasks persisted"`.
