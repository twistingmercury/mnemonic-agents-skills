# Claude Code and Codex Agent Ecosystem

> **Maturity Level**: Basic - Ready for use. The agent catalog is usable now and will continue to evolve as workflows improve.
> **Version**: v1.1.0
>
> - **Emerging**: Prototype, not production-ready, expect breaking changes
> - **Basic**: Production-ready but actively evolving, expect minor version changes
> - **Mature**: Stable, battle-tested, changes are rare

Specialized development agents and skills for AI-assisted software work in Claude Code and Codex. Platform-specific integrations are isolated while portable skills remain shared.

## Table of Contents

- [Usage](#usage)
- [How it works](#how-it-works)
- [Key Considerations](#key-considerations)
- [Development Considerations](#development-considerations)
- [Versioning](#versioning)

## Usage

### Using agents

Request a specific agent by name or describe the work and let the configured client select specialists. Agent definition files are configuration sources; do not invoke them as scripts.

The platform installers make the corresponding agent catalog available automatically. Claude Code uses Markdown definitions; Codex uses native TOML definitions.

The catalog below uses Claude Code display names, which contain spaces; installed Claude definition filenames use hyphens. Codex identifiers use underscores instead (for example, `go_software_engineer`), and the exact TOML `name` values in the [Codex registry](codex/agents/global-agents.md#custom-agent-registry) are authoritative.

```text
User: "Build a user management REST API in Go"

Claude Code:
  1. Consults solutions architect for high-level direction
  2. Hands implementation planning to go software architect
  3. Sends API contract work to api architect
  4. Delegates implementation to go software engineer
  5. Delegates test coverage to go e2e test engineer
```

For narrow tasks, Claude Code can delegate directly:

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

See [ABOUT-THE-AGENTS.md](claude/agents/ABOUT-THE-AGENTS.md) for Claude Code workflow examples and role boundaries. See [Codex Agents](codex/agents/README.md) for the native Codex definition format and conventions.

### Skill catalog

Portable skills live under `shared/skills/`. Each platform installer can also include an optional platform-specific `skills/` directory when one exists. Claude Code installs skills into `~/.claude/skills/`; Codex installs them into `$CODEX_HOME/skills/`, defaulting to `~/.codex/skills/`.

| Skill                    | Purpose                                                    |
| ------------------------ | ---------------------------------------------------------- |
| `arch-docs`              | Create and update architecture documentation               |
| `code-review`            | Orchestrate parallel code review across multiple concerns  |
| `docker-first-ci`        | Implement and harden Docker-first CI/CD pipelines          |
| `prime`                  | Survey a repository and build context before starting work |
| `ralph-loop-docs-writer` | Create PRD and prompt files for agent-agnostic Ralph loops |
| `readme-writer`          | Create or update project READMEs from a standard template  |
| `rlm`                    | Run long-context tasks using a persistent Python REPL      |
| `shell-script`           | Generate shell scripts with automatic BATS test coverage   |

## How it works

This repository contains three integration layers:

- Claude integration files under `claude/`, including agents, installers, and tests
- Codex integration files under `codex/`, including agents, installers, and tests
- Portable skills under `shared/skills/` and shared shell helpers under `lib/`

Installers are separated by platform:

| Platform    | Installed content                                                                                     |
| ----------- | ----------------------------------------------------------------------------------------------------- |
| Claude Code | Agent symlinks, a managed rules block in `~/.claude/CLAUDE.md`, and skills in `~/.claude/skills/`     |
| Codex       | Agent symlinks, global `AGENTS.md`, and skills under `$CODEX_HOME`, defaulting to `~/.codex/`         |

Both skill installers combine the shared skill directory with an optional platform-specific directory. Platform-specific definitions take precedence when both sources contain the same skill name.

## Key Considerations

**This is a reference implementation, not a framework.** Adapt the agent prompts and delegation model to match your own workflow.

**Global rules are part of both platform installs.** The Claude installer updates a managed block in `~/.claude/CLAUDE.md`. The Codex installer links `$CODEX_HOME/AGENTS.md` to `codex/agents/global-agents.md`, which defines global coordination behavior and the custom-agent routing registry. A nonempty `$CODEX_HOME/AGENTS.override.md` suppresses `$CODEX_HOME/AGENTS.md`; restarting Codex does not activate the installed rules until the override is removed or emptied. Review the relevant source before installing if you maintain custom global instructions.

**Review name conflicts before installing.** Agent and skill entries are classified by repository basename, so same-named paths can be removed and replaced even when they are not symlinks. The Claude agent installer also removes broken `.md` symlinks. For Codex global rules, a non-symlink `$CODEX_HOME/AGENTS.md` is preserved; an unrelated symlink is preserved by default but replaced when `FORCE=1`. See [installation details](INSTALL.md) for complete preservation and replacement behavior.

**Agents, skills, and Codex global rules use symlinks.** Claude global rules are copied into a managed block instead. Keep the repository checkout available after installation; moving it makes symlinked content stale, so rerun the appropriate installer from the new location to repair it.

## Development Considerations

### Quick Start

1. Run the installer for the desired platform:

   ```bash
   make install-claude
   make install-codex
   ```

   Use `make install-all` to install both integrations. `make install` remains an alias for `make install-claude`.

2. Restart the target client so it reloads installed agents, rules, and skills.

3. Review [ABOUT-THE-AGENTS.md](claude/agents/ABOUT-THE-AGENTS.md) before changing Claude Code delegation behavior, or [global-agents.md](codex/agents/global-agents.md) before changing Codex coordination and routing.

### Building & running

The Claude installer at [install.sh](claude/install/install.sh) runs these scripts in sequence:

| Script | Purpose |
| --- | --- |
| `01_install_agents.sh` | Symlink repo-managed agents into `~/.claude/agents/` |
| `02_install_global_agents.sh` | Update the managed agent rules block in `~/.claude/CLAUDE.md` |
| `03_install_skills.sh` | Install skill bundles into `~/.claude/skills/` |

You can also run the scripts individually:

```bash
./claude/install/01_install_agents.sh
./claude/install/02_install_global_agents.sh
./claude/install/03_install_skills.sh
```

To force reinstall even when dates are current:

```bash
FORCE=1 ./claude/install/install.sh
```

The Codex installer runs these phases in order:

| Script | Purpose |
| --- | --- |
| `01_install_agents.sh` | Flatten and link native TOML agents into `$CODEX_HOME/agents/` |
| `02_install_global_agents.sh` | Link `codex/agents/global-agents.md` as `$CODEX_HOME/AGENTS.md` |
| `03_install_skills.sh` | Install shared and Codex-specific skills into `$CODEX_HOME/skills/` |

`CODEX_HOME` defaults to `~/.codex`. The installer supports the same `FORCE=1` override:

```bash
./codex/install/install.sh
FORCE=1 ./codex/install/install.sh
```

The phases can also be run individually:

```bash
./codex/install/01_install_agents.sh
./codex/install/02_install_global_agents.sh
./codex/install/03_install_skills.sh
```

See [INSTALL.md](INSTALL.md) for install details and behavior.

### Testing

Run both BATS suites (requires `bats` and Python 3.11+ on `PATH`):

```bash
make test
```

Run one platform suite with `make test-claude` or `make test-codex`.

Run the RLM unit tests directly:

```bash
(cd shared/skills/rlm && python3 -m unittest discover -s tests -v)
```

Validate the shell scripts with ShellCheck:

```bash
shellcheck claude/install/*.sh codex/install/*.sh
```

If you use markdownlint in your environment, run it against edited docs after documentation changes.

### Versioning

This project follows [Semantic Versioning 2.0.0](https://semver.org/).

Version is determined from git tags:

```bash
git describe --tags --always
```

Current version: `v1.1.0`.
