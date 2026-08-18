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
managed agent-rules block in the user's global `CLAUDE.md`. The installer:

- creates `~/.claude/CLAUDE.md` when it does not exist;
- replaces only content between the managed rule markers;
- backs up an existing file before changing that block; and
- compares the embedded `Last Updated` date before reinstalling.

Content outside the managed markers remains user-owned.

## Installation

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

Unrelated agent and skill names are preserved. Paths whose basenames collide
with repository-managed agents or skills may be replaced; review the
[complete installation behavior](../INSTALL.md) before installing over a
custom catalog.

Restart Claude Code after installation so it reloads agents, rules, and skills.

## Testing

The installer suite requires BATS:

```bash
make test-claude
```

Validate installer shell scripts separately with:

```bash
shellcheck claude/install/*.sh
```

For troubleshooting and preservation details, see [Installation](../INSTALL.md).
