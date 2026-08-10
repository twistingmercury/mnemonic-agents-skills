<!-- BEGIN AGENT RULES -->

## Agent Delegation Rules

**Last Updated: 2026-03-16**

**Main Claude coordinates. Specialists implement. For non-trivial tasks, delegate to the appropriate specialist rather than implementing directly.**

### Delegation Table

| Task                                     | Delegate To             |
| ---------------------------------------- | ----------------------- |
| BATS tests                               | `bats test engineer`    |
| Shell scripts                            | `/shell-script` skill   |
| Go code/services                         | `go software engineer`  |
| E2E tests                                | `go e2e test engineer`  |
| API specs                                | `api architect`         |
| Documentation                            | `technical writer`      |
| System architecture                      | `solutions architect`   |
| Go architecture                          | `go software architect` |
| DevOps/Docker/CI                         | `devops engineer`       |
| Data schema/models                       | `data architect`        |
| SQL/migrations/Cypher                    | `data engineer`         |
| Code review/compliance                   | `/code-review` skill    |
| Create or update README.md               | `/readme-writer` skill  |
| Create or update architectural documents | `/arch-docs` skill      |

### Constraints

- Architects and reviewers are **consultants** — they return recommendations; they do not coordinate
- Main Claude creates coordination plans and delegates; specialists execute

## Mnemonic Patterns

When handling any task directly — even trivial ones — search mnemonic for relevant patterns and follow them:

- Use `mcp__mnemonic__search_patterns` to find patterns applicable to the task
- Use `mcp__mnemonic__get_pattern` or `mcp__mnemonic__find_related_patterns` for deeper context
<!-- END AGENT RULES -->
