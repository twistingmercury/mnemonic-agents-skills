# Claude Code and Codex Agent Ecosystem

> **Maturity Level**: Basic - Ready for use and actively evolving.
> **Version**: v1.1.0
>
> - **Emerging**: Prototype, not production-ready, expect breaking changes
> - **Basic**: Production-ready but actively evolving, expect minor version changes
> - **Mature**: Stable, battle-tested, changes are rare

Specialized development agents and reusable skills for AI-assisted software
work in Claude Code and Codex.

Choose a platform guide for setup and platform behavior:

- [Claude Code integration](claude/README.md)
- [Codex integration](codex/README.md)
- [Comprehensive installation behavior](INSTALL.md)

## Table of Contents

- [Usage](#usage)
- [How it works](#how-it-works)
- [Key Considerations](#key-considerations)
- [Development Considerations](#development-considerations)
- [Versioning](#versioning)
- [Versioning](#versioning)

## Usage

Request a role by name, or describe the outcome and let the client route work
to the appropriate specialist. The shared role catalog uses normalized
snake_case labels below; each platform guide lists its exact names:

| Area                     | Roles                                                                                                                                               |
| ------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| Architecture             | `solutions_architect`, `go_software_architect`, `api_architect`, `data_architect`                                                                   |
| Implementation           | `go_software_engineer`, `python_software_engineer`, `dotnet_software_engineer`, `react_software_engineer`, `shell_script_engineer`, `data_engineer` |
| Testing                  | `go_e2e_test_engineer`, `bats_test_engineer`                                                                                                        |
| Operations               | `devops_engineer`                                                                                                                                   |
| Documentation and review | `technical_writer`, `code_reviewer`                                                                                                                 |
| Support                  | `rlm_subcall_agent`                                                                                                                                 |

Portable skills live under `shared/skills/`:

| Skill                    | Purpose                                                    |
| ------------------------ | ---------------------------------------------------------- |
| `arch-docs`              | Create and update architecture documentation               |
| `code-review`            | Coordinate review across multiple concerns                 |
| `docker-first-ci`        | Implement and harden Docker-first CI/CD pipelines          |
| `prime`                  | Survey a repository and build working context              |
| `ralph-loop-docs-writer` | Create PRD and prompt files for iterative automation       |
| `readme-writer`          | Create or update a README from a standard template         |
| `rlm`                    | Run long-context tasks using a persistent local REPL       |
| `shell-script`           | Create shell scripts with automatic BATS coverage          |

## How it works

The repository separates portable capabilities from client integration:

- `shared/skills/` contains skills used by both platforms.
- `lib/` contains shared installer helpers.
- `claude/` and `codex/` adapt the common roles and skills to each client.
- Each installer follows the same three phases: install agent definitions,
  install global coordination guidance, and install skills.

The main client coordinates the request and delegates bounded work to the
specialist that owns it. Consultants recommend; implementation specialists
produce artifacts; the main client integrates the result.

## Key Considerations

This is a reference implementation, not a framework. Adapt prompts and routing
rules to the needs of each project.

Agent and skill installations remain connected to this checkout. Keep it in a
stable location, or rerun installation after moving it. Review potential name
conflicts and existing global guidance before installation.

Platform naming, configuration precedence, preservation rules, and destination
paths differ. Read the [Claude Code guide](claude/README.md) or
[Codex guide](codex/README.md) before installing. See [INSTALL.md](INSTALL.md)
for the complete installation contract.

## Development Considerations

### Quick Start

Install both integrations from the repository root:

```bash
make install-all
```

Restart each client after installation. For a single client, follow its
platform guide.

### Building & running

This repository has no compiled build artifact. Use `make help` to list the
supported install and test targets:

```bash
make help
```

### Testing

Run both platform BATS suites:

```bash
make test
```

Run the shared RLM unit tests:

```bash
(cd shared/skills/rlm && python3 -m unittest discover -s tests -v)
```

### Versioning

This project follows [Semantic Versioning 2.0.0](https://semver.org/).

Version is determined from Git tags:

```bash
git describe --tags --always
```

Current version: `v1.1.0`.
