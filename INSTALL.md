# Installation

Claude Code and Codex each have a self-contained installer. Both install agents,
global guidance, and the portable skills from `shared/skills/`.

## Prerequisites

- Claude Code and/or Codex installed for the integration you want to use
- Bash 4.x or newer
- A writable platform home directory (`~/.claude` or `$CODEX_HOME`)

ShellCheck and [BATS](https://github.com/bats-core/bats-core) are recommended
for local development.

## Quick Start

From the repository root, install one or both integrations:

```bash
make install-claude
make install-codex
make install-all
```

`make install` remains an alias for `make install-claude`. The direct platform
entrypoints are:

```bash
./claude/install/install.sh
./codex/install/install.sh
```

Each entrypoint runs its three phases in order and stops on the first failure.
Restart the target client after installation so it reloads agents, global
guidance, and skills.

## Claude Code Installation

The Claude installer runs:

1. `claude/install/01_install_agents.sh` symlinks agent definitions from
   `claude/agents/` into `~/.claude/agents/`.
2. `claude/install/02_install_global_agents.sh` installs the managed rules block
   from `claude/agents/GLOBAL_AGENT_RULES.md` into `~/.claude/CLAUDE.md`.
3. `claude/install/03_install_skills.sh` symlinks skill bundles into
   `~/.claude/skills/`.

The agent and skill phases remove stale or broken repository-managed links and
preserve unrelated user content. The global-rules phase creates
`~/.claude/CLAUDE.md` when needed and backs up an existing file before replacing
the block between the managed markers. It skips a current block unless
`FORCE=1` is set.

Run an individual phase when needed:

```bash
./claude/install/01_install_agents.sh
./claude/install/02_install_global_agents.sh
./claude/install/03_install_skills.sh
```

## Codex Installation

`CODEX_HOME` defaults to `~/.codex`. The Codex installer runs:

1. `codex/install/01_install_agents.sh` recursively discovers TOML definitions
   under `codex/agents/`, flattens them by basename, and links them into
   `$CODEX_HOME/agents/`.
2. `codex/install/02_install_global_agents.sh` links
   `codex/agents/global-agents.md` as `$CODEX_HOME/AGENTS.md`.
3. `codex/install/03_install_skills.sh` links skill bundles into
   `$CODEX_HOME/skills/`.

The agent phase replaces stale or broken repository-managed links while
preserving unrelated agents and existing non-symlink paths. The global-rules
phase creates an absolute link, keeps a correct link, repairs links managed by
this repository's current or legacy layout, and preserves unrelated links and
non-symlink paths by default. It warns when a nonempty
`$CODEX_HOME/AGENTS.override.md` suppresses the installed global guidance.

Run an individual phase when needed:

```bash
./codex/install/01_install_agents.sh
./codex/install/02_install_global_agents.sh
./codex/install/03_install_skills.sh
```

## Force Reinstall

Set `FORCE=1` to refresh repository-managed content:

```bash
FORCE=1 ./claude/install/install.sh
FORCE=1 ./codex/install/install.sh
```

Existing non-symlink Codex agent and global-rules targets are still preserved.
An unrelated Codex `AGENTS.md` symlink is replaced only with `FORCE=1`.

## Testing

Run both platform BATS suites:

```bash
make test
```

Use `make test-claude` or `make test-codex` for one platform.

## Troubleshooting

### Agents or skills do not appear

Rerun the matching platform installer and restart the client. Because installed
content uses symlinks, moving the repository makes existing links stale; running
the installer from the new checkout location repairs repository-managed links.

### Claude global rules were overwritten

Check for `~/.claude/CLAUDE.md.<timestamp>.backup`. The installer creates a
backup before updating an existing config.

### Codex global rules were not linked

The Codex installer preserves an existing non-symlink `$CODEX_HOME/AGENTS.md`.
Move that path out of the way only if you intend this repository to own the
complete file, then rerun `codex/install/02_install_global_agents.sh`.

If `$CODEX_HOME/AGENTS.override.md` is nonempty, Codex loads it instead of
`$CODEX_HOME/AGENTS.md` until the override is removed or emptied.
