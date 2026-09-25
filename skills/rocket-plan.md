---
description: Discover the code, draft the HOW with citations, challenge it, and put one question batch to the human on the beads epic
crew_member: meowth
argument-hint: the beads epic id from rocket-ideate
---

# Plan (meowth drafts, jessie challenges)

```bash
[ -f .kiro/crew/beads-dir ] && export BEADS_DIR=$(cat .kiro/crew/beads-dir)
bd show <epic-id>
```

Read first: `.kiro/steering/opinions.md`, `.kiro/steering/philosophy.md`, `.kiro/steering/failure-modes.md`, and the project's own docs (CLAUDE.md, AGENTS.md, rules files). That direct read is the reliable baseline on every backend; it is never skipped in favor of what follows.

If you are running as a KiroCrew session and the `knowledge_add_document` tool is available, also add each of the three steering files to the Knowledge Library, one call per file, with `title` set to its path (`.kiro/steering/opinions.md` etc.) so a rerun updates the same document instead of duplicating it. This costs nothing extra to discovery and lets `local_knowledge_search` surface a relevant passage by meaning later in this skill or in `rocket-implement`, instead of everyone re-reading the whole file cold every time. If the tool is not available (no KiroCrew, or `knowledge.auto_add_documents` is off), skip this without comment - the direct read above already covers you.

## 1. Discover (meowth)

Given WHY and WHAT, find everything needed to write the HOW. Read the code the story touches, its siblings, its tests. If `local_knowledge_search` is available, also search it for prior decisions or steering passages relevant to this story - it can surface something the direct reads above missed by wording rather than location. Cite every source. Log every decision as a beads comment on the epic, in this shape:

```
DECISION: <what>
REASON: <why>
EVIDENCE: <file:line, doc, or command output>
REJECTED: <alternatives and why not - mandatory; write "none considered" if truly none>
```

Do not guess. A question the repo, the tracker, or the project docs can answer is answered there. Note the repo's no-touch files (toolchain pins, CI config) and the gates that must pass.

## 2. Draft the HOW

Split the work into grapes. A grape is a task one `rocket-implement` invocation finishes: one logical change, 1 to 3 small commits. Each task gets:
- What to do and how, with file pointers. Specific enough that the implementer never has to think about design.
- The behaviours and test cases it must pin (the spec; code and tests implement it).
- The verification setup: env, data, commands that prove it at runtime.
- The gates to run before done.

## 3. Challenge (jessie)

Delegate a fresh-eyes review of the draft to the jessie crew member (or, if this crew has no separate jessie session available, switch hats deliberately and re-read the draft cold). Her checklist: is each task a grape? Can she name a regression a test would catch per acceptance row? Is the verification setup runnable as written? Any failure mode from `.kiro/steering/failure-modes.md` baked into the design? Any contradiction between acceptance rows? Converge with her before finishing.

## 4. Hand over to the human

Collect what discovery and the challenge could not settle into ONE batch of numbered questions. Each question carries its evidence trail ("checked X and Y; could not determine Z") or arrives as confirm/deny with the evidence.

Post to the beads epic, as comments (beads is the durable copy - this is the only handoff that matters, no run dies and takes it with it):
- the full plan draft,
- the numbered question batch, under the heading `OPEN QUESTIONS`.

**Do not create tasks. Do not assume answers. This skill ends here.** Finish by stating: the epic id, where the questions are, and that the human should answer them as a comment on the epic and then invoke `rocket-confirm-plan` with that epic id. Confirming the plan is the approval path; nothing is built before it.
