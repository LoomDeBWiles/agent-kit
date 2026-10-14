#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 || ! $2 =~ ^w[0-9]{2}_[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  printf 'Usage: task-finish.sh <project> <wNN_slug>\n' >&2
  exit 2
fi
project="$HOME/projects/$1"
worktree="$HOME/worktrees/$1/$2"
if [[ ! -d $worktree ]]; then
  printf 'Worktree not found: %s\n' "$worktree" >&2
  exit 1
fi
if [[ -n $(git -C "$worktree" status --porcelain) ]]; then
  printf 'Worktree is dirty: %s\n' "$worktree" >&2
  exit 1
fi
if ! git -C "$project" merge --ff-only "$2"; then
  printf 'Fast-forward failed. Rebase the task branch on main, resolve conflicts, then retry: git -C %s rebase main\n' "$worktree" >&2
  exit 1
fi
git -C "$project" worktree remove "$worktree"
git -C "$project" branch -d "$2"
