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
rules and concise role registry. Installation links it as the global
`AGENTS.md` in `CODEX_HOME`.

A nonempty `AGENTS.override.md` in the same directory takes precedence over
`AGENTS.md`. The installer warns but does not change the override, so the
installed registry remains inactive until the override is emptied or removed.
More specific project instructions and direct user instructions can also take
precedence over the global registry.

## Installation

`CODEX_HOME` controls the destination and defaults to `~/.codex`. From the
repository root, run either the Make target or direct entrypoint:

```bash
make install-codex
./codex/install/install.sh
```

The entrypoint runs the agent, global-rules, and skill phases in order. It
installs links at:

- `$CODEX_HOME/agents/` for flattened TOML definitions;
- `$CODEX_HOME/AGENTS.md` for the global registry and rules; and
- `$CODEX_HOME/skills/` for skills.

Run a single phase when troubleshooting or developing an installer:

```bash
./codex/install/01_install_agents.sh
./codex/install/02_install_global_agents.sh
./codex/install/03_install_skills.sh
```

Set `FORCE=1` to refresh repository-managed links:

```bash
FORCE=1 ./codex/install/install.sh
```

Codex agent installation preserves non-symlink targets, including colliding
basenames. Global-rule installation also preserves non-symlink targets;
`FORCE=1` may replace an unrelated `AGENTS.md` symlink. Skill paths with names
managed by this repository may be replaced. See the
[complete installation behavior](../INSTALL.md) before installing over custom
content.

Restart Codex after installation so it reloads agents, rules, and skills.

## Testing

The validation and installer suite requires BATS and Python 3.11 or newer:

```bash
make test-codex
```

Validate installer shell scripts separately with:

```bash
shellcheck codex/install/*.sh
```

For troubleshooting and preservation details, see [Installation](../INSTALL.md).
