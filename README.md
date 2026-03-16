# Claude Code Agent Ecosystem

> **Maturity Level**: Basic - Ready for use. The agent catalog is usable now and will continue to evolve as workflows improve.
>
> - **Emerging**: Prototype, not production-ready, expect breaking changes
> - **Basic**: Production-ready but actively evolving, expect minor version changes
> - **Mature**: Stable, battle-tested, changes are rare

Specialized development agents for AI-assisted software work in Claude Code. This repository only manages agent definitions and the global delegation rules that support them. It does not install skills, commands, or external memory infrastructure.

## Usage

### Invoking agents

Main Claude acts as the coordinator. You do not call these agent files directly. Instead, describe the work you need, and Main Claude delegates to the right specialist.

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

The repository currently includes agents for:

| Area                     | Agents                                                                                                                                              |
| ------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| Architecture             | `solutions architect`, `go software architect`, `api architect`, `data architect`                                                                   |
| Implementation           | `go software engineer`, `python software engineer`, `dotnet software engineer`, `react software engineer`, `shell script engineer`, `data engineer` |
| Testing                  | `go e2e test engineer`, `bats test engineer`                                                                                                        |
| Operations               | `devops engineer`                                                                                                                                   |
| Documentation and review | `technical writer`, `code reviewer`                                                                                                                 |
| Support                  | `rlm subcall agent`                                                                                                                                 |

See [ABOUT-THE-AGENTS.md](agents/ABOUT-THE-AGENTS.md) for workflow examples and role boundaries.

## How it works

This repo ships two things:

- Agent definition files under `agents/`
- Global delegation rules in `agents/global-agent-rules.md`

The installer links repo-managed agents into `~/.claude/agents/` and updates the managed rules block in `~/.claude/CLAUDE.md`.

The installation flow is intentionally small:

1. Install or refresh repo-managed agent symlinks.
2. Install or refresh the managed global agent rules block.

User-created agents are preserved. The installer only removes agents whose basenames match files managed by this repository.

## Key Considerations

**This is a reference implementation, not a framework.** Adapt the agent prompts and delegation model to match your own workflow.

**Global rules are part of the install.** Running the installer updates the managed rules block in `~/.claude/CLAUDE.md` using the contents of `agents/global-agent-rules.md`. Review that file before installing if you maintain custom coordination rules.

**The installer preserves user work where possible.** Repo-managed agents are refreshed; unrelated user-created agents in `~/.claude/agents/` are left in place.

**The repo is agents-only.** Skills, command bundles, pattern libraries, and local memory services are out of scope for this project.

## Development Considerations

### Quick Start

1. Run the installer:

   ```bash
   make install
   ```

2. Restart Claude Code so it reloads the installed agents and global rules.

3. Review [ABOUT-THE-AGENTS.md](agents/ABOUT-THE-AGENTS.md) before changing delegation behavior.

### Building & running

The installer is [setup/scripts/installer.sh](setup/scripts/installer.sh). It runs these scripts in sequence:

| Script                             | Purpose                                                                                     |
| ---------------------------------- | ------------------------------------------------------------------------------------------- |
| `01-install-agents.sh`             | Symlink repo-managed agents into `~/.claude/agents/` while preserving unrelated user agents |
| `02-install-global-agent-rules.sh` | Update the managed agent rules block in `~/.claude/CLAUDE.md`                               |

Logs are written to `setup/scripts/logs/{TIMESTAMP}/`.

You can also run the scripts individually:

```bash
cd setup
./scripts/01-install-agents.sh
./scripts/02-install-global-agent-rules.sh
```

See [setup/README.md](setup/README.md) for install details and behavior.

### Testing

Validate the shell scripts with ShellCheck:

```bash
shellcheck setup/scripts/*.sh
```

If you use markdownlint in your environment, run it against the edited docs after documentation changes.

### Versioning

This project does not currently publish semantic version tags. Track changes through the Git history of the repository where you manage this code.
