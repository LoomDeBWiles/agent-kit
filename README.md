# agent-kit

The starter kit for the Agent Fleet Guide helps you plan and build projects with AI agents on your own Ubuntu server. It installs participant instructions, project setup scripts and backups that run every 30 minutes. Read the [Agent Fleet Guide](https://agentfleetguide.com/) for the walkthrough.

On a fresh Ubuntu 24.04 server, connect as root using the server's IP address in place of `$SERVER_IP`, then run the three commands:

```sh
ssh root@$SERVER_IP
git clone https://github.com/LoomDeBWiles/agent-kit /tmp/agent-kit
bash /tmp/agent-kit/install/bootstrap.sh <username>
```

After bootstrap, sign in as the new user, start `claude`, and follow the plan skill before making project changes.

## Backups

Before `backup.sh --init`, create `~/.config/agent-kit/backup.env` with mode `600` and set `RESTIC_REPOSITORY`, `AWS_ACCESS_KEY_ID`, and `AWS_SECRET_ACCESS_KEY`.
