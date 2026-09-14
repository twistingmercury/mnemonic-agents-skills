# Claude Code and Codex Agent Ecosystem

> **Maturity Level**: Basic - Ready for use and actively evolving.
> **Version**: v1.5.0
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

| Skill                                                                               | Purpose                                                  |
| ----------------------------------------------------------------------------------- | -------------------------------------------------------- |
| [`arch-docs`](shared/skills/arch-docs/SKILL.md)                                     | Create and update architecture documentation             |
| [`capture-requirements`](shared/skills/capture-requirements/SKILL.md)               | Capture requirements for architecture and design handoff |
| [`check-push-readiness`](shared/skills/check-push-readiness/SKILL.md)               | Assess committed changes before pushing                  |
| [`code-review`](shared/skills/code-review/SKILL.md)                                 | Coordinate review across multiple concerns               |
| [`docker-first-ci`](shared/skills/docker-first-ci/SKILL.md)                         | Implement and harden Docker-first CI/CD pipelines        |
| [`dotnet-postgres-api-starter`](shared/skills/dotnet-postgres-api-starter/SKILL.md) | Scaffold a complete .NET API and PostgreSQL repository   |
| [`prime`](shared/skills/prime/SKILL.md)                                             | Survey a repository and build working context            |
| [`ralph-loop-docs-writer`](shared/skills/ralph-loop-docs-writer/SKILL.md)           | Create YAML tasks, checkpoints, logs, and JSON results   |
| [`readme-writer`](shared/skills/readme-writer/SKILL.md)                             | Create or update a README from a standard template       |
| [`rlm`](shared/skills/rlm/SKILL.md)                                                 | Run long-context tasks using a persistent local REPL     |
| [`shell-script`](shared/skills/shell-script/SKILL.md)                               | Create shell scripts with automatic BATS coverage        |

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

The [Ralph loop docs writer](shared/skills/ralph-loop-docs-writer/SKILL.md)
generates a typed `LOOP_TASKS.yaml` and a self-contained `LOOP_PROMPT.md`. This
edition requires a YAML-capable Gralph runtime — `gralph` with `--tasks`/`-t`,
`--prompt`/`-p`, and `--dry-run` — or another loop process that implements the
same contract: runtime-owned task status, agent-owned checkpoints, a reserved
Markdown activity log, and a separate JSON result. Validate a generated pair
with its actual paths before relying on it:

```bash
gralph -t LOOP_TASKS.yaml -p LOOP_PROMPT.md --dry-run
```

Validation is verified against gralph v0.5.22; older installations may lack YAML
input or dry-run support. An unavailable runner, an unsupported option, or a
nonzero exit is a blocker, not a pass. Installing the skill does not migrate
existing projects; the superseded Markdown-checklist resources are retained in
`_archive/ralph_loop_docs_writer/` outside the installed package.

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

Both platforms install copies of agent definitions and skills that remain usable
after moving or removing the checkout. Rerun the installer to refresh your
installation with updates from an updated checkout. Review potential name
conflicts and existing global guidance before installation.

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

With BATS, Python 3.11+, Bash 4+, and Make available, run the test suites from
the repository root:

```bash
make test
```

This runs the shared .NET PostgreSQL scaffold regression tests and shared RLM
unit tests. Separately, you may also run them directly:

```bash
bats shared/skills/dotnet-postgres-api-starter/tests/scaffold.bats
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
