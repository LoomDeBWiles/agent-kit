#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  printf 'Run this script as root.\n' >&2
  exit 1
fi
if [[ $# -ne 1 || ! $1 =~ ^[a-z_][a-z0-9_-]*$ ]]; then
  printf 'Usage: bootstrap.sh <username>\n' >&2
  exit 2
fi
username=$1
user_home="/home/$username"
kit_dir="$user_home/agent-kit"

export DEBIAN_FRONTEND=noninteractive
apt_update_deadline=$((SECONDS + 600))
while true; do
  if apt-get update; then
    break
  fi
  remaining=$((apt_update_deadline - SECONDS))
  if (( remaining <= 0 )); then
    printf 'apt-get update failed after waiting up to 10 minutes for another package install to finish.\n' >&2
    exit 1
  fi
  printf 'Waiting for another package install to finish...\n'
  sleep "$((remaining < 10 ? remaining : 10))"
done
apt-get -o DPkg::Lock::Timeout=600 install -y git tmux python3 python3-venv curl unzip bzip2 shellcheck restic cron sudo ufw openssl

if ! id "$username" >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash --groups sudo "$username"
else
  usermod --append --groups sudo "$username"
fi
sudoers_file="/etc/sudoers.d/90-agent-kit-$username"
sudoers_tmp=$(mktemp "/etc/sudoers.d/.90-agent-kit-$username.XXXXXX")
trap '[[ -z ${sudoers_tmp:-} ]] || rm -f -- "$sudoers_tmp"' EXIT
printf '%s ALL=(ALL) NOPASSWD:ALL\n' "$username" > "$sudoers_tmp"
chmod 440 "$sudoers_tmp"
visudo -cf "$sudoers_tmp"
mv -f -- "$sudoers_tmp" "$sudoers_file"
sudoers_tmp=
install -d -m 700 -o "$username" -g "$username" "$user_home/.ssh"
if [[ -f /root/.ssh/authorized_keys ]]; then
  install -m 600 -o "$username" -g "$username" /root/.ssh/authorized_keys "$user_home/.ssh/authorized_keys"
fi

cat > /etc/ssh/sshd_config.d/agent-kit.conf <<'SSH'
PasswordAuthentication no
PermitRootLogin no
SSH
sshd -t
systemctl reload ssh
ufw allow OpenSSH
ufw --force enable

if [[ ! -d $kit_dir ]]; then
  sudo -u "$username" git clone https://github.com/LoomDeBWiles/agent-kit "$kit_dir"
fi
install -d -o "$username" -g "$username" "$user_home/.claude/skills/plan" "$user_home/.claude/skills/work" "$user_home/.claude/agents" "$user_home/projects" "/home/$username/worktrees"
for file in CLAUDE.md settings.json; do
  ln -sfn "$kit_dir/home/.claude/$file" "$user_home/.claude/$file"
done
for skill in plan work; do
  ln -sfn "$kit_dir/home/.claude/skills/$skill/SKILL.md" "$user_home/.claude/skills/$skill/SKILL.md"
done
ln -sfn "$kit_dir/home/.claude/agents/builder.md" "$user_home/.claude/agents/builder.md"
chown -hR "$username:$username" "$user_home/.claude"
sudo -u "$username" env HOME="$user_home" bash -lc 'curl -fsSL https://claude.ai/install.sh | bash'

printf 'Bootstrap complete for %s. Next: sign in as %s, run claude, then create a project with ~/agent-kit/scripts/new-project.sh <name>.\n' "$username" "$username"
