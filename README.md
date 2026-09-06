# Claude Code and Codex Agent Ecosystem

> **Maturity Level**: Basic - Ready for use and actively evolving.
> **Version**: v1.2.1
>
> - **Emerging**: Prototype, not production-ready, expect breaking changes
> - **Basic**: Production-ready but actively evolving, expect minor version changes
> - **Mature**: Stable, battle-tested, changes are rare

Specialized development agents and reusable skills for AI-assisted software
work in Claude Code and Codex.

Choose a platform guide for installation and platform-specific behavior:

- [Claude Code integration](claude/README.md)
- [Codex integration](codex/README.md)

## Table of Contents

- [Usage](#usage)
- [How it works](#how-it-works)
- [Key Considerations](#key-considerations)
- [Development Considerations](#development-considerations)
- [Versioning](#versioning)

## Usage

Request a role by name, or describe the outcome and let the client route work
to the appropriate specialist. The shared catalog uses normalized snake_case
labels; each platform guide explains how those labels map to its agent names.

| Area                     | Roles                                                                                                                                               |
| ------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| Architecture             | `solutions_architect`, `go_software_architect`, `api_architect`, `data_architect`                                                                   |
| Implementation           | `go_software_engineer`, `python_software_engineer`, `dotnet_software_engineer`, `react_software_engineer`, `shell_script_engineer`, `data_engineer` |
| Testing                  | `go_e2e_test_engineer`, `bats_test_engineer`                                                                                                        |
| Operations               | `devops_engineer`                                                                                                                                   |
| Documentation and review | `technical_writer`, `code_reviewer`                                                                                                                 |
| Support                  | `rlm_subcall_agent`                                                                                                                                 |

Portable skills are shared across both integrations:

| Skill                    | Purpose                                               |
| ------------------------ | ----------------------------------------------------- |
| `arch-docs`              | Create and update architecture documentation          |
| `check-push-readiness`   | Assess committed changes before pushing               |
| `code-review`            | Coordinate review across multiple concerns            |
| `docker-first-ci`        | Implement and harden Docker-first CI/CD pipelines     |
| `prime`                  | Survey a repository and build working context         |
| `ralph-loop-docs-writer` | Create PRD and prompt files for iterative automation  |
| `readme-writer`          | Create or update a README from a standard template    |
| `rlm`                    | Run long-context tasks using a persistent local REPL  |
| `shell-script`           | Create shell scripts with automatic BATS coverage     |

## How it works

Each integration follows the same three-phase model:

1. Install agent definitions.
2. Install global coordination guidance.
3. Install shared skills.

The main client coordinates the request and delegates bounded work to the
specialist that owns it. Consultants recommend; implementation specialists
produce artifacts; the main client integrates the result.

## Key Considerations

This is a reference implementation, not a framework. Adapt prompts and routing
rules to the needs of each project.

Claude Code installs agent and skill symlinks that remain connected to this
checkout, so keep it in a stable location or rerun installation after moving it.
Codex installs local copies of this catalog that remain usable after moving or
removing the checkout; rerun its installer to refresh managed content from an
updated checkout. Review potential name conflicts and existing global guidance
before installation.

Naming, configuration precedence, preservation rules, and destinations differ
by platform. Read the [Claude Code guide](claude/README.md) or
[Codex guide](codex/README.md) before installing.

## Development Considerations

### Quick Start

Install both integrations from the repository root after checking the
prerequisites in the platform guides:

```bash
make install-all
```

For a single client, use `make install-claude` or `make install-codex`.
`make install` is an alias for the Claude target. Restart each client after
installation.

### Building & running

This repository has no compiled build artifact. List the supported install and
test targets with:

```bash
make help
```

### Testing

With BATS, Python 3.11+, Bash 4+, rsync, and Make available, run both platform
test suites from the repository root. Clear destination overrides so tests
use their temporary fixtures:

```bash
env -u AGENTS_DIR -u SKILLS_DIR make test
```

Run the shared RLM unit tests:

```bash
(cd shared/skills/rlm && python3 -m unittest discover -s tests -v)
```

### Versioning

This project follows [Semantic Versioning 2.0.0](https://semver.org/).

See [CHANGELOG.md](CHANGELOG.md) for release notes. Inspect the checked-out
revision relative to Git tags with:

```bash
git describe --tags --always
```

Between tags, the command includes the commit count and abbreviated commit hash.
