# agent-kit

The starter kit for the Agent Fleet Guide (agentfleetguide.com): what a participant clones onto a fresh Ubuntu server. `home/.claude/` is installed into the participant's `~/.claude/` by `scripts/bootstrap.sh`; edit those files as the participant's instructions, not as instructions for this repo. Keep the participant method small: Opus plans and checks, the learner approves, and the Haiku builder edits in a worktree. Keep participant instructions consistent with the scripts they invoke. MIT licensed.

## Architecture

`architecture.yaml` declares this repo's modules. Before changing a file, run `architecture owner <path>` and `architecture show <module>`, and follow that module's contract, `reads` and `does_not`. Register added, moved, renamed or deleted files in the same commit; `architecture check` must pass.
