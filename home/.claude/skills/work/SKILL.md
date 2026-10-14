---
name: work
description: "Build an approved plan with the builder subagent, check it and merge. Use after I approve a plan."
---

# Work

1. Confirm I approved the current `plan_vN` of `wNN`. Append "Approved plan_vN" to `log.md`. Commit this item's plan and log in the project before creating the worktree, so the builder can read them there.
2. Make the worktree: `~/agent-kit/scripts/task-start.sh <project> wNN_<slug>` prints its path. All building and further work-record updates happen there.
3. Hand the build to the `builder` subagent (model: haiku). Its prompt contains the worktree path, the plan path inside the worktree, the steps and acceptance checks, "commit your changes in the worktree with a message starting wNN", and "write your report to `work/wNN_<slug>/build_report.md` in the worktree: what you changed, the commands you ran with their output, and anything you could not do". One builder at a time.
4. Check its work yourself; its report is a claim, not proof:
   - Read `git -C <worktree> diff main...HEAD` in full.
   - Run every acceptance check and compare the output with the plan.
   - Look for changes the plan did not ask for.
5. If a check fails or the diff is wrong, send the builder back with the exact defect and required correction, then repeat the checks in step 4. After two correction rounds without a pass, stop and tell me. If the fix changes the approved scope, return to the plan skill for approval.
6. When every check passes, write `work/wNN_<slug>/work_report.md` in the worktree: what changed, each check with its result, and anything left undone. Commit it with the updated log and build report; confirm the worktree is clean.
7. Merge: `~/agent-kit/scripts/task-finish.sh <project> wNN_<slug>`. After success, append "Merged" to `log.md` in the project and commit that log. If the script fails, report its error without claiming a merge.
8. Tell me what changed, the checks and their results, and anything I should look at.
