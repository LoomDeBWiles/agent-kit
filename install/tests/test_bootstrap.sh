#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
[[ $EUID -ne 0 ]] || { printf 'run this test as a non-root user\n' >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
root_error="$tmp/root.err"
status=0
bash install/bootstrap.sh demo 2>"$root_error" || status=$?
[[ $status -eq 1 ]]
[[ $(cat "$root_error") == 'Run this script as root.' ]]
[[ $(grep -F 'for file in CLAUDE.md settings.json' install/bootstrap.sh) ]]
[[ $(grep -F 'for skill in plan work' install/bootstrap.sh) ]]
[[ $(grep -F 'home/.claude/agents/builder.md' install/bootstrap.sh) ]]
python3 - <<'PY'
from pathlib import Path

bootstrap = Path('install/bootstrap.sh').read_text()
assert 'for file in CLAUDE.md settings.json; do\n  ln -sfn "$kit_dir/home/.claude/$file" "$user_home/.claude/$file"\ndone' in bootstrap
assert 'for skill in plan work; do\n  ln -sfn "$kit_dir/home/.claude/skills/$skill/SKILL.md" "$user_home/.claude/skills/$skill/SKILL.md"\ndone' in bootstrap
PY
expected=$(printf '%s\n' home/.claude/CLAUDE.md home/.claude/agents/builder.md home/.claude/settings.json home/.claude/skills/plan/SKILL.md home/.claude/skills/work/SKILL.md)
actual=$(git ls-files home/.claude ':!home/.claude/tests/**')
[[ $actual == "$expected" ]]
python3 -c 'import json; from pathlib import Path; assert json.loads(Path("home/.claude/settings.json").read_text())["model"] == "opus"'
