---
name: plan
description: "Write a plan and stop for approval. Use before any change to files, code or settings."
---

# Plan

1. Find the project in `~/projects`. If there is none, ask me for a name and run `~/agent-kit/scripts/new-project.sh <name>`.
2. Read the project's `context/INDEX.md` and the files the change touches.
3. Number the work item one above the highest `work/wNN_*` (start at `w01`). Name it with two to four lowercase words joined by hyphens.
4. Write `work/wNN_<slug>/plan_v1.md`:

```markdown
# wNN <title>

## Goal
One sentence: what will be true when this is done, and for whom.

## Scope
In: ... Out: ...

## Files
| File | Change |
|---|---|

## Steps
Numbered; each small enough for one builder session.

## Acceptance checks
| Check | Command | Pass when the output shows |
|---|---|---|

## Risks
What could go wrong, and what you will do about it.
```

5. Start `work/wNN_<slug>/log.md` with today's date, my request in my words and "Plan v1 written; waiting for approval."
6. Show me the Goal, Steps and Acceptance checks, then stop. Build nothing until I reply "approve".
7. If I ask for changes, write `plan_v2.md` (keep v1), then increment the version for later revisions. Append each revision to `log.md` and stop again.

Keep the plan to the smallest change that does what I asked. For each acceptance check, give the command and expected passing output. Ask me only questions whose answers change the plan.
