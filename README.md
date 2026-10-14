# agent-kit

The starter kit for the Agent Field Guide helps you plan and build projects with AI agents on your own Ubuntu server. It installs participant instructions, project setup scripts and nightly backup tools. Read the [Agent Field Guide](https://agentfieldguide.org/) for the walkthrough.

On a fresh Ubuntu 24.04 server, sign in as root and run:

```sh
git clone https://github.com/LoomDeBWiles/agent-kit /tmp/agent-kit
bash /tmp/agent-kit/scripts/bootstrap.sh <username>
```

After bootstrap, sign in as the new user, start `claude`, and follow the plan skill before making project changes.
