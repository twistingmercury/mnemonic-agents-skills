# Claude Code Agent Ecosystem

> **Maturity Level**: Basic - Ready for use. The agent catalog is usable now and will continue to evolve as workflows improve.
> **Version**: v1.0.0
>
> - **Emerging**: Prototype, not production-ready, expect breaking changes
> - **Basic**: Production-ready but actively evolving, expect minor version changes
> - **Mature**: Stable, battle-tested, changes are rare

Specialized development agents and skills for AI-assisted software work in Claude Code. This repository manages agent definitions, global delegation rules, and installable skill bundles.

## Table of Contents

- [Usage](#usage)
- [How it works](#how-it-works)
- [Key Considerations](#key-considerations)
- [Development Considerations](#development-considerations)
- [Versioning](#versioning)

## Usage

### Invoking agents

You can request a specific agent by name, or simply describe the work and let Claude decide which specialists to involve. Either way, Claude handles delegation — you do not invoke agent files directly.

```text
User: "Build a user management REST API in Go"

Main Claude:
  1. Consults solutions architect for high-level direction
  2. Hands implementation planning to go software architect
  3. Sends API contract work to api architect
  4. Delegates implementation to go software engineer
  5. Delegates test coverage to go e2e test engineer
```

For narrow tasks, Main Claude can delegate directly:

```text
User: "Write BATS tests for scripts/backup.sh"
  -> Main Claude delegates to bats test engineer

User: "Update the project README"
  -> Main Claude delegates to technical writer

User: "Review this Go diff for correctness risks"
  -> Main Claude delegates to code reviewer
```

### Agent catalog

| Area                     | Agents                                                                                                                                              |
| ------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| Architecture             | `solutions architect`, `go software architect`, `api architect`, `data architect`                                                                   |
| Implementation           | `go software engineer`, `python software engineer`, `dotnet software engineer`, `react software engineer`, `shell script engineer`, `data engineer` |
| Testing                  | `go e2e test engineer`, `bats test engineer`                                                                                                        |
| Operations               | `devops engineer`                                                                                                                                   |
| Documentation and review | `technical writer`, `code reviewer`                                                                                                                 |
| Support                  | `rlm subcall agent`                                                                                                                                 |

See [ABOUT-THE-AGENTS.md](agents/ABOUT-THE-AGENTS.md) for workflow examples and role boundaries.

### Skill catalog

Skills are Claude Code workflow prompts installed into `~/.claude/skills/`.

| Skill            | Purpose                                                   |
| ---------------- | --------------------------------------------------------- |
| `arch-docs`      | Create and update architecture documentation              |
| `code-review`    | Orchestrate parallel code review across multiple concerns |
| `docker-first-ci`| Implement and harden Docker-first CI/CD pipelines         |
| `prime`          | Prime Claude's context before complex tasks               |
| `readme-writer`  | Create or update project READMEs from a standard template |
| `rlm`            | Run long-context tasks using a persistent Python REPL     |
| `shell-script`   | Generate shell scripts with automatic BATS test coverage  |

## How it works

This repo ships three things:

- Agent definition files under `agents/`
- Global delegation rules in `agents/global-agent-rules.md`
- Skill bundles under `skills/`

The installer links repo-managed agents into `~/.claude/agents/`, updates the managed rules block in `~/.claude/CLAUDE.md`, and installs skills into `~/.claude/skills/`.

The installation flow is intentionally small:

1. Install or refresh repo-managed agent symlinks.
2. Install or refresh the managed global agent rules block.
3. Install or refresh skill bundles.

User-created agents are preserved. The installer only removes agents whose basenames match files managed by this repository.

## Key Considerations

**This is a reference implementation, not a framework.** Adapt the agent prompts and delegation model to match your own workflow.

**Global rules are part of the install.** Running the installer updates the managed rules block in `~/.claude/CLAUDE.md` using the contents of `agents/global-agent-rules.md`. Review that file before installing if you maintain custom coordination rules.

**The installer preserves user work where possible.** Repo-managed agents are refreshed; unrelated user-created agents in `~/.claude/agents/` are left in place.

## Development Considerations

### Quick Start

1. Run the installer:

   ```bash
   make install
   ```

2. Restart Claude Code so it reloads the installed agents, rules, and skills.

3. Review [ABOUT-THE-AGENTS.md](agents/ABOUT-THE-AGENTS.md) before changing delegation behavior.

### Building & running

The installer is [install/scripts/install.sh](install/scripts/install.sh). It runs these scripts in sequence:

| Script                             | Purpose                                                                                     |
| ---------------------------------- | ------------------------------------------------------------------------------------------- |
| `01-install-agents.sh`             | Symlink repo-managed agents into `~/.claude/agents/` while preserving unrelated user agents |
| `02-install-global-agent-rules.sh` | Update the managed agent rules block in `~/.claude/CLAUDE.md`                               |
| `03-install-skills.sh`             | Install skill bundles into `~/.claude/skills/`                                              |

You can also run the scripts individually:

```bash
./install/scripts/01-install-agents.sh
./install/scripts/02-install-global-agent-rules.sh
./install/scripts/03-install-skills.sh
```

To force reinstall even when dates are current:

```bash
FORCE=1 ./install/scripts/install.sh
```

See [install/README.md](install/README.md) for install details and behavior.

### Testing

Run the BATS unit test suite (requires `bats` on `PATH`):

```bash
make test
```

Validate the shell scripts with ShellCheck:

```bash
shellcheck install/scripts/*.sh
```

If you use markdownlint in your environment, run it against edited docs after documentation changes.

### Versioning

This project follows [Semantic Versioning 2.0.0](https://semver.org/).

Version is determined from git tags:

```bash
git describe --tags --always
```

Current version: `v1.0.0`.
