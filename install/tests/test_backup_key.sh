#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
tmp=$(mktemp -d)
trap 'trash.sh --discard "$tmp"' EXIT
home="$tmp/home"
mkdir -p "$home"
output="$tmp/output"

printf '%s\n' \
  'https://s3.us-west-004.backblazeb2.com' \
  'course bucket' \
  'fake key id' \
  'fake application key' |
  HOME="$home" bash scripts/backup-key.sh >"$output"

env_file="$home/.config/agent-kit/backup.env"
[[ $(stat -c '%a' "$home/.config/agent-kit") == 700 ]]
[[ $(stat -c '%a' "$env_file") == 600 ]]
set -a
source "$env_file"
set +a
[[ $RESTIC_REPOSITORY == 's3:https://s3.us-west-004.backblazeb2.com/course bucket' ]]
[[ $AWS_ACCESS_KEY_ID == 'fake key id' ]]
[[ $AWS_SECRET_ACCESS_KEY == 'fake application key' ]]
[[ $(cat "$output") == *'backup config saved'* ]]
! grep -Fq 'fake key id' "$output"
! grep -Fq 'fake application key' "$output"
