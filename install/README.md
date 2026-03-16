# Agent Setup

This directory contains the installer and helper scripts for the agents in this repository. The setup is limited to two tasks:

- Install repo-managed agents into `~/.claude/agents/`
- Install the managed global rules block into `~/.claude/CLAUDE.md`

It does not provision Docker services, skills, commands, or external memory infrastructure.

## Prerequisites

Before running setup, make sure you have:

- Claude Code installed
- A writable `~/.claude/` directory
- Bash 4.x or newer

ShellCheck is recommended if you want to validate the scripts locally.

## Quick Start

From the repository root:

```bash
make install
```

Or from this directory:

```bash
./scripts/installer.sh
```

The installer runs two steps:

1. `01-install-agents.sh`
2. `02-install-global-agent-rules.sh`

Logs are written to `scripts/logs/{TIMESTAMP}/`.

Restart Claude Code after installation so the updated agents and global rules are picked up.

## Manual Setup

If you want to run each step yourself:

### 01-install-agents.sh

Installs agent definition symlinks into `~/.claude/agents/`.

```bash
./scripts/01-install-agents.sh
```

Behavior:

- Creates `~/.claude/agents/` if it does not exist
- Removes and replaces repo-managed agents
- Preserves unrelated user-created agents
- Logs to `scripts/logs/{TIMESTAMP}/01-install-agents.log`

### 02-install-global-agent-rules.sh

Installs the managed rules block from `agents/global-agent-rules.md` into `~/.claude/CLAUDE.md`.

```bash
./scripts/02-install-global-agent-rules.sh
```

Behavior:

- Creates `~/.claude/CLAUDE.md` if needed
- Backs up the existing file to `~/.claude/CLAUDE.md.backup`
- Replaces the block between `<!-- BEGIN AGENT RULES -->` and `<!-- END AGENT RULES -->`
- Logs to `scripts/logs/{TIMESTAMP}/02-install-global-agent-rules.log`

## Installer Behavior

The top-level installer is `scripts/installer.sh`. It sets a shared timestamp, runs both setup steps, and stops on the first failure.

This script does not install anything outside the agent catalog and managed global rules block.

## Troubleshooting

### `~/.claude` does not exist

Create the directory first:

```bash
mkdir -p ~/.claude
```

### Agents do not appear in Claude Code

Restart Claude Code after running the installer.

### Global rules were overwritten unexpectedly

Check `~/.claude/CLAUDE.md.backup`. The installer creates a backup before it updates an existing file.
