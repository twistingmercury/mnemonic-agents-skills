# Claude Code and Codex Agent Ecosystem

> **Maturity Level**: Basic - Ready for use and actively evolving.
> **Version**: v1.3.1
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

| Skill                                                                               | Purpose                                                |
| ----------------------------------------------------------------------------------- | ------------------------------------------------------ |
| `arch-docs`                                                                         | Create and update architecture documentation           |
| `check-push-readiness`                                                              | Assess committed changes before pushing                |
| `code-review`                                                                       | Coordinate review across multiple concerns             |
| `docker-first-ci`                                                                   | Implement and harden Docker-first CI/CD pipelines      |
| [`dotnet-postgres-api-starter`](shared/skills/dotnet-postgres-api-starter/SKILL.md) | Scaffold a complete .NET API and PostgreSQL repository |
| `prime`                                                                             | Survey a repository and build working context          |
| `ralph-loop-docs-writer`                                                            | Create PRD and prompt files for iterative automation   |
| `readme-writer`                                                                     | Create or update a README from a standard template     |
| `rlm`                                                                               | Run long-context tasks using a persistent local REPL   |
| `shell-script`                                                                      | Create shell scripts with automatic BATS coverage      |

The [code-review skill](shared/skills/code-review/SKILL.md) writes reports by
default to `./local/code_review_YYYY_mm_dd_vN.md` in the reviewed repository.
Versions increment across all reviews on the same date; each review and
re-review creates a new file without overwriting earlier reports.

Findings use stable IDs and describe the trigger, impact, code location,
evidence, recommended change, and observable acceptance checks. Reports use
`ACCEPTABLE`, `CHANGES_REQUIRED`, or `INCOMPLETE` verdicts, with assessment
completeness recorded separately as `COMPLETE` or `INCOMPLETE`. An open finding
or failed required check requires changes; missing required evidence or
independent reviewers prevents acceptance. The skill defines the full report
format, disposition requirements, and verdict rules. Reviews account for explicit
user concerns and relevant test groups, disclosing sampling and omissions.
Re-reviews reconcile every prior finding with evidence; a finding that was not
rediscovered remains open until its disposition is justified.

The .NET PostgreSQL starter generates a complete repository targeting .NET 10,
including Docker builds, tests, CI, and deployment assets. It has no
application-only alternative. Invoke it in the intended project directory with
no application files; the skill defines which existing Git and agent metadata
it preserves. In the generated repository, run `make build-db` before
`make build`: black-box tests reuse and preserve that database image.

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
test suites from the repository root. `make test` runs only the platform suites;
run shared skill tests separately. Clear destination overrides so platform tests
use their temporary fixtures:

```bash
env -u AGENTS_DIR -u SKILLS_DIR make test
```

Run the shared .NET PostgreSQL scaffold regression tests:

```bash
bats shared/skills/dotnet-postgres-api-starter/tests/scaffold.bats
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
