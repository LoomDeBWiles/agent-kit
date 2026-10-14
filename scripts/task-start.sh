#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 || ! $2 =~ ^w[0-9]{2}_[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  printf 'Usage: task-start.sh <project> <wNN_slug>\n' >&2
  exit 2
fi
project="$HOME/projects/$1"
worktree="$HOME/worktrees/$1/$2"
if [[ ! -d $project/.git ]]; then
  printf 'Project repository not found: %s\n' "$project" >&2
  exit 1
fi
if [[ -e $worktree ]]; then
  printf 'Worktree already exists: %s\n' "$worktree" >&2
  exit 1
fi
mkdir -p "$(dirname "$worktree")"
git -C "$project" worktree add -b "$2" "$worktree" main
printf '%s\n' "$worktree"
