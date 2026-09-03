# Codex Integration

This integration packages the shared specialist catalog as native Codex custom
agents. For the project-wide role and skill catalogs, start with the
[root README](../README.md).

## Agent definitions and naming

Codex agents are TOML files under `agents/`. Each definition declares a native
snake_case `name`, a routing `description`, a sandbox mode, and developer
instructions. The exact TOML `name` is authoritative; for example,
`go_software_engineer` is defined by `go_software_engineer.toml`.

Model settings are omitted so agents inherit the active session configuration.
See [Codex agents](agents/README.md) for definition conventions and discovery
details.

## Global registry and precedence

[`global-agents.md`](agents/global-agents.md) defines the main-agent coordination
rules and concise role registry. Installation materializes it as the global
`AGENTS.md` in `CODEX_HOME`.

A nonempty `AGENTS.override.md` in the same directory takes precedence over
`AGENTS.md`. The installer warns but does not change the override, so the
installed registry remains inactive until the override is emptied or removed.
More specific project instructions and direct user instructions can also take
precedence over the global registry.

## Installation

### Prerequisites

- Codex is installed.
- Bash 4 or newer is available.
- `rsync` is available on `PATH`; the installer uses it to copy managed
  content and stops with an actionable error when it is unavailable.
- The configured `CODEX_HOME` location, or its parent when it does not yet
  exist, is writable.

`CODEX_HOME` controls the destination and defaults to `~/.codex`. From the
repository root, run either the Make target or direct entrypoint:

```bash
make install-codex
./codex/install/install.sh
```

The entrypoint runs the agent, global-rules, and skill phases in order. It
materializes regular files and directories at:

- `$CODEX_HOME/agents/` for flattened TOML definitions;
- `$CODEX_HOME/AGENTS.md` for the global registry and rules; and
- `$CODEX_HOME/skills/` for skills.

Run a single phase when troubleshooting or developing an installer:

```bash
./codex/install/01_install_agents.sh
./codex/install/02_install_global_agents.sh
./codex/install/03_install_skills.sh
```

Set `FORCE=1` when explicitly refreshing repository-managed content:

```bash
FORCE=1 ./codex/install/install.sh
```

### Preservation behavior

- The installer records its managed paths beneath `CODEX_HOME`. On later runs,
  it refreshes only those manifest-owned copies; `FORCE=1` does not allow it to
  overwrite an untracked collision.
- Existing agent files, skills, or `$CODEX_HOME/AGENTS.md` that are not in that
  manifest are preserved, as are unrelated symlinks.
- Recognized legacy repository symlinks are migrated to local copies. This
  includes the previous repository layouts for agents, skills, and global
  rules; unrelated links remain untouched.
- Managed skills are synchronized with `rsync -a --delete` only within their
  already manifest-owned directory, so user-owned paths are not deleted.

Restart Codex after installation so it reloads agents, rules, and skills.

## Troubleshooting

### Agents, rules, or skills do not appear

Rerun the installer and restart Codex. Installed agents, rules, and skills are
local copies, so they remain available after moving or removing the checkout.
If content is outdated, rerun the installer (optionally with `FORCE=1`) and
restart Codex.

### Global rules were not installed

The installer preserves an untracked `$CODEX_HOME/AGENTS.md`. Move
that path out of the way only if you intend this repository to own the complete
file, then rerun:

```bash
./codex/install/02_install_global_agents.sh
```

Also check the override precedence described in
[Global registry and precedence](#global-registry-and-precedence). Empty or
remove the override only if you want the installed global registry to become
active.

## Testing

The validation and installer suite requires BATS and Python 3.11 or newer:

```bash
make test-codex
```

Validate installer shell scripts separately with:

```bash
shellcheck codex/install/*.sh
```
