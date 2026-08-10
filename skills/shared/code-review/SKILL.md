---
name: code-review
description: Orchestrate a multi-perspective code review combining general correctness, architectural analysis, and language-specific conventions. Use for reviewing files, diffs, pull requests, or uncommitted changes and producing a versioned review document.
---

# Code Review Skill

Orchestrate a comprehensive code review using independent specialist perspectives, then synthesize their findings.

## Inputs

Accept these scope patterns from the skill invocation:

- A file path, directory path, or glob pattern to review
- A PR number (e.g., `#42` or `42`)
- `--diff` to review staged/unstaged git changes
- No arguments defaults to reviewing uncommitted changes (`git diff`)

If the user didn't supply arguments, ask what they want reviewed.

## Step-by-step procedure

### Step 1: Determine review scope

Identify what code to review:

- **PR**: Run `git diff <base>...<head>` to get changed files
- **Files/directories**: Use the provided paths
- **Staged changes**: Run `git diff --cached`
- **Uncommitted changes**: Run `git diff`

Collect the list of changed/target files and their contents.

### Step 2: Select review perspectives

Always include:

1. **General code reviewer**
   - Correctness, security, testing, maintainability, documented project patterns, and appropriate static analysis
2. **Solutions architect**
   - Architectural consistency, separation of concerns, boundaries, and design coherence

Inspect the review scope to identify its implementation languages. Add the installed language specialist matching each materially changed language. For example, use a Go software architect for Go changes, a Python software engineer for Python changes, or a React software engineer for React changes. Do not invoke a language specialist for a language absent from the review scope.

Resolve specialists by their declared capabilities and use the exact identifiers registered in the current runtime. Do not assume Claude-style, Codex-style, or filename-derived identifiers.

### Step 3: Run independent reviews

Use the host's available subagent mechanism to run the selected perspectives concurrently. Give each reviewer the same scope and ask for structured findings with evidence. If subagents or a matching specialist are unavailable, perform that perspective directly and note the fallback in the review metadata.

### Step 4: Synthesize findings

When all selected reviewers return:

1. **Identify agreements** — Issues flagged by multiple agents
2. **Identify unique findings** — Issues only one agent caught
3. **Identify disagreements** — Conflicting recommendations

### Step 5: Reconcile disagreements

If disagreements exist:

1. Present the conflicting views back to each disagreeing agent
2. Ask each to provide reasoning
3. Request they reach consensus
4. If no consensus, present both perspectives to the user

### Step 6: Compile unified findings

Resolve this skill's directory from the active `SKILL.md`, then read `templates/code-review-template.md`. Use that template's section order exactly.

Compile the report directly or delegate it to the installed technical-writing specialist. When delegating, provide:

1. The resolved template path
2. The most recent review from `docs/code_reviews/`, when one exists, as a style reference
3. The synthesized findings, metadata, and compliance checks

Require the writer to preserve the template structure.

Create a new file under `docs/code_reviews/` with a lowercase snake_case, versioned name derived from the scope, for example `docs/code_reviews/phase_09_routing_engine_v01.md`. Keep the template section order intact and synchronize the filename with its `Version`, `Date`, and `Notes` metadata.

Before editing an existing review, inspect Git history and upstream or remote-tracking refs. Never edit a published review; preserve it and create the next version. If publication status is uncertain, treat a committed review as published. Edit a version in place only while it is untracked or known to be unpushed.

If you must show a summary to the user, include only a short synopsis plus a linkable file reference to the completed review document.

### Step 7: Collaborate with user on resolution

- Discuss trade-offs for architectural decisions
- Get user approval before delegating fixes
- Do NOT auto-fix without user consent

### Step 8: Delegate approved fixes

After the user approves specific fixes, select installed specialists by declared capability and use their exact runtime identifiers. Typical roles include:

- Language implementation issues → matching language software engineer
- Shell issues → shell script engineer
- Infrastructure issues → DevOps engineer
- Documentation → technical writer

If the appropriate specialist is unavailable, report the missing capability instead of silently assigning the work to an unrelated agent.

## Key principles

- Always include general and architectural perspectives
- Select language perspectives dynamically from the files under review
- Agents reconcile disagreements BEFORE presenting to user
- User is involved in resolution decisions, not just notified
- Documentation updated to capture learnings from review
- Pattern compliance checked against repository documentation and available project knowledge

## Finding categories

- **Pattern Violation**: Deviates from a documented project pattern
- **Language Idiom**: Non-idiomatic language or framework usage
- **Architecture**: Structural or design concern
- **Security**: Potential security issue
- **Error Handling**: Missing or inadequate error handling
- **Testing**: Missing tests or edge cases
- **Performance**: Inefficient implementation
- **Style**: Naming, formatting, organization issues
