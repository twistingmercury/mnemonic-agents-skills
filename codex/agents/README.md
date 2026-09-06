# Codex Agents

This directory contains native Codex custom-agent definitions. The roles parallel the Claude Code catalog, but their operating instructions are tailored to Codex delegation, sandboxing, tool availability, validation, and parent-agent handoff behavior.

Each TOML file defines:

- `name`: a stable `snake_case` identifier used for delegation
- `description`: concise routing guidance for the parent agent
- `sandbox_mode`: the definition's configured filesystem access, either `read-only` or `workspace-write`
- `developer_instructions`: Codex-specific operating constraints followed by focused role instructions

Model settings are intentionally omitted so each custom agent inherits the active Codex session model and reasoning configuration. Optional skills and MCP services degrade gracefully when unavailable. Claude-specific metadata and tool allowlists are not used because Codex custom agents use Codex configuration, sandboxing, approvals, and inherited tool settings.

The source tree retains language and responsibility groupings for maintainability. The Codex installer flattens the TOML definitions into `$CODEX_HOME/agents/`, defaulting to `~/.codex/agents/`, where Codex discovers personal custom agents.

[`global-agents.md`](global-agents.md) defines the global coordination policy and concise routing registry for this catalog. The Codex installer copies it to `$CODEX_HOME/AGENTS.md` as a regular file. The TOML `name` and `description` fields remain authoritative for agent identity and native routing metadata; the global registry adds orchestration policy without duplicating full agent instructions.
