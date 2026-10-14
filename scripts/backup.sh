#!/usr/bin/env bash
set -euo pipefail

config_dir="$HOME/.config/agent-kit"
env_file="$config_dir/backup.env"
password_file="$HOME/.config/restic/password"
exclude_file="$config_dir/excludes"
log_file="$HOME/.local/state/agent-kit/backup.log"
script_dir=$(cd "$(dirname "$0")" && pwd)

if [[ ! -f $env_file ]]; then
  if [[ ${1:-} == --init ]]; then
    printf 'Create %s with mode 600 and set RESTIC_REPOSITORY, AWS_ACCESS_KEY_ID, and AWS_SECRET_ACCESS_KEY.\n' "$env_file" >&2
  else
    printf 'run backup.sh --init first\n' >&2
  fi
  exit 1
fi
set -a
# shellcheck source=/dev/null
source "$env_file"
set +a

if [[ ${1:-} == --status ]]; then
  if [[ -f $log_file ]]; then tail -n 1 "$log_file"; else printf 'no backup recorded\n'; fi
  exit 0
fi
if [[ ${1:-} != '' && ${1:-} != --init ]]; then
  printf 'Usage: backup.sh [--init|--status]\n' >&2
  exit 2
fi
if [[ ! -f $exclude_file ]]; then
  install -d -m 700 "$config_dir"
  install -m 600 "$script_dir/excludes" "$exclude_file"
fi
if [[ ${1:-} == --init ]]; then
  install -d -m 700 "$(dirname "$password_file")" "$config_dir"
  if [[ ! -f $password_file ]]; then
    openssl rand -base64 32 > "$password_file"
    chmod 600 "$password_file"
  fi
  export RESTIC_PASSWORD_FILE=$password_file
  restic init
  existing_cron=$(crontab -l 2>/dev/null || true)
  printf '%s\n15 3 * * * %s/scripts/backup.sh\n' "$existing_cron" "$HOME/agent-kit" | awk '!seen[$0]++' | crontab -
  exit 0
fi

export RESTIC_PASSWORD_FILE=$password_file
mkdir -p "$(dirname "$log_file")"
if restic backup "$HOME" --exclude-caches --exclude-file "$exclude_file" && restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune && restic check; then
  printf '%s backup ok\n' "$(date --iso-8601=seconds)" >> "$log_file"
else
  status=$?
  printf '%s backup failed (%s)\n' "$(date --iso-8601=seconds)" "$status" >> "$log_file"
  exit "$status"
fi
