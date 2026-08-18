# Install

This directory contains platform-specific installers and shared helper scripts.

The Claude Code installer handles three tasks:

- Symlink repo-managed agents into `~/.claude/agents/`
- Install the managed global rules block into `~/.claude/CLAUDE.md`
- Symlink skill bundles into `~/.claude/skills/`

The Codex installer handles three tasks:

- Flatten and symlink native agent definitions into `$CODEX_HOME/agents/`
- Symlink the global coordination rules as `$CODEX_HOME/AGENTS.md`
- Symlink skill bundles into `$CODEX_HOME/skills/`

`CODEX_HOME` defaults to `~/.codex` when unset.

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

Restart the target client after installation so the updated agents, rules, and skills are picked up.

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

### 01-install-agents.sh

Recursively discovers native TOML definitions under `agents/codex/`, flattens them by basename, and symlinks them into `$CODEX_HOME/agents/`:

```bash
./install/codex/scripts/01-install-agents.sh
```

Behavior:

- Creates `$CODEX_HOME/agents/` if it does not exist
- Replaces stale or broken repo-managed agent symlinks
- Preserves unrelated user-created agents and existing non-symlink paths
- Keeps current symlinks unless `FORCE=1`

### 02-install-global-agent-rules.sh

Links `agents/codex/global-agents.md` as `$CODEX_HOME/AGENTS.md`:

```bash
./install/codex/scripts/02-install-global-agent-rules.sh
```

Behavior:

- Creates `$CODEX_HOME` when needed
- Creates an absolute symlink so source updates are available without reinstalling
- Keeps a correct link and repairs stale or broken repository-managed links
- Preserves unrelated symlinks and existing non-symlink paths by default
- Warns when a nonempty `$CODEX_HOME/AGENTS.override.md` makes the installed rules inactive

Restart Codex after changing or reinstalling global guidance because Codex loads its instruction chain once per run or launched session.

### 03-install-skills.sh

Installs portable skills from `skills/shared/` and optional native Codex skills from `skills/codex/` into `$CODEX_HOME/skills/`:

```bash
./install/codex/scripts/03-install-skills.sh
```

Agent definitions and installer behavior are validated by `install/codex/tests/`.

## Force Reinstall

To refresh repository-managed content:

```bash
FORCE=1 ./install/claude/scripts/install.sh
FORCE=1 ./install/codex/scripts/install.sh
```

## Testing

Both platform installers have BATS tests under their respective `tests/` directories. Run them with:

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

### Codex global rules were not linked

The Codex installer preserves an existing user-owned `$CODEX_HOME/AGENTS.md`. Move that file out of the way only if you intend the repository to own the complete global guidance file, then rerun `02-install-global-agent-rules.sh`.

If `$CODEX_HOME/AGENTS.override.md` is nonempty, Codex loads it instead of `$CODEX_HOME/AGENTS.md` until the override is removed.
