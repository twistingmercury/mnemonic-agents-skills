# Install

This directory contains platform-specific installers and shared helper scripts.

The Claude Code installer handles three tasks:

- Symlink repo-managed agents into `~/.claude/agents/`
- Install the managed global rules block into `~/.claude/CLAUDE.md`
- Symlink skill bundles into `~/.claude/skills/`

## Prerequisites

- Claude Code installed
- A writable `~/.claude/` directory
- Bash 4.x or newer

ShellCheck and [bats](https://github.com/bats-core/bats-core) are recommended for local development.

## Quick Start

From the repository root, install the desired integration:

```bash
make install-claude
make install-codex
```

Install both with `make install-all`. `make install` remains an alias for the Claude Code integration.

The platform entrypoints can also be run directly:

```bash
./install/claude/scripts/install.sh
./install/codex/scripts/install.sh
```

Each installer stops on its first failure.

Restart Claude Code after installation so the updated agents, rules, and skills are picked up.

## Claude Code Manual Steps

### 01-install-agents.sh

Symlinks agent definition files into `~/.claude/agents/`.

```bash
./install/claude/scripts/01-install-agents.sh
```

Behavior:

- Creates `~/.claude/agents/` if it does not exist
- Removes stale or broken repo-managed agent symlinks
- Creates fresh symlinks for all current repo agents
- Preserves unrelated user-created agents

### 02-install-global-agent-rules.sh

Installs the managed rules block from `agents/claude/global-agent-rules.md` into `~/.claude/CLAUDE.md`.

```bash
./install/claude/scripts/02-install-global-agent-rules.sh
```

Behavior:

- Creates `~/.claude/CLAUDE.md` if needed (skips backup for a just-created file)
- Backs up existing file to `~/.claude/CLAUDE.md.<timestamp>.backup` before changes
- Replaces the block between `<!-- BEGIN AGENT RULES -->` and `<!-- END AGENT RULES -->`
- Skips update if the installed rules are already at least as recent as the source, unless `FORCE=1`

### 03-install-skills.sh

Symlinks skill bundles into `~/.claude/skills/`.

```bash
./install/claude/scripts/03-install-skills.sh
```

Behavior:

- Creates `~/.claude/skills/` if it does not exist
- Removes stale or broken repo-managed skill symlinks
- Creates fresh symlinks for all current repo skills
- Preserves unrelated user-created skills

## Codex Manual Steps

The initial Codex installer installs portable skills from `skills/shared/` and native Codex skills from `skills/codex/` into `~/.agents/skills/`:

```bash
./install/codex/scripts/03-install-skills.sh
```

Native Codex agent definitions are stored under `agents/codex/` and validated by `install/codex/tests/`. Codex agent and global `AGENTS.md` installation will be added next.

## Force Reinstall

To reinstall even when dates are current:

```bash
FORCE=1 ./install/claude/scripts/install.sh
FORCE=1 ./install/codex/scripts/install.sh
```

## Testing

The Claude installer scripts have BATS unit tests in `install/claude/tests/`. Run them with:

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
