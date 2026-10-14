#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || ! $1 =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]]; then
  printf 'Usage: new-project.sh <name>\n' >&2
  exit 2
fi
if ! git var GIT_COMMITTER_IDENT >/dev/null 2>&1; then
  printf 'Set git identity first: git config --global user.name "Your Name" && git config --global user.email "you@example.com"\n' >&2
  exit 1
fi
script_dir=$(cd "$(dirname "$0")" && pwd)
project="$HOME/projects/$1"
if [[ -e $project ]]; then
  printf 'Project already exists: %s\n' "$project" >&2
  exit 1
fi
mkdir -p "$project/context" "$project/work"
cp "$script_dir/../templates/project/context/INDEX.md" "$project/context/INDEX.md"
git -C "$project" init --quiet --initial-branch=main
git -C "$project" add context/INDEX.md
git -C "$project" commit --quiet -m 'Initialize project context'
printf 'Created %s on branch main.\n' "$project"
