#!/usr/bin/env bash
set -euo pipefail
repo=$(git rev-parse --show-toplevel)
new_project="$repo/scripts/new-project.sh"
task_start="$repo/scripts/task-start.sh"
task_finish="$repo/scripts/task-finish.sh"
backup="$repo/scripts/backup.sh"
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test-builder@test.invalid
export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test-builder@test.invalid
export HOME="$tmp/home"
mkdir -p "$HOME"
new_output=$(bash "$new_project" demo)
[[ $new_output == "Created $HOME/projects/demo on branch main." ]]
[[ -f $HOME/projects/demo/context/INDEX.md ]]
cmp "$HOME/projects/demo/context/INDEX.md" "$repo/templates/project/context/INDEX.md"
[[ -d $HOME/projects/demo/work ]]
[[ $(git -C "$HOME/projects/demo" branch --show-current) == main ]]
[[ $(git -C "$HOME/projects/demo" log -1 --format=%s) == 'Initialize project context' ]]
[[ -z $(git -C "$HOME/projects/demo" status --porcelain) ]]
status=0
bash "$new_project" demo >"$tmp/new-existing.out" 2>"$tmp/new-existing.err" || status=$?
[[ $status -eq 1 ]]
grep -F 'Project already exists' "$tmp/new-existing.err"
status=0
bash "$new_project" 'bad name' >"$tmp/new-invalid.out" 2>"$tmp/new-invalid.err" || status=$?
[[ $status -eq 2 ]]
grep -F 'Usage:' "$tmp/new-invalid.err"
start_output=$(bash "$task_start" demo w01_add-thing)
[[ ${start_output##*$'\n'} == "$HOME/worktrees/demo/w01_add-thing" ]]
[[ -e $HOME/worktrees/demo/w01_add-thing/.git ]]
[[ $(git -C "$HOME/worktrees/demo/w01_add-thing" branch --show-current) == w01_add-thing ]]
[[ $(git -C "$HOME/worktrees/demo/w01_add-thing" rev-parse HEAD) == $(git -C "$HOME/projects/demo" rev-parse main) ]]
status=0
bash "$task_start" demo w01_add-thing >"$tmp/start-existing.out" 2>"$tmp/start-existing.err" || status=$?
[[ $status -eq 1 ]]
grep -F 'Worktree already exists' "$tmp/start-existing.err"
status=0
bash "$task_start" demo W1-bad >"$tmp/start-invalid.out" 2>"$tmp/start-invalid.err" || status=$?
[[ $status -eq 2 ]]
grep -F 'Usage:' "$tmp/start-invalid.err"
status=0
bash "$task_start" missing w01_add-thing >"$tmp/start-missing.out" 2>"$tmp/start-missing.err" || status=$?
[[ $status -eq 1 ]]
grep -F 'Project repository not found' "$tmp/start-missing.err"
printf 'uncommitted\n' > "$HOME/worktrees/demo/w01_add-thing/uncommitted.txt"
status=0
bash "$task_finish" demo w01_add-thing >"$tmp/finish-dirty.out" 2>"$tmp/finish-dirty.err" || status=$?
[[ $status -eq 1 ]]
grep -F 'Worktree is dirty' "$tmp/finish-dirty.err"
[[ -d $HOME/worktrees/demo/w01_add-thing ]]
rm "$HOME/worktrees/demo/w01_add-thing/uncommitted.txt"
printf 'task change\n' > "$HOME/worktrees/demo/w01_add-thing/task.txt"
git -C "$HOME/worktrees/demo/w01_add-thing" add task.txt
git -C "$HOME/worktrees/demo/w01_add-thing" commit --quiet -m task
finished_head=$(git -C "$HOME/worktrees/demo/w01_add-thing" rev-parse HEAD)
(cd "$HOME/projects/demo" && bash "$task_finish" demo w01_add-thing)
[[ $(git -C "$HOME/projects/demo" rev-parse main) == "$finished_head" ]]
[[ ! -e $HOME/worktrees/demo/w01_add-thing ]]
! git -C "$HOME/projects/demo" show-ref --verify --quiet refs/heads/w01_add-thing
bash "$new_project" diverge >/dev/null
bash "$task_start" diverge w02_diverge >/dev/null
printf 'main change\n' > "$HOME/projects/diverge/main.txt"
git -C "$HOME/projects/diverge" add main.txt
git -C "$HOME/projects/diverge" commit --quiet -m main
printf 'task change\n' > "$HOME/worktrees/diverge/w02_diverge/task.txt"
git -C "$HOME/worktrees/diverge/w02_diverge" add task.txt
git -C "$HOME/worktrees/diverge/w02_diverge" commit --quiet -m task
status=0
bash "$task_finish" diverge w02_diverge >"$tmp/finish-diverged.out" 2>"$tmp/finish-diverged.err" || status=$?
[[ $status -eq 1 ]]
grep -F 'Fast-forward failed' "$tmp/finish-diverged.err"
[[ -d $HOME/worktrees/diverge/w02_diverge ]]
git -C "$HOME/projects/diverge" show-ref --verify --quiet refs/heads/w02_diverge
mkdir -p "$tmp/bin"
cat > "$tmp/bin/restic" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf '%s|%s\n' "$*" "${RESTIC_PASSWORD_FILE:-}" >> "$RESTIC_LOG"
exit "${RESTIC_STUB_STATUS:-0}"
STUB
cat > "$tmp/bin/crontab" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
case "$1" in
  -l) cat "$CRONTAB_FILE" ;;
  -) cat > "$CRONTAB_FILE" ;;
esac
STUB
chmod +x "$tmp/bin/restic" "$tmp/bin/crontab"
export PATH="$tmp/bin:$PATH"
export RESTIC_LOG="$tmp/restic.log"
export CRONTAB_FILE="$tmp/crontab"
status=0
bash "$backup" >"$tmp/backup-no-env.out" 2>"$tmp/backup-no-env.err" || status=$?
[[ $status -eq 1 ]]
grep -F 'run backup.sh --init first' "$tmp/backup-no-env.err"
status=0
bash "$backup" --init >"$tmp/backup-init-no-env.out" 2>"$tmp/backup-init-no-env.err" || status=$?
[[ $status -eq 1 ]]
grep -F "$HOME/.config/agent-kit/backup.env" "$tmp/backup-init-no-env.err"
mkdir -p "$HOME/.config/agent-kit"
printf 'RESTIC_REPOSITORY=test\nAWS_ACCESS_KEY_ID=test\nAWS_SECRET_ACCESS_KEY=test\n' > "$HOME/.config/agent-kit/backup.env"
[[ $(bash "$backup" --status) == 'no backup recorded' ]]
status=0
bash "$backup" bogus >"$tmp/backup-bogus.out" 2>"$tmp/backup-bogus.err" || status=$?
[[ $status -eq 2 ]]
grep -F 'Usage:' "$tmp/backup-bogus.err"
bash "$backup" --init
[[ $(stat -c %a "$HOME/.config/restic/password") == 600 ]]
[[ $(stat -c %a "$HOME/.config/agent-kit/excludes") == 600 ]]
cmp "$HOME/.config/agent-kit/excludes" "$repo/scripts/excludes"
grep -F "init|$HOME/.config/restic/password" "$RESTIC_LOG"
[[ $(grep -Fxc "*/30 * * * * $HOME/agent-kit/scripts/backup.sh" "$CRONTAB_FILE") -eq 1 ]]
printf '0 9 * * * other-job\n15 3 * * * %s/agent-kit/scripts/backup.sh\n' "$HOME" > "$CRONTAB_FILE"
bash "$backup" --init
[[ $(grep -Fxc "*/30 * * * * $HOME/agent-kit/scripts/backup.sh" "$CRONTAB_FILE") -eq 1 ]]
[[ $(grep -c 'agent-kit/scripts/backup.sh' "$CRONTAB_FILE") -eq 1 ]]
grep -Fx '0 9 * * * other-job' "$CRONTAB_FILE"
: > "$RESTIC_LOG"
bash "$backup"
grep -F "backup $HOME --exclude-caches --exclude-file $HOME/.config/agent-kit/excludes|$HOME/.config/restic/password" "$RESTIC_LOG"
grep -F 'forget --keep-within 2h --keep-hourly 24 --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --keep-yearly 2 --prune|' "$RESTIC_LOG"
grep -F 'check|' "$RESTIC_LOG"
last_backup=$(tail -n 1 "$HOME/.local/state/agent-kit/backup.log")
[[ $last_backup == *' backup ok' ]]
[[ $(bash "$backup" --status) == "$last_backup" ]]
: > "$RESTIC_LOG"
mkdir -p "$HOME/.local/state/agent-kit"
flock "$HOME/.local/state/agent-kit/backup.lock" bash "$backup"
[[ ! -s $RESTIC_LOG ]]
[[ $(tail -n 1 "$HOME/.local/state/agent-kit/backup.log") == "$last_backup" ]]
export RESTIC_STUB_STATUS=3
status=0
bash "$backup" >"$tmp/backup-fail.out" 2>"$tmp/backup-fail.err" || status=$?
[[ $status -eq 3 ]]
failed_backup=$(tail -n 1 "$HOME/.local/state/agent-kit/backup.log")
[[ $failed_backup == *' backup failed (3)' ]]
[[ $(bash "$backup" --status) == "$failed_backup" ]]
