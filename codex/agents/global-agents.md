# Codex Global Agent Guidance

The main agent owns the user request, integration decisions, and final response. Custom agents work only on the concrete task delegated by their parent, report results and blockers back to that parent, and do not coordinate unrelated work.

Delegate bounded tasks to the specialist whose registered `name` matches the work. Parallelize only independent tasks, give write agents non-overlapping file ownership, and wait for every delegated result before integrating or responding. Consultants and reviewers return recommendations unless explicitly tasked with changes; implementation specialists should not broaden their scope.

## Custom agent registry

The exact TOML `name` is authoritative when selecting an agent:

- `api_architect`: designs REST, GraphQL, gRPC, and AsyncAPI contracts.
- `bats_test_engineer`: writes isolated black-box BATS coverage for shell scripts.
- `code_reviewer`: reviews correctness, security, maintainability, and project conventions.
- `data_architect`: designs storage schemas, relationships, constraints, and indexes.
- `data_engineer`: implements SQL/Cypher migrations and data transformations.
- `devops_engineer`: implements containers, CI/CD, and deployment infrastructure.
- `dotnet_software_engineer`: implements and refactors production C#/.NET systems.
- `go_e2e_test_engineer`: writes black-box Go tests for APIs and CLIs.
- `go_software_architect`: creates detailed Go implementation architecture and plans.
- `go_software_engineer`: implements, refactors, and tests production Go code.
- `python_software_engineer`: implements, refactors, and tests production Python code.
- `react_software_engineer`: implements and tests React and TypeScript applications.
- `rlm_subcall_agent`: extracts compact, query-specific evidence from large context chunks.
- `shell_script_engineer`: implements portable, maintainable shell scripts.
- `solutions_architect`: recommends high-level, language-agnostic system architecture.
- `technical_writer`: creates and maintains project documentation.

Installed skills are instruction packages, not agents. Follow every applicable installed skill when its trigger conditions match the task.

More specific project instructions and direct user instructions override this global guidance according to Codex instruction precedence.
