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

### Prerequisites

- Codex is installed.
- Bash 4 or newer is available.
- The configured `CODEX_HOME` location, or its parent when it does not yet
  exist, is writable.

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

### Preservation behavior

- Agent paths that are not symlinks are preserved, including paths whose
  basenames collide with repository-managed agents. This remains true with
  `FORCE=1`.
- An existing non-symlink `$CODEX_HOME/AGENTS.md` is preserved, including with
  `FORCE=1`. An unrelated symlink is preserved by default but may be replaced
  with `FORCE=1`.
- Agent and skill names not managed by this repository are preserved. Skill
  paths whose names collide with repository-managed skills may be replaced.
- Repository-managed stale or broken links are repaired. The global-rules
  phase also recognizes links from the repository's legacy layout.

Restart Codex after installation so it reloads agents, rules, and skills.

## Troubleshooting

### Agents, rules, or skills do not appear

Rerun the installer and restart Codex. Installed content uses symlinks, so
moving the checkout makes those links stale. Rerunning the installer from the
checkout's new location repairs repository-managed links.

### Global rules were not linked

The installer preserves an existing non-symlink `$CODEX_HOME/AGENTS.md`. Move
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
