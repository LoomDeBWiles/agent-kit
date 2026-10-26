#!/usr/bin/env bash
set -euo pipefail

printf 'B2_ENDPOINT: '
IFS= read -r B2_ENDPOINT
printf 'B2_BUCKET: '
IFS= read -r B2_BUCKET
printf 'B2_KEY_ID: '
IFS= read -rs B2_KEY_ID
printf '\nB2_APP_KEY: '
IFS= read -rs B2_APP_KEY
printf '\n'

config_dir="$HOME/.config/agent-kit"
env_file="$config_dir/backup.env"
install -d -m 700 "$config_dir"
chmod 700 "$config_dir"
umask 077
{
  printf 'RESTIC_REPOSITORY=%q\n' "s3:$B2_ENDPOINT/$B2_BUCKET"
  printf 'AWS_ACCESS_KEY_ID=%q\n' "$B2_KEY_ID"
  printf 'AWS_SECRET_ACCESS_KEY=%q\n' "$B2_APP_KEY"
} > "$env_file"
chmod 600 "$env_file"
printf 'backup config saved\n'
