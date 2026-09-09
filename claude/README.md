# Claude Code Integration

This integration packages the shared specialist catalog for Claude Code. For
the project-wide role and skill catalogs, start with the [root README](../README.md).

## Agent definitions and naming

Claude agents are Markdown files under `agents/`. YAML frontmatter declares the
agent's display `name`, description, model, memory, and allowed tools; the body
contains its working instructions.

Display names use spaces, such as `go software engineer`, while definition
filenames use hyphens, such as `go-software-engineer.md`. Use the display name
when requesting or delegating to a role.

See [About the agents](agents/ABOUT-THE-AGENTS.md) for role boundaries and the
full workflow model.

## Main Claude workflow

Main Claude owns coordination and the final response. It can consult an
architect, delegate artifact production to implementation specialists, and
then request independent validation. For example:

```text
User: "Build a user management REST API in Go"

Main Claude:
  1. Consults solutions architect
  2. Delegates the Go plan to go software architect
  3. Delegates the contract to api architect
  4. Delegates implementation to go software engineer
  5. Delegates black-box tests to go e2e test engineer
```

Narrow requests can go directly to one specialist:

```text
"Write BATS tests for scripts/backup.sh" -> bats test engineer
"Update the project README" -> technical writer
```

## Global rules

[`GLOBAL_AGENT_RULES.md`](agents/GLOBAL_AGENT_RULES.md) is the source for the
managed agent-rules block in the user's global `CLAUDE.md`. The installer uses
the embedded `Last Updated` date to avoid unnecessary rewrites unless
`FORCE=1` is set.

## Installation

### Prerequisites

- Claude Code is installed.
- Bash 4 or newer is available.
- Make is available if using the Make targets below.
- The home directory is writable. The full installer creates `~/.claude` as
  needed; the standalone global-rules phase expects it to exist already.

From the repository root, run either the Make target or direct entrypoint:

```bash
make install-claude
./claude/install/install.sh
```

The entrypoint runs the agent, global-rules, and skill phases in order. The
default destinations are:

- agent links: `~/.claude/agents/`
- managed global rules: `~/.claude/CLAUDE.md`
- skill links: `~/.claude/skills/`

Run a single phase when troubleshooting or developing an installer:

```bash
./claude/install/01_install_agents.sh
./claude/install/02_install_global_agents.sh
./claude/install/03_install_skills.sh
```

Set `FORCE=1` to refresh current repository-managed links and reinstall a
managed rules block even when its date is current:

```bash
FORCE=1 ./claude/install/install.sh
```

### Preservation behavior

- Agent and skill names absent from the repository catalog are preserved,
  except broken agent symlinks, which are removed.
- Agent or skill paths whose basenames collide with repository-managed content
  may be replaced. Back up custom content with a colliding name first.
- The global-rules phase creates `~/.claude/CLAUDE.md.<timestamp>.backup` when
  adding rules to an existing file without a managed block or replacing a block
  with a readable installed date.
- For a dated block with complete rule markers, updates remove the old block
  and append the current one, retaining content outside those markers.

Restart Claude Code after installation so it reloads agents, rules, and skills.

## Troubleshooting

### Migrating the renamed .NET starter

The installer preserves skill names absent from the catalog, so the old
`dotnet-minimal-api-starter` symlink can remain broken after the rename to
[`dotnet-postgres-api-starter`](../shared/skills/dotnet-postgres-api-starter/SKILL.md).
Save any custom changes, then remove only the obsolete installed
`dotnet-minimal-api-starter` entry from `SKILLS_DIR` when set, otherwise
`~/.claude/skills`. Remove the link itself, leaving its target untouched.
From the repository root, rerun `make install-claude` with the same destination
configuration, then restart Claude Code.

### Agents or skills do not appear

Rerun the installer and restart Claude Code. Agent and skill installations use
symlinks, so moving the checkout makes those links stale. Rerunning the
installer from the checkout's new location repairs repository-managed links.

### Global rules were overwritten

Look for `~/.claude/CLAUDE.md.<timestamp>.backup`, created for the updates
described in [Preservation behavior](#preservation-behavior). If installation
fails after the backup is created, the installer attempts to restore it.

### The global-rules phase cannot find Claude configuration

Confirm that `~/.claude` exists and is writable, then rerun:

```bash
./claude/install/02_install_global_agents.sh
```

## Testing

The installer suite requires BATS, Bash, and Make. From the repository root,
clear destination overrides so tests use their temporary fixtures:

```bash
env -u AGENTS_DIR -u SKILLS_DIR make test-claude
```

With ShellCheck installed, validate installer shell scripts separately:

```bash
shellcheck claude/install/*.sh
```
