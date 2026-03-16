# Install

This directory contains the installer and helper scripts for this repository. The installer handles three tasks:

- Symlink repo-managed agents into `~/.claude/agents/`
- Install the managed global rules block into `~/.claude/CLAUDE.md`
- Symlink skill bundles into `~/.claude/skills/`

## Prerequisites

- Claude Code installed
- A writable `~/.claude/` directory
- Bash 4.x or newer

ShellCheck and [bats](https://github.com/bats-core/bats-core) are recommended for local development.

## Quick Start

From the repository root:

```bash
make install
```

Or directly:

```bash
./install/scripts/install.sh
```

The installer runs three steps in sequence and stops on the first failure.

Restart Claude Code after installation so the updated agents, rules, and skills are picked up.

## Manual Steps

### 01-install-agents.sh

Symlinks agent definition files into `~/.claude/agents/`.

```bash
./install/scripts/01-install-agents.sh
```

Behavior:

- Creates `~/.claude/agents/` if it does not exist
- Removes stale or broken repo-managed agent symlinks
- Creates fresh symlinks for all current repo agents
- Preserves unrelated user-created agents

### 02-install-global-agent-rules.sh

Installs the managed rules block from `agents/global-agent-rules.md` into `~/.claude/CLAUDE.md`.

```bash
./install/scripts/02-install-global-agent-rules.sh
```

Behavior:

- Creates `~/.claude/CLAUDE.md` if needed (skips backup for a just-created file)
- Backs up existing file to `~/.claude/CLAUDE.md.<timestamp>.backup` before changes
- Replaces the block between `<!-- BEGIN AGENT RULES -->` and `<!-- END AGENT RULES -->`
- Skips update if the installed rules are already at least as recent as the source, unless `FORCE=1`

### 03-install-skills.sh

Symlinks skill bundles into `~/.claude/skills/`.

```bash
./install/scripts/03-install-skills.sh
```

Behavior:

- Creates `~/.claude/skills/` if it does not exist
- Removes stale or broken repo-managed skill symlinks
- Creates fresh symlinks for all current repo skills
- Preserves unrelated user-created skills

## Force Reinstall

To reinstall even when dates are current:

```bash
FORCE=1 ./install/scripts/install.sh
```

## Testing

The installer scripts have BATS unit tests in `install/tests/`. Run them with:

```bash
make test
```

## Troubleshooting

### `~/.claude` does not exist

```bash
mkdir -p ~/.claude
```

### Agents or skills do not appear in Claude Code

Restart Claude Code after running the installer.

### Global rules were overwritten unexpectedly

Check for a `~/.claude/CLAUDE.md.<timestamp>.backup` file. The installer creates a backup before updating an existing config.
